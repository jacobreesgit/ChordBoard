//
//  ContentView.swift
//  ChordBoard
//
//  Created by Jacob Rees on 01/07/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var musicLibraryManager = MusicLibraryManager()
    
    var body: some View {
        TabView {
            NavigationStack {
                SongsView()
                    .environmentObject(musicLibraryManager)
            }
            .tabItem {
                Image(systemName: "music.note")
                Text("Songs")
            }
            
            NavigationStack {
                AlbumsView()
                    .environmentObject(musicLibraryManager)
            }
            .tabItem {
                Image(systemName: "opticaldisc")
                Text("Albums")
            }
            
            NavigationStack {
                ArtistsView()
                    .environmentObject(musicLibraryManager)
            }
            .tabItem {
                Image(systemName: "person.2")
                Text("Artists")
            }
            
            NavigationStack {
                RanksView()
                    .environmentObject(musicLibraryManager)
            }
            .tabItem {
                Image(systemName: "chart.bar")
                Text("Ranks")
            }
        }
    }
}

#Preview {
    ContentView()
}
