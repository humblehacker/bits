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

public enum FocusedField: Equatable {
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
        var selectedBitWidth: Bits
        var expTextTemp: String?
        var expEntry: EntryReducer.State
        var hexEntry: EntryReducer.State
        var decEntry: EntryReducer.State
        var binEntry: EntryReducer.State
        var focusedField: FocusedField?
        @Presents var destination: Destination.State?

        public init(
            idealWidth: Double = 500.0,
            selectedBitWidth: Bits = ._8,
            expEntry: EntryReducer.State = EntryReducer.State(kind: .exp),
            hexEntry: EntryReducer.State = EntryReducer.State(kind: .hex),
            decEntry: EntryReducer.State = EntryReducer.State(kind: .dec),
            binEntry: EntryReducer.State = EntryReducer.State(kind: .bin),
            focusedField: FocusedField? = nil
        ) {
            self.idealWidth = idealWidth
            self.selectedBitWidth = selectedBitWidth
            self.expEntry = expEntry
            self.hexEntry = hexEntry
            self.decEntry = decEntry
            self.binEntry = binEntry
            self.focusedField = focusedField
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case expEntryUpdated(String, updateHistory: Bool)
        case expEntry(EntryReducer.Action)
        case decEntry(EntryReducer.Action)
        case hexEntry(EntryReducer.Action)
        case binEntry(EntryReducer.Action)
        case focusedFieldChanged(FocusedField?)
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

        Scope(state: \.expEntry, action: \.expEntry) { EntryReducer() }
        Scope(state: \.hexEntry, action: \.hexEntry) { EntryReducer() }
        Scope(state: \.decEntry, action: \.decEntry) { EntryReducer() }
        Scope(state: \.binEntry, action: \.binEntry) { EntryReducer() }

        Reduce { state, action in
            switch action {
            case .onAppear:
                state.selectedBitWidth = loadBits()
                state.idealWidth = idealWindowWidth(bits: state.selectedBitWidth)
                state.focusedField = .exp
                state.expEntry.text = ""
                update(&state, from: 0)
                return .send(.focusedFieldChanged(state.focusedField))

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
                update(&state, from: value)
                if updateHistory {
                    return .send(.expressionUpdated)
                }
                return .none

            case let .expEntry(entryAction):
                switch entryAction {
                case .binding(\.text):
                    return .send(.expEntryUpdated(state.expEntry.text, updateHistory: true))

                case .binding(\.isFocused):
                    state.focusedField = .exp
                    return .send(.focusedFieldChanged(state.focusedField))

                case .delegate(.confirmationKeyPressed):
                    let value: Int
                    do {
                        value = try evaluateExpression(state.expEntry.text)
                    } catch {
                        print(error)
                        return .none
                    }
                    state.expEntry.text = String(value, radix: 10)
                    return .none

                default:
                    return .none
                }

            case let .decEntry(entryAction):
                switch entryAction {
                case .binding(\.text):
                    guard state.focusedField == .dec else { return .none }
                    let value = Int(state.decEntry.text, radix: 10) ?? 0
                    update(&state, from: value)
                    return .none

                case .binding(\.isFocused):
                    state.focusedField = .dec
                    return .send(.focusedFieldChanged(state.focusedField))

                default:
                    return .none
                }

            case let .hexEntry(entryAction):
                switch entryAction {
                case .binding(\.text):
                    guard state.focusedField == .hex else { return .none }
                    let value = Int(state.hexEntry.text, radix: 16) ?? 0
                    update(&state, from: value)
                    return .none

                case .binding(\.isFocused):
                    state.focusedField = .hex
                    return .send(.focusedFieldChanged(state.focusedField))

                default:
                    return .none
                }

            case let .binEntry(entryAction):
                switch entryAction {
                case .binding(\.text):
                    guard state.focusedField == .bin else { return .none }
                    let value = Int(state.binEntry.text.filter { !$0.isWhitespace }, radix: 2) ?? 0
                    update(&state, from: value)
                    return .none

                case .binding(\.isFocused):
                    state.focusedField = .bin
                    return .send(.focusedFieldChanged(state.focusedField))

                default:
                    return .none
                }

            case let .focusedFieldChanged(newField):
                state.expEntry.isFocused = newField == .exp
                state.binEntry.isFocused = newField == .bin
                state.decEntry.isFocused = newField == .dec
                state.hexEntry.isFocused = newField == .hex
                return .none

            case .binding(\.selectedBitWidth):
                let value = Int(state.decEntry.text, radix: 10) ?? 0
                update(&state, from: value)
                saveBits(state.selectedBitWidth)
                state.idealWidth = idealWindowWidth(bits: state.selectedBitWidth)
                return .none

            case .binding(\.focusedField):
                return .send(.focusedFieldChanged(state.focusedField))

            case .binding:
                return .none

            case .expressionUpdated:
                return .run { [text = state.expEntry.text] _ in
                    try await historyStore.addItem(text: text.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                .debounce(id: CancelID.history, for: 1.0, scheduler: self.mainQueue)

            case .upArrowPressed:
                state.expTextTemp = state.expEntry.text
                return .run { send in
                    let history = try await historyStore.items()
                    guard history.isNotEmpty else { return }
                    await send(.historyLoaded(history))
                }
                .debounce(id: CancelID.upArrow, for: 0.2, scheduler: self.mainQueue)

            case let .historyLoaded(history):
                guard state.destination == nil else { return .none }
                state.destination = .history(HistoryReducer.State(history: history))
                return .none

            case let .historyItemSelected(item):
                state.expEntry.text = item.text
                return .send(.expEntryUpdated(item.text, updateHistory: false))

            case let .historyItemConfirmed(item):
                state.expEntry.text = item.text
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
                    state.expEntry.text = expText
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
        .ifLet(\.$destination, action: \.destination) {
            Destination()
        }
        ._printChanges()
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

    func update(_ state: inout ContentReducer.State, from value: Int) {
        state.hexEntry.text = String(value, radix: 16).uppercased()
        state.decEntry.text = String(value, radix: 10)
        state.binEntry.text = value.paddedBinaryString(bits: state.selectedBitWidth.rawValue)
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
