import ComposableArchitecture
import SwiftUI

@main
struct HexCalcApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(store: Store(initialState: ContentReducer.State()) {
                ContentReducer()
            })
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified)
        .windowResizability(.contentSize)
    }
}
