//
//  ContentView.swift
//  ContentFeaturePreview
//
//  Created by David Whetstone on 1/27/24.
//

import ComposableArchitecture
import ContentFeature
import SwiftUI

struct ContentView: View {
    var body: some View {
        ContentFeature.ContentView(
            store: Store(initialState: .init()) {
                ContentReducer()
            }
        )
    }
}

#Preview {
    ContentView()
}
