import BigInt
import ComposableArchitecture
import DataStore
import Dependencies
import DependenciesAdditions
import ExpressionEvaluator
import Foundation
import HistoryFeature
import Observation
import Types
import Utils

private let defaultBits: Bits = ._32

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
        var entryWidth: Double
        var selectedBits: Bits
        var expTextTemp: String?
        var entries: IdentifiedArrayOf<EntryReducer.State>
        var variableEntryKeys: [EntryKind]
        @Shared var value: EntryValue
        var focusedField: EntryKind?
        @Presents var destination: Destination.State?

        var variableEntries: IdentifiedArrayOf<EntryReducer.State> {
            entries.filter { variableEntryKeys.contains($0.id) }
        }

        public init(
            entryWidth: Double = 100.0,
            selectedBits: Bits = ._8,
            variableEntryKeys: [EntryKind] = [.dec, .hex],
            value: EntryValue = .init(),
            focusedField: EntryKind? = nil
        ) {
            self.entryWidth = entryWidth
            self.selectedBits = selectedBits
            self.variableEntryKeys = variableEntryKeys
            self.focusedField = focusedField

            _value = Shared(.init())
            entries = [
                .init(.bin, value: _value, binText: .init()),
                .init(.exp, value: _value),
                .init(.dec, value: _value),
                .init(.hex, value: _value),
            ]
        }

        mutating func updateFocusedField(newField: EntryKind?) -> EffectOf<ContentReducer> {
            for entryID in entries.ids {
                let thisKind = entries[id: entryID]?.kind
                let isFocused = newField == thisKind
                entries[id: entryID]?.isFocused = isFocused
                // TODO: the following should be propagated from the former
                entries[id: entryID]?.binText?.isFocused = isFocused
            }
            return .none
        }

        mutating func updateExpressionText(_ text: String) -> EffectOf<ContentReducer> {
            entries[id: .exp]?.updateText(text).map(Action.entries) ?? .none
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case destination(PresentationAction<Destination.Action>)
        case entries(IdentifiedActionOf<EntryReducer>)
        case historyItemConfirmed(HistoryItem)
        case historyItemSelected(HistoryItem)
        case historyLoaded([HistoryItem])
        case onAppear
        case toggleSignage
        case upArrowPressed
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
        .ifLet(\.$destination, action: \.destination)
        .forEach(\.entries, action: \.entries) {
            EntryReducer()
        }
        ._printChanges()
    }

    func reduce(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .binding(\.selectedBits):
            let bits = state.selectedBits
            saveBits(bits)
            state.value.bits = bits
            return .none

        case .binding(\.focusedField):
            return state.updateFocusedField(newField: state.focusedField)

        case .binding:
            return .none

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

        case let .entries(.element(_, .delegate(.focusChanged(newFocusedField)))):
            state.focusedField = newFocusedField
            return state.updateFocusedField(newField: state.focusedField)

        case let .entries(.element(id, .valueUpdated)):
            guard id == .exp else { return .none }
            guard let text = state.entries[id: .exp]?.text else { return .none }
            return .run { _ in
                try await historyStore.addItem(text: text.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            .debounce(id: CancelID.history, for: 1.0, scheduler: mainQueue)

        case .entries:
            return .none

        case let .historyItemConfirmed(item):
            state.expTextTemp = nil
            return state.updateExpressionText(item.text)

        case let .historyItemSelected(item):
            return state.updateExpressionText(item.text)

        case let .historyLoaded(history):
            guard state.destination == nil else { return .none }
            state.destination = .history(HistoryReducer.State(history: history))
            return .none

        case .onAppear:
            state.selectedBits = loadBits()
            state.focusedField = .exp
            state.entries[id: .exp]?.text = ""
            return state.updateFocusedField(newField: state.focusedField)

        case .toggleSignage:
            state.value.signage = state.value.signage.toggled()
            // If the focused field has text, that text should be re-evaluated with the new signage
            guard let field = state.focusedField, let text = state.entries[id: field]?.text else { return .none }
            return .send(.entries(.element(id: field, action: .binding(.set(\.text, text)))))

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
        }
    }

    @Reducer(state: .equatable, action: .equatable)
    public enum Destination {
        case history(HistoryReducer)
    }

    func saveBits(_ bits: Bits) {
        userDefaults.set(bits.rawValue, forKey: "bits")
    }

    func loadBits() -> Bits {
        guard let bits = userDefaults.integer(forKey: "bits") else { return defaultBits }
        return Bits(rawValue: bits) ?? defaultBits
    }
}
