import ComposableArchitecture
import DataStore
import Dependencies
import DependenciesAdditions
import ExpressionEvaluator
import Foundation
import HistoryFeature
import Observation
import Utils

private let defaultBits: Bits = ._32
let minWidth = 440.0
let maxWidth = 900.0

public enum EntryKind: Equatable {
    case exp
    case bin
    case dec
    case hex
}

@Reducer
public struct ContentReducer {
    @ObservableState
    public struct State: Equatable {
        var idealWidth: Double
        var entryWidth: Double
        var selectedBitWidth: Bits
        var expTextTemp: String?
        var entries: IdentifiedArrayOf<EntryReducer.State>
        var value: Int
        var focusedField: EntryKind?
        @Presents var destination: Destination.State?

        public init(
            idealWidth: Double = 500.0,
            entryWidth: Double = 100.0,
            selectedBitWidth: Bits = ._8,
            entries: IdentifiedArrayOf<EntryReducer.State> = [
                .init(.exp), .init(.dec), .init(.hex), .init(.bin, binText: .init()),
            ],
            value: Int = 0,
            focusedField: EntryKind? = nil
        ) {
            self.idealWidth = idealWidth
            self.entryWidth = entryWidth
            self.selectedBitWidth = selectedBitWidth
            self.entries = entries
            self.value = value
            self.focusedField = focusedField
        }

        mutating func updateValues(newValue: Int) -> EffectOf<ContentReducer> {
            return .merge(
                entries.ids
                    .compactMap { id in entries[id: id]?.updateValue(newValue) }
                    .map { effect in effect.map(ContentReducer.Action.entries) }
            )
        }

        mutating func updateBitWidth(_ bitWidth: Bits) -> EffectOf<ContentReducer> {
            return .merge(
                entries.ids
                    .compactMap { id in entries[id: id]?.updateBitWidth(bitWidth) }
                    .map { effect in effect.map(ContentReducer.Action.entries) }
            )
        }

        mutating func updateValuesFromExpression() -> EffectOf<ContentReducer> {
            guard let value = entries[id: .exp]?.value else { return .none }
            print("Updating from value: \(value)")
            return updateValues(newValue: value)
        }

        mutating func updateFocusedField(newField: EntryKind?) -> EffectOf<ContentReducer> {
            for entryID in entries.ids {
                let thisKind = entries[id: entryID]?.kind
                entries[id: entryID]?.isFocused = newField == thisKind
            }
            return .none
        }

        mutating func updateExpressionText(_ text: String) -> EffectOf<ContentReducer> {
            .merge(
                entries[id: .exp]?.updateText(text).map(Action.entries) ?? .none,
                updateValuesFromExpression()
            )
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case entries(IdentifiedActionOf<EntryReducer>)
        case onAppear
        case upArrowPressed
        case historyItemSelected(HistoryItem)
        case historyItemConfirmed(HistoryItem)
        case historyLoaded([HistoryItem])
        case destination(PresentationAction<Destination.Action>)
    }

    @Dependency(\.expressionEvaluator.evaluate) var evaluateExpression
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.historyStore) var historyStore
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.userDefaults) var userDefaults

    enum CancelID { case history, upArrow }

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            reduce(state: &state, action: action)
        }
        .ifLet(\.$destination, action: \.destination) {
            Destination()
        }
        .forEach(\.entries, action: \.entries) {
            EntryReducer()
        }
        ._printChanges()
    }

    func reduce(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .onAppear:
            state.selectedBitWidth = loadBits()
            state.idealWidth = idealWindowWidth(bits: state.selectedBitWidth)
            state.focusedField = .exp
            state.entries[id: .exp]?.text = ""
            return .merge(
                state.updateValues(newValue: 0),
                state.updateBitWidth(state.selectedBitWidth),
                state.updateFocusedField(newField: state.focusedField)
            )

        case let .entries(.element(_, .delegate(.focusChanged(newFocusedField)))):
            state.focusedField = newFocusedField
            return state.updateFocusedField(newField: state.focusedField)

        case let .entries(.element(id, .delegate(.valueUpdated(value)))):
            state.value = value
            return .merge(
                state.updateValues(newValue: value),
                id == .exp ? addExpressionToHistory() : .none
            )

        case .entries:
            return .none

        case .binding(\.selectedBitWidth):
            let bitWidth = state.selectedBitWidth
            saveBits(bitWidth)
            state.idealWidth = idealWindowWidth(bits: bitWidth)
            return state.updateBitWidth(bitWidth)

        case .binding(\.focusedField):
            return state.updateFocusedField(newField: state.focusedField)

        case .binding:
            return .none

        case .upArrowPressed:
            guard
                let field = state.focusedField, field == .exp,
                let text = state.entries[id: field]?.text
            else { return .none }

            state.expTextTemp = text

            return .run { send in
                let history = try await historyStore.items()
                guard history.isNotEmpty else { return }
                await send(.historyLoaded(history))
            }
            .debounce(id: CancelID.upArrow, for: 0.2, scheduler: mainQueue)

        case let .historyLoaded(history):
            guard state.destination == nil else { return .none }
            state.destination = .history(HistoryReducer.State(history: history))
            return .none

        case let .historyItemSelected(item):
            return state.updateExpressionText(item.text)

        case let .historyItemConfirmed(item):
            state.expTextTemp = nil
            return state.updateExpressionText(item.text)

        case let .destination(.presented(.history(.delegate(.selectionChanged(id))))):
            return .run { send in
                guard let id, let item = try await historyStore.item(id: id) else { return }
                await send(.historyItemSelected(item))
            }

        case let .destination(.presented(.history(.delegate(.selectionConfirmed(id))))):
            return .run { send in
                guard let item = try await historyStore.item(id: id) else { return }
                await send(.historyItemConfirmed(item))
            }

        case .destination(.dismiss):
            guard let expText = state.expTextTemp else { return .none }
            state.expTextTemp = nil
            return state.updateExpressionText(expText)

        case let .destination(.presented(.history(.delegate(.itemDeleted(item))))):
            return .run { send in
                try await historyStore.removeItem(item)
                let history = try await historyStore.items()
                await send(.destination(.presented(.history(.historyUpdated(history)))))
                if history.isEmpty { await dismiss() }
            }

        case .destination:
            return .none
        }

        func addExpressionToHistory() -> EffectOf<ContentReducer> {
            guard let text = state.entries[id: .exp]?.text else { return .none }
            return .run { _ in
                try await historyStore.addItem(text: text.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            .debounce(id: CancelID.history, for: 1.0, scheduler: mainQueue)
        }
    }

    @Reducer
    public struct Destination {
        @ObservableState
        public enum State: Equatable {
            case history(HistoryReducer.State)
        }

        public enum Action: Equatable {
            case history(HistoryReducer.Action)
        }

        public var body: some ReducerOf<Self> {
            Scope(state: \.history, action: \.history) {
                HistoryReducer()
            }
        }
    }

    func saveBits(_ bits: Bits) {
        userDefaults.set(bits.rawValue, forKey: "bits")
    }

    func loadBits() -> Bits {
        guard let bits = userDefaults.integer(forKey: "bits") else { return defaultBits }
        return Bits(rawValue: bits) ?? defaultBits
    }
}

func idealWindowWidth(bits: Bits) -> Double {
    return switch bits {
    case ._8, ._16: minWidth
    case ._32: minWidth + 100
    case ._64: maxWidth
    }
}