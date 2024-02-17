import ComposableArchitecture
import ContentFeature
import SwiftUI
import XCTestDynamicOverlay

@main
struct BitsApp: App {
    var body: some Scene {
        WindowGroup {
            if !_XCTIsTesting {
                ContentView(store: Store(initialState: ContentReducer.State()) {
                    ContentReducer()
                })
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)
        .windowResizability(.contentSize)
    }
}
