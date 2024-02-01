import ComposableArchitecture
@testable import ContentFeature
import CustomDump
import DataStore
import HistoryFeature
import XCTest

class ContentReducerTests: XCTestCase {
    @MainActor
    func testExpIsFocusedOnStart() async {
        let store = TestStore(initialState: ContentReducer.State()) {
            ContentReducer()
        } withDependencies: {
            $0.userDefaults = .ephemeral()
        }

        await store.send(.onAppear) {
            $0.focusedField = .exp
            $0.idealWidth = 450
            $0.selectedBitWidth = ._32
            $0.decEntry.text = "0"
            $0.hexEntry.text = "0"
            $0.binEntry.text = "0000 0000 0000 0000 0000 0000 0000 0000"
        }

        await store.receive(.focusedFieldChanged(.exp)) {
            $0.expEntry.isFocused = true
        }

        await store.finish()
    }

    @MainActor
    func testDecEntryUpdatesOtherEntries() async {
        var initialState = ContentReducer.State()
        initialState.focusedField = .dec
        initialState.decEntry.isFocused = true

        let store = TestStore(initialState: initialState) {
            ContentReducer()
        } withDependencies: {
            $0.userDefaults = .ephemeral()
        }

        await store.send(.decEntry(.binding(.set(\.text, "55")))) {
            $0.decEntry.text = "55"
            $0.hexEntry.text = "37"
            $0.binEntry.text = "0011 0111"
        }

        await store.finish()
    }

    @MainActor
    func testHexEntryUpdatesOtherEntries() async {
        var initialState = ContentReducer.State()
        initialState.focusedField = .hex
        initialState.hexEntry.isFocused = true
        initialState.selectedBitWidth = ._16

        let store = TestStore(initialState: initialState) {
            ContentReducer()
        } withDependencies: {
            $0.userDefaults = .ephemeral()
        }

        await store.send(.hexEntry(.binding(.set(\.text, "ff")))) {
            $0.decEntry.text = "255"
            $0.hexEntry.text = "FF"
            $0.binEntry.text = "0000 0000 1111 1111"
        }

        await store.finish()
    }

    @MainActor
    func testExpEntryUpdatesOtherEntries() async {
        var initialState = ContentReducer.State()
        initialState.focusedField = .exp
        initialState.expEntry.isFocused = true
        initialState.selectedBitWidth = ._16

        let store = TestStore(initialState: initialState) {
            ContentReducer()
        } withDependencies: {
            var addedItemText: String? = nil
            $0.historyStore.addItem = { addedItemText = $0 }
            $0.historyStore.item = { id in HistoryItem(id: id, addedOn: .now, text: addedItemText!) }
            $0.mainQueue = .immediate
            $0.userDefaults = .ephemeral()
        }

        await store.send(.expEntry(.binding(.set(\.text, "0xff + 1")))) {
            $0.expEntry.text = "0xff + 1"
        }

        await store.receive(.expEntryUpdated("0xff + 1", updateHistory: true)) {
            $0.decEntry.text = "256"
            $0.hexEntry.text = "100"
            $0.binEntry.text = "0000 0001 0000 0000"
        }

        await store.receive(.expressionUpdated)

        await store.finish()
    }

    @MainActor
    func testBinEntryUpdatesOtherEntries() async {
        var initialState = ContentReducer.State()
        initialState.focusedField = .bin
        initialState.binEntry.isFocused = true
        initialState.selectedBitWidth = ._16

        let store = TestStore(initialState: initialState) {
            ContentReducer()
        } withDependencies: {
            $0.userDefaults = .ephemeral()
        }

        await store.send(.binEntry(.binding(.set(\.text, "111100000000")))) {
            $0.decEntry.text = "3840"
            $0.hexEntry.text = "F00"
            $0.binEntry.text = "0000 1111 0000 0000"
        }

        await store.finish()
    }

    @MainActor
    func testHistoryLaunchAndCancel() async {
        var initialState = ContentReducer.State()
        initialState.focusedField = .exp
        initialState.expEntry.isFocused = true
        initialState.expEntry.text = "0xff"
        initialState.selectedBitWidth = ._16

        let fakeItemInHistory = HistoryItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
            addedOn: Date(timeIntervalSinceReferenceDate: 1_234_567_890),
            text: "123"
        )

        let store = TestStore(initialState: initialState) {
            ContentReducer()
        } withDependencies: {
            $0.date.now = Date(timeIntervalSinceReferenceDate: 1_234_567_890)
            $0.historyStore.items = { [fakeItemInHistory] }
            $0.mainQueue = .immediate
            $0.userDefaults = .ephemeral()
            $0.uuid = .incrementing
        }

        await store.send(.upArrowPressed) {
            $0.expTextTemp = "0xff"
        }

        await store.receive(\.historyLoaded) {
            $0.destination = .history(HistoryReducer.State(history: [fakeItemInHistory]))
        }

        // When the history picker is dismissed without a selection being confirmed
        // the entry state reverts to what is was before the picker was presented ...
        await store.send(.destination(.dismiss)) {
            $0.expEntry.text = "0xff"
            $0.expTextTemp = nil
            $0.destination = nil
        }

        // ... and the other entries update accordingly
        await store.receive(.expEntryUpdated("0xff", updateHistory: false)) {
            $0.decEntry.text = "255"
            $0.hexEntry.text = "FF"
            $0.binEntry.text = "0000 0000 1111 1111"
        }

        await store.finish()
    }

    @MainActor
    func testHistoryLaunchAndConfirm() async {
        var initialState = ContentReducer.State()
        initialState.focusedField = .exp
        initialState.expEntry.isFocused = true
        initialState.expEntry.text = "0xff"
        initialState.selectedBitWidth = ._16

        let fakeItemInHistory = HistoryItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
            addedOn: Date(timeIntervalSinceReferenceDate: 1_234_567_890),
            text: "123"
        )

        let store = TestStore(initialState: initialState) {
            ContentReducer()
        } withDependencies: {
            $0.date.now = Date(timeIntervalSinceReferenceDate: 1_234_567_890)
            $0.historyStore.items = { [fakeItemInHistory] }
            $0.historyStore.item = { _ in fakeItemInHistory }
            $0.mainQueue = .immediate
            $0.userDefaults = .ephemeral()
            $0.uuid = .incrementing
        }

        await store.send(.upArrowPressed) {
            $0.expTextTemp = "0xff"
        }

        await store.receive(\.historyLoaded) {
            $0.destination = .history(HistoryReducer.State(history: [fakeItemInHistory]))
        }

        await store.send(.destination(.presented(.history(.delegate(.selectionConfirmed(fakeItemInHistory.id))))))

        await store.receive(.historyItemConfirmed(fakeItemInHistory)) {
            $0.expEntry.text = "123"
            $0.expTextTemp = nil
        }

        await store.receive(.expEntryUpdated("123", updateHistory: false)) {
            $0.decEntry.text = "123"
            $0.hexEntry.text = "7B"
            $0.binEntry.text = "0000 0000 0111 1011"
        }

        await store.finish()
    }

    @MainActor
    func testIdealWidth() async {
        let store = TestStore(initialState: ContentReducer.State()) {
            ContentReducer()
        } withDependencies: {
            $0.userDefaults = .ephemeral()
        }

        await store.send(.binding(.set(\.selectedBitWidth, ._8))) {
            $0.selectedBitWidth = ._8
            $0.idealWidth = 450.0
            $0.decEntry.text = "0"
            $0.hexEntry.text = "0"
            $0.binEntry.text = "0000 0000"
        }

        await store.send(.binding(.set(\.selectedBitWidth, ._16))) {
            $0.selectedBitWidth = ._16
            $0.idealWidth = 450.0
            $0.decEntry.text = "0"
            $0.hexEntry.text = "0"
            $0.binEntry.text = "0000 0000 0000 0000"
        }

        await store.send(.binding(.set(\.selectedBitWidth, ._32))) {
            $0.selectedBitWidth = ._32
            $0.idealWidth = 450.0
            $0.decEntry.text = "0"
            $0.hexEntry.text = "0"
            $0.binEntry.text = "0000 0000 0000 0000 0000 0000 0000 0000"
        }

        await store.send(.binding(.set(\.selectedBitWidth, ._64))) {
            $0.selectedBitWidth = ._64
            $0.idealWidth = 730.0
            $0.decEntry.text = "0"
            $0.hexEntry.text = "0"
            $0.binEntry.text = "0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000"
        }
    }

    @MainActor
    func testTextStrippedBeforeAddingToHistory() async {
        @Dependency(\.historyStore) var historyStore

        var actual: String? = nil

        var initialState = ContentReducer.State()
        initialState.expEntry.text = " 0x55 "
        let store = TestStore(initialState: initialState) {
            ContentReducer()
        } withDependencies: {
            $0.date.now = Date(timeIntervalSinceReferenceDate: 1_234_567_890)
            $0.historyStore.addItem = { actual = $0 }
            $0.mainQueue = .immediate
            $0.userDefaults = .ephemeral()
            $0.uuid = .incrementing
        }

        store.exhaustivity = .off

        await store.send(.expressionUpdated)

        let expected = "0x55"

        XCTAssertNoDifference(expected, actual)
    }
}
