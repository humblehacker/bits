import ComposableArchitecture
@testable import ContentFeature
import CustomDump
import DataStore
@testable import HistoryFeature
import Utils
import XCTest

class ContentReducerTests: XCTestCase {
    @MainActor
    func testExpEntryUpdatesOtherEntries() async {
        let store = TestStore(initialState: ContentReducer.State()) {
            ContentReducer()
        } withDependencies: {
            $0.userDefaults = .ephemeral()
            $0.entryConverter = .liveValue
            $0.mainQueue = .immediate
            $0.historyStore.addItem = { _ in }
        }

        await store.send(.entries(.element(id: .exp, action: .binding(.set(\.text, "54 + 1"))))) {
            $0.entries[id: .exp]?.apply {
                $0.text = "54 + 1"
                $0.value = EntryValue(55)
            }
        }

        await store.receive(\.entries[id: .exp].delegate.valueUpdated, EntryValue(55)) {
            $0.value = EntryValue(55)
        }

        await store.receive(\.entries[id: .bin].binding) {
            $0.entries[id: .bin]?.apply {
                $0.text = "110111"
                $0.value = EntryValue(55)
            }
        }

        await store.receive(\.entries[id: .dec].binding) {
            $0.entries[id: .dec]?.apply {
                $0.text = "55"
                $0.value = EntryValue(55)
            }
        }

        await store.receive(\.entries[id: .hex].binding) {
            $0.entries[id: .hex]?.apply {
                $0.text = "37"
                $0.value = EntryValue(55)
            }
        }

        await store.finish()
    }

    @MainActor
    func testDecEntryUpdatesOtherEntries() async {
        let store = TestStore(initialState: ContentReducer.State()) {
            ContentReducer()
        } withDependencies: {
            $0.userDefaults = .ephemeral()
            $0.entryConverter = .liveValue
        }

        await store.send(.entries(.element(id: .dec, action: .binding(.set(\.text, "55"))))) {
            $0.entries[id: .dec]?.apply {
                $0.text = "55"
                $0.value = EntryValue(55)
            }
        }

        await store.receive(\.entries[id: .dec].delegate.valueUpdated, EntryValue(55)) {
            $0.value = EntryValue(55)
        }

        await store.receive(\.entries[id: .bin].binding) {
            $0.entries[id: .bin]?.apply {
                $0.text = "110111"
                $0.value = EntryValue(55)
            }
        }

        await store.receive(\.entries[id: .exp].binding) {
            $0.entries[id: .exp]?.apply {
                $0.text = "55"
                $0.value = EntryValue(55)
            }
        }

        await store.receive(\.entries[id: .hex].binding) {
            $0.entries[id: .hex]?.apply {
                $0.text = "37"
                $0.value = EntryValue(55)
            }
        }

        await store.finish()
    }

    @MainActor
    func testHexEntryUpdatesOtherEntries() async {
        let store = TestStore(initialState: ContentReducer.State()) {
            ContentReducer()
        } withDependencies: {
            $0.userDefaults = .ephemeral()
            $0.entryConverter = .liveValue
        }

        await store.send(.entries(.element(id: .hex, action: .binding(.set(\.text, "37"))))) {
            $0.entries[id: .hex]?.apply {
                $0.text = "37"
                $0.value = EntryValue(55)
            }
        }

        await store.receive(\.entries[id: .hex].delegate.valueUpdated, EntryValue(55)) {
            $0.value = EntryValue(55)
        }

        await store.receive(\.entries[id: .bin].binding) {
            $0.entries[id: .bin]?.apply {
                $0.text = "110111"
                $0.value = EntryValue(55)
            }
        }

        await store.receive(\.entries[id: .exp].binding) {
            $0.entries[id: .exp]?.apply {
                $0.text = "55"
                $0.value = EntryValue(55)
            }
        }

        await store.receive(\.entries[id: .dec].binding) {
            $0.entries[id: .dec]?.apply {
                $0.text = "55"
                $0.value = EntryValue(55)
            }
        }

        await store.finish()
    }

    @MainActor
    func testBinEntryUpdatesOtherEntries() async {
        let store = TestStore(initialState: ContentReducer.State()) {
            ContentReducer()
        } withDependencies: {
            $0.userDefaults = .ephemeral()
            $0.entryConverter = .liveValue
        }

        await store.send(.entries(.element(id: .bin, action: .binding(.set(\.text, "110111"))))) {
            $0.entries[id: .bin]?.apply {
                $0.text = "110111"
                $0.value = EntryValue(55)
            }
        }

        await store.receive(\.entries[id: .bin].delegate.valueUpdated, EntryValue(55)) {
            $0.value = EntryValue(55)
        }

        await store.receive(\.entries[id: .exp].binding) {
            $0.entries[id: .exp]?.apply {
                $0.text = "55"
                $0.value = EntryValue(55)
            }
        }

        await store.receive(\.entries[id: .dec].binding) {
            $0.entries[id: .dec]?.apply {
                $0.text = "55"
                $0.value = EntryValue(55)
            }
        }

        await store.receive(\.entries[id: .hex].binding) {
            $0.entries[id: .hex]?.apply {
                $0.text = "37"
                $0.value = EntryValue(55)
            }
        }

        await store.finish()
    }

    @MainActor
    func testHistoryLaunchAndCancel() async {
        var initialState = ContentReducer.State()
        initialState.focusedField = .exp
        initialState.selectedBitWidth = ._16
        initialState.entries[id: .exp]?.apply {
            $0.isFocused = true
            $0.text = "0xff"
        }

        let fakeItemInHistory = HistoryItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
            addedOn: Date(timeIntervalSinceReferenceDate: 1_234_567_890),
            text: "123"
        )

        let store = TestStore(initialState: initialState) {
            ContentReducer()
        } withDependencies: {
            $0.date.now = Date(timeIntervalSinceReferenceDate: 1_234_567_890)
            $0.entryConverter = .liveValue
            $0.historyStore.items = { [fakeItemInHistory] }
            $0.historyStore.item = { _ in fakeItemInHistory }
            $0.historyStore.addItem = { _ in }
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

        // When HistoryPicker is presented the first (bottom, newest) history item is selected
        await store.send(.destination(.presented(.history(.binding(.set(\.selection, fakeItemInHistory.id)))))) {
            $0.destination?.modify(\ContentReducer.Destination.State.Cases.history) {
                $0.selection = fakeItemInHistory.id
            }
        }

        await store.receive(\.destination.presented.history.delegate.selectionChanged, fakeItemInHistory.id)

        await store.receive(\.historyItemSelected)

        // The exp entry gets updated with the text of the selected history item
        await store.receive(\.entries[id: .exp].binding) {
            $0.entries[id: .exp]?.apply {
                $0.text = "123"
                $0.value = EntryValue(123)
            }
        }

        // The exp entry fires the valueUpdated delegate action which sets the value ...
        await store.receive(\.entries[id: .exp].delegate.valueUpdated, EntryValue(123)) {
            $0.value = EntryValue(123)
        }

        // ... and causes the rest of the entries to update
        await store.receive(\.entries[id: .bin].binding) {
            $0.entries[id: .bin]?.apply {
                $0.text = "1111011"
                $0.value = EntryValue(123)
            }
        }

        await store.receive(\.entries[id: .dec].binding) {
            $0.entries[id: .dec]?.apply {
                $0.text = "123"
                $0.value = EntryValue(123)
            }
        }

        await store.receive(\.entries[id: .hex].binding) {
            $0.entries[id: .hex]?.apply {
                $0.text = "7B"
                $0.value = EntryValue(123)
            }
        }

        // When the history picker is dismissed without a selection being confirmed,
        // the entry state reverts to what is was before the picker was presented ...
        await store.send(.destination(.dismiss)) {
            $0.expTextTemp = nil
            $0.destination = nil
        }

        await store.receive(\.entries[id: .exp].binding) {
            $0.entries[id: .exp]?.apply {
                $0.text = "0xff"
                $0.value = EntryValue(255)
            }
        }

        // ... and the other entries update accordingly
        await store.receive(\.entries[id: .exp].delegate.valueUpdated, EntryValue(255)) {
            $0.value = EntryValue(255)
        }

        await store.receive(\.entries[id: .bin].binding) {
            $0.entries[id: .bin]?.apply {
                $0.text = "11111111"
                $0.value = EntryValue(255)
            }
        }

        await store.receive(\.entries[id: .dec].binding) {
            $0.entries[id: .dec]?.apply {
                $0.text = "255"
                $0.value = EntryValue(255)
            }
        }

        await store.receive(\.entries[id: .hex].binding) {
            $0.entries[id: .hex]?.apply {
                $0.text = "FF"
                $0.value = EntryValue(255)
            }
        }

        await store.finish()
    }

    @MainActor
    func testHistoryLaunchAndConfirm() async {
        var initialState = ContentReducer.State()
        initialState.focusedField = .exp
        initialState.selectedBitWidth = ._16
        initialState.entries[id: .exp]?.apply {
            $0.isFocused = true
            $0.text = "0xff"
        }

        let fakeItemInHistory = HistoryItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
            addedOn: Date(timeIntervalSinceReferenceDate: 1_234_567_890),
            text: "123"
        )

        let store = TestStore(initialState: initialState) {
            ContentReducer()
        } withDependencies: {
            $0.date.now = Date(timeIntervalSinceReferenceDate: 1_234_567_890)
            $0.entryConverter = .liveValue
            $0.historyStore.items = { [fakeItemInHistory] }
            $0.historyStore.item = { _ in fakeItemInHistory }
            $0.historyStore.addItem = { _ in }
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

        // When HistoryPicker is presented the first (bottom, newest) history item is selected
        await store.send(.destination(.presented(.history(.binding(.set(\.selection, fakeItemInHistory.id)))))) {
            $0.destination?.modify(\ContentReducer.Destination.State.Cases.history) {
                $0.selection = fakeItemInHistory.id
            }
        }

        await store.receive(\.destination.presented.history.delegate.selectionChanged, fakeItemInHistory.id)

        await store.receive(\.historyItemSelected)

        // The exp entry gets updated with the text of the selected history item
        await store.receive(\.entries[id: .exp].binding) {
            $0.entries[id: .exp]?.apply {
                $0.text = "123"
                $0.value = EntryValue(123)
            }
        }

        // The exp entry fires the valueUpdated delegate action which sets the value ...
        await store.receive(\.entries[id: .exp].delegate.valueUpdated, EntryValue(123)) {
            $0.value = EntryValue(123)
        }

        // ... and causes the rest of the entries to update
        await store.receive(\.entries[id: .bin].binding) {
            $0.entries[id: .bin]?.apply {
                $0.text = "1111011"
                $0.value = EntryValue(123)
            }
        }

        await store.receive(\.entries[id: .dec].binding) {
            $0.entries[id: .dec]?.apply {
                $0.text = "123"
                $0.value = EntryValue(123)
            }
        }

        await store.receive(\.entries[id: .hex].binding) {
            $0.entries[id: .hex]?.apply {
                $0.text = "7B"
                $0.value = EntryValue(123)
            }
        }

        await store.send(.destination(.presented(.history(.delegate(.selectionConfirmed(fakeItemInHistory.id))))))

        await store.receive(.historyItemConfirmed(fakeItemInHistory)) {
            $0.expTextTemp = nil
        }

        await store.finish()
    }

    @MainActor
    func testTextStrippedBeforeAddingToHistory() async {
        @Dependency(\.historyStore) var historyStore

        var itemAdded: String? = nil

        let store = TestStore(initialState: ContentReducer.State()) {
            ContentReducer()
        } withDependencies: {
            $0.date.now = Date(timeIntervalSinceReferenceDate: 1_234_567_890)
            $0.historyStore.addItem = { itemAdded = $0 }
            $0.mainQueue = .immediate
            $0.userDefaults = .ephemeral()
            $0.uuid = .incrementing
            $0.entryConverter = .liveValue
        }

        store.exhaustivity = .off

        await store.send(.entries(.element(id: .exp, action: .binding(.set(\.text, " 0x55 "))))) {
            $0.entries[id: .exp]?.apply {
                $0.text = " 0x55 "
                $0.value = EntryValue(85)
            }
        }

        let expected = "0x55"

        XCTAssertNoDifference(expected, itemAdded)
    }
}
