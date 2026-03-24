//
//  ContentView.swift
//  PargrexslulmorBrelden
//
//  Created by Роман Главацкий on 24.03.2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var progress = ProgressStore()

    var body: some View {
        RootView()
            .environmentObject(progress)
            .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
