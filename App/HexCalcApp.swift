import ComposableArchitecture
import ContentFeature
import SwiftUI
import XCTestDynamicOverlay

@main
struct HexCalcApp: App {
    var body: some Scene {
        WindowGroup {
            if !_XCTIsTesting {
                ContentView(store: Store(initialState: ContentReducer.State()) {
                    ContentReducer()
                })
            }
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified)
        .windowResizability(.contentSize)
    }
}
