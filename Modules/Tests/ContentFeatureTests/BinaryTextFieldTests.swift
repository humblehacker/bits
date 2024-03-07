import ComposableArchitecture
@testable import ContentFeature
import Types
import XCTest

final class BinaryTextFieldTests: XCTestCase {
    @MainActor
    func testSelectionBoundsChangeWhenBitsChanges() async throws {
        let store = TestStore(initialState: .init()) {
            BinaryTextFieldReducer()
        }

        XCTAssertEqual(store.state.selection.bounds, 48 ..< 64)

        let task = await store.send(.task)

        store.state.bits = ._8

        await store.receive(\.bitsUpdated) {
            $0.selection.bounds = 56 ..< 64
        }

        await task.cancel()
    }
}
