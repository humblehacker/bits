//
//  ContentFeaturePreviewApp.swift
//  ContentFeaturePreview
//
//  Created by David Whetstone on 1/27/24.
//

import SwiftUI

@main
struct ContentFeaturePreviewApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unifiedCompact)
        .windowResizability(.contentSize)
    }
}
