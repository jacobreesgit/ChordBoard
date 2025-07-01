//
//  ChordBoardApp.swift
//  ChordBoard
//
//  Created by Jacob Rees on 01/07/2025.
//

import SwiftUI
import SwiftData

@main
struct ChordBoardApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(for: ELORating.self, RankingSession.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}
