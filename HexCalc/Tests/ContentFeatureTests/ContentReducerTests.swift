import ComposableArchitecture
@testable import ContentFeature
import XCTest

@MainActor
class ContentReducerTests: XCTestCase {
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
}
