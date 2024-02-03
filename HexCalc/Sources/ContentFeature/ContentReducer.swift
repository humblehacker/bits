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
private let minWidth = 450.0
private let maxWidth = 730.0

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
                .init(kind: .exp), .init(kind: .hex), .init(kind: .dec), .init(kind: .bin),
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

        mutating func updateValues(newValue: Int) -> Effect<ContentReducer.Action> {
            return .merge(
                entries.ids
                    .compactMap { id in entries[id: id]?.updateValue(newValue) }
                    .map { effect in effect.map(ContentReducer.Action.entries) }
            )
        }

        mutating func updateFocusedField(newField: EntryKind?) -> Effect<ContentReducer.Action> {
            for entryID in entries.ids {
                let thisKind = entries[id: entryID]?.kind
                entries[id: entryID]?.isFocused = newField == thisKind
            }
            return .none
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case expEntryUpdated(String, updateHistory: Bool)
        case entries(IdentifiedActionOf<EntryReducer>)
        case onAppear
        case expressionUpdated
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
                state.updateFocusedField(newField: state.focusedField)
            )

        case let .entries(.element(_, .delegate(.focusChanged(newFocusedField)))):
            state.focusedField = newFocusedField
            return state.updateFocusedField(newField: state.focusedField)

        case let .entries(.element(_, .delegate(.valueUpdated(value)))):
            state.value = value
            return state.updateValues(newValue: value)

        case .entries:
            return .none

        case let .expEntryUpdated(text, updateHistory):
            let value: Int
            do {
                if text.isNotEmpty {
                    value = try evaluateExpression(text)
                } else {
                    value = 0
                }
            } catch {
                print("Error: \(error)")
                return .none
            }
            print("Updating from value: \(value)")
            if updateHistory {
                return .send(.expressionUpdated)
            }
            return state.updateValues(newValue: value)

        case .binding(\.selectedBitWidth):
            saveBits(state.selectedBitWidth)
            state.idealWidth = idealWindowWidth(bits: state.selectedBitWidth)
            return state.updateValues(newValue: state.value)

        case .binding(\.focusedField):
            return state.updateFocusedField(newField: state.focusedField)

        case .binding:
            return .none

        case .expressionUpdated:
            guard let text = state.entries[id: .exp]?.text else { return .none }
            return .run { _ in
                try await historyStore.addItem(text: text.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            .debounce(id: CancelID.history, for: 1.0, scheduler: mainQueue)

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
            state.entries[id: .exp]?.text = item.text
            return .send(.expEntryUpdated(item.text, updateHistory: false))

        case let .historyItemConfirmed(item):
            state.entries[id: .exp]?.text = item.text
            state.expTextTemp = nil
            return .send(.expEntryUpdated(item.text, updateHistory: false))

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
            if let expText = state.expTextTemp {
                state.entries[id: .exp]?.text = expText
                state.expTextTemp = nil
                return .send(.expEntryUpdated(expText, updateHistory: false))
            }
            return .none

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
    case ._8, ._16, ._32: minWidth
    case ._64: maxWidth
    }
}
