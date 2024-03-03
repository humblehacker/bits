import ComposableArchitecture
@testable import ContentFeature
import CustomDump
import DataStore
@testable import HistoryFeature
import Utils
import XCTest

class ContentReducerTests: XCTestCase {
    let entryIDs: [EntryKind] = [.exp, .dec, .hex, .bin]

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

        for id in entryIDs {
            await store.send(\.entries[id: id].onAppear)
        }

        await store.send(\.entries[id: .exp].binding.text, "54 + 1") {
            $0.entries[id: .exp]?.apply {
                $0.text = "54 + 1"
                $0.value = EntryValue(55)
                $0.lastValue = EntryValue(55)
            }

            $0.entries[id: .dec]?.value = EntryValue(55)
            $0.entries[id: .hex]?.value = EntryValue(55)
            $0.entries[id: .bin]?.value = EntryValue(55)
        }

        await store.receive(\.entries[id: .exp].valueUpdated)

        await store.receive(\.entries[id: .dec].valueUpdated) {
            $0.entries[id: .dec]?.apply {
                $0.lastValue = EntryValue(55)
                $0.text = "55"
            }
        }

        await store.receive(\.entries[id: .hex].valueUpdated) {
            $0.entries[id: .hex]?.apply {
                $0.lastValue = EntryValue(55)
                $0.text = "37"
            }
        }

        await store.receive(\.entries[id: .bin].valueUpdated) {
            $0.entries[id: .bin]?.apply {
                $0.lastValue = EntryValue(55)
                $0.text = "110111"
            }
        }

        for id in entryIDs {
            await store.send(\.entries[id: id].onDisappear)
        }

        await store.finish()
    }

    @MainActor
    func testDecEntryUpdatesOtherEntries() async {
        let store = TestStore(initialState: ContentReducer.State()) {
            ContentReducer()
        } withDependencies: {
            $0.mainQueue = .immediate
            $0.userDefaults = .ephemeral()
            $0.entryConverter = .liveValue
            $0.historyStore.addItem = { _ in }
        }

        for id in entryIDs {
            await store.send(\.entries[id: id].onAppear)
        }

        await store.send(\.entries[id: .dec].binding.text, "55") {
            $0.entries[id: .dec]?.apply {
                $0.text = "55"
                $0.value = EntryValue(55)
                $0.lastValue = EntryValue(55)
            }

            $0.entries[id: .exp]?.value = EntryValue(55)
            $0.entries[id: .hex]?.value = EntryValue(55)
            $0.entries[id: .bin]?.value = EntryValue(55)
        }

        await store.receive(\.entries[id: .exp].valueUpdated) {
            $0.entries[id: .exp]?.apply {
                $0.text = "55"
                $0.lastValue = EntryValue(55)
            }
        }

        await store.receive(\.entries[id: .dec].valueUpdated)

        await store.receive(\.entries[id: .hex].valueUpdated) {
            $0.entries[id: .hex]?.apply {
                $0.text = "37"
                $0.lastValue = EntryValue(55)
            }
        }

        await store.receive(\.entries[id: .bin].valueUpdated) {
            $0.entries[id: .bin]?.apply {
                $0.text = "110111"
                $0.lastValue = EntryValue(55)
            }
        }

        for id in entryIDs {
            await store.send(\.entries[id: id].onDisappear)
        }

        await store.finish()
    }

    @MainActor
    func testHexEntryUpdatesOtherEntries() async {
        let store = TestStore(initialState: ContentReducer.State()) {
            ContentReducer()
        } withDependencies: {
            $0.mainQueue = .immediate
            $0.userDefaults = .ephemeral()
            $0.entryConverter = .liveValue
            $0.historyStore.addItem = { _ in }
        }

        for id in entryIDs {
            await store.send(\.entries[id: id].onAppear)
        }

        await store.send(\.entries[id: .hex].binding.text, "37") {
            $0.entries[id: .hex]?.apply {
                $0.text = "37"
                $0.value = EntryValue(55)
                $0.lastValue = EntryValue(55)
            }

            $0.entries[id: .exp]?.value = EntryValue(55)
            $0.entries[id: .dec]?.value = EntryValue(55)
            $0.entries[id: .bin]?.value = EntryValue(55)
        }

        await store.receive(\.entries[id: .exp].valueUpdated) {
            $0.entries[id: .exp]?.apply {
                $0.text = "55"
                $0.lastValue = EntryValue(55)
            }
        }

        await store.receive(\.entries[id: .dec].valueUpdated) {
            $0.entries[id: .dec]?.apply {
                $0.text = "55"
                $0.lastValue = EntryValue(55)
            }
        }

        await store.receive(\.entries[id: .hex].valueUpdated)

        await store.receive(\.entries[id: .bin].valueUpdated) {
            $0.entries[id: .bin]?.apply {
                $0.text = "110111"
                $0.lastValue = EntryValue(55)
            }
        }

        for id in entryIDs {
            await store.send(\.entries[id: id].onDisappear)
        }

        await store.finish()
    }

    @MainActor
    func testBinEntryUpdatesOtherEntries() async {
        let store = TestStore(initialState: ContentReducer.State()) {
            ContentReducer()
        } withDependencies: {
            $0.mainQueue = .immediate
            $0.userDefaults = .ephemeral()
            $0.entryConverter = .liveValue
            $0.historyStore.addItem = { _ in }
        }

        for id in entryIDs {
            await store.send(\.entries[id: id].onAppear)
        }

        await store.send(\.entries[id: .bin].binding.text, "110111") {
            $0.entries[id: .bin]?.apply {
                $0.text = "110111"
                $0.value = EntryValue(55)
                $0.lastValue = EntryValue(55)
            }

            $0.entries[id: .exp]?.value = EntryValue(55)
            $0.entries[id: .dec]?.value = EntryValue(55)
            $0.entries[id: .hex]?.value = EntryValue(55)
        }

        await store.receive(\.entries[id: .exp].valueUpdated) {
            $0.entries[id: .exp]?.apply {
                $0.text = "55"
                $0.lastValue = EntryValue(55)
            }
        }

        await store.receive(\.entries[id: .dec].valueUpdated) {
            $0.entries[id: .dec]?.apply {
                $0.text = "55"
                $0.lastValue = EntryValue(55)
            }
        }

        await store.receive(\.entries[id: .hex].valueUpdated) {
            $0.entries[id: .hex]?.apply {
                $0.text = "37"
                $0.lastValue = EntryValue(55)
            }
        }

        await store.receive(\.entries[id: .bin].valueUpdated)

        for id in entryIDs {
            await store.send(\.entries[id: id].onDisappear)
        }

        await store.finish()
    }

    @MainActor
    func testHistoryLaunchAndCancel() async {
        var initialState = ContentReducer.State()
        initialState.focusedField = .exp
        initialState.selectedBits = ._16
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

        for id in entryIDs {
            await store.send(\.entries[id: id].onAppear)
        }

        await store.send(.upArrowPressed) {
            $0.expTextTemp = "0xff"
        }

        await store.receive(\.historyLoaded) {
            $0.destination = .history(HistoryReducer.State(history: [fakeItemInHistory]))
        }

        // When HistoryPicker is presented the first (bottom, newest) history item is selected,
        // so we emulate the picker making that selection.
        await store.send(\.destination.history.binding.selection, fakeItemInHistory.id) {
            $0.destination?.modify(\.history) {
                $0.selection = fakeItemInHistory.id
            }
        }

        await store.receive(\.destination.presented.history.delegate.selectionChanged, fakeItemInHistory.id)

        await store.receive(\.historyItemSelected, fakeItemInHistory)

        // The exp entry's text is set to the text of the selected history item
        // by sending an explicit binding action ...
        await store.receive(\.entries[id: .exp].binding.text, "123") {
            $0.entries[id: .exp]?.apply {
                $0.text = "123"
                $0.value = EntryValue(123)
                $0.lastValue = EntryValue(123)
            }
        }

        // ... which causes the rest of the entries to update
        await store.receive(\.entries[id: .exp].valueUpdated)

        await store.receive(\.entries[id: .dec].valueUpdated) {
            $0.entries[id: .dec]?.apply {
                $0.text = "123"
                $0.lastValue = EntryValue(123)
            }
        }

        await store.receive(\.entries[id: .hex].valueUpdated) {
            $0.entries[id: .hex]?.apply {
                $0.text = "7B"
                $0.lastValue = EntryValue(123)
            }
        }

        await store.receive(\.entries[id: .bin].valueUpdated) {
            $0.entries[id: .bin]?.apply {
                $0.text = "1111011"
                $0.lastValue = EntryValue(123)
            }
        }

        // When the history picker is dismissed without a selection being confirmed,
        // the shared `value` reverts to what is was before the picker was presented ...
        await store.send(\.destination.dismiss) {
            $0.expTextTemp = nil
            $0.destination = nil
            $0.value = EntryValue(255)
        }

        // ... which reverts the exp entry's text by setting its binding directly ...
        await store.receive(\.entries[id: .exp].binding.text, "0xff") {
            $0.entries[id: .exp]?.apply {
                $0.text = "0xff"
                $0.lastValue = EntryValue(255)
            }
        }

        // ... and the other entries update accordingly
        await store.receive(\.entries[id: .exp].valueUpdated)

        await store.receive(\.entries[id: .dec].valueUpdated) {
            $0.entries[id: .dec]?.apply {
                $0.text = "255"
                $0.lastValue = EntryValue(255)
            }
        }

        await store.receive(\.entries[id: .hex].valueUpdated) {
            $0.entries[id: .hex]?.apply {
                $0.text = "FF"
                $0.lastValue = EntryValue(255)
            }
        }

        await store.receive(\.entries[id: .bin].valueUpdated) {
            $0.entries[id: .bin]?.apply {
                $0.text = "11111111"
                $0.lastValue = EntryValue(255)
            }
        }

        for id in entryIDs {
            await store.send(\.entries[id: id].onDisappear)
        }

        await store.finish()
    }

    @MainActor
    func testHistoryLaunchAndConfirm() async {
        var initialState = ContentReducer.State()
        initialState.focusedField = .exp
        initialState.selectedBits = ._16
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

        for id in entryIDs {
            await store.send(\.entries[id: id].onAppear)
        }

        await store.send(.upArrowPressed) {
            $0.expTextTemp = "0xff"
        }

        await store.receive(\.historyLoaded) {
            $0.destination = .history(HistoryReducer.State(history: [fakeItemInHistory]))
        }

        // When HistoryPicker is presented the first (bottom, newest) history item is selected,
        // so we emulate the picker making that selection.
        await store.send(\.destination.history.binding.selection, fakeItemInHistory.id) {
            $0.destination?.modify(\ContentReducer.Destination.State.Cases.history) {
                $0.selection = fakeItemInHistory.id
            }
        }

        await store.receive(\.destination.presented.history.delegate.selectionChanged, fakeItemInHistory.id)

        await store.receive(\.historyItemSelected)

        // The exp entry's text is set to the text of the selected history item
        // by sending an explicit binding action ...
        await store.receive(\.entries[id: .exp].binding.text, "123") {
            $0.entries[id: .exp]?.apply {
                $0.text = "123"
                $0.value = EntryValue(123)
                $0.lastValue = EntryValue(123)
            }
        }

        await store.receive(\.entries[id: .exp].valueUpdated)

        // ... which causes the rest of the entries to update.
        await store.receive(\.entries[id: .dec].valueUpdated) {
            $0.entries[id: .dec]?.apply {
                $0.text = "123"
                $0.lastValue = EntryValue(123)
            }
        }

        await store.receive(\.entries[id: .hex].valueUpdated) {
            $0.entries[id: .hex]?.apply {
                $0.text = "7B"
                $0.lastValue = EntryValue(123)
            }
        }

        await store.receive(\.entries[id: .bin].valueUpdated) {
            $0.entries[id: .bin]?.apply {
                $0.text = "1111011"
                $0.lastValue = EntryValue(123)
            }
        }

        // When the user confirms the selected history item ...
        await store.send(\.destination.history.delegate.selectionConfirmed, fakeItemInHistory.id)

        // we need only remove the temporary reversion state
        await store.receive(.historyItemConfirmed(fakeItemInHistory)) {
            $0.expTextTemp = nil
        }

        for id in entryIDs {
            await store.send(\.entries[id: id].onDisappear)
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

        for id in entryIDs {
            await store.send(\.entries[id: id].onAppear)
        }

        await store.send(\.entries[id: .exp].binding.text, " 0x55 ") {
            $0.entries[id: .exp]?.apply {
                $0.text = " 0x55 "
                $0.value = EntryValue(85)
                $0.lastValue = EntryValue(85)
            }
        }

        for id in entryIDs {
            await store.send(\.entries[id: id].onDisappear)
        }

        XCTAssertNoDifference("0x55", itemAdded)
    }
}
