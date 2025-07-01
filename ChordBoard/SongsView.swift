//
//  SongsView.swift
//  ChordBoard
//
//  Created by Jacob Rees on 01/07/2025.
//

import SwiftUI
import MediaPlayer
import SwiftData

struct SongsView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryManager
    @Environment(\.modelContext) private var modelContext
    @StateObject private var eloManager: ELOManager
    @State private var showingGlobalRanking = false
    @State private var allSongs: [MPMediaItem] = []
    
    init() {
        let container = try! ModelContainer(for: ELORating.self, RankingSession.self)
        self._eloManager = StateObject(wrappedValue: ELOManager(modelContext: container.mainContext))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if musicLibrary.authorizationStatus == .authorized {
                if allSongs.isEmpty {
                    if musicLibrary.isLoading {
                        ProgressView("Loading songs...")
                    } else {
                        emptyState
                    }
                } else {
                    songRankingInterface
                }
            } else {
                AuthorizationView()
            }
        }
        .navigationTitle("Songs")
        .onAppear {
            loadAllSongs()
        }
        .sheet(isPresented: $showingGlobalRanking) {
            HeadToHeadView(
                items: allSongs,
                context: RankingContext.allSongs.contextKey(for: nil),
                contextDisplayName: "All Songs",
                eloManager: eloManager,
                modelContext: modelContext
            )
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Songs Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add music to your library to start ranking songs")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var songRankingInterface: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "music.note")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Global Song Ranking")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text("\(allSongs.count) songs in your library")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Battle Button
            if allSongs.count >= 2 {
                Button(action: { showingGlobalRanking = true }) {
                    HStack {
                        Image(systemName: "crown")
                        Text("Rank All Songs")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .rounded()
                }
                .padding(.horizontal, 40)
            }
            
            // Current Rankings Preview
            globalRankingsPreview
            
            Spacer()
        }
        .padding()
    }
    
    private var globalRankingsPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Top Ranked Songs")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink("See All") {
                    RankingResultsView(
                        context: RankingContext.allSongs.contextKey(for: nil),
                        contextDisplayName: "All Songs"
                    )
                    .environmentObject(musicLibrary)
                }
                .font(.subheadline)
            }
            
            let topRankings = eloManager.getTopRated(
                for: RankingContext.allSongs.contextKey(for: nil),
                count: 3
            )
            
            if topRankings.isEmpty {
                Text("No rankings yet - start battling to see results!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(Array(topRankings.enumerated()), id: \.element.id) { index, rating in
                    CompactRankingRowView(
                        rank: index + 1,
                        rating: rating,
                        allSongs: allSongs
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .rounded()
        .padding(.horizontal)
    }
    
    private func loadAllSongs() {
        guard musicLibrary.authorizationStatus == .authorized else { return }
        
        var songs: [MPMediaItem] = []
        
        // Collect all songs from all albums
        for album in musicLibrary.albums {
            songs.append(contentsOf: album.items)
        }
        
        // Remove duplicates and sort
        let uniqueSongs = Array(Set(songs)).sorted { song1, song2 in
            let title1 = song1.title ?? ""
            let title2 = song2.title ?? ""
            return title1.localizedCaseInsensitiveCompare(title2) == .orderedAscending
        }
        
        allSongs = uniqueSongs
    }
}

struct CompactRankingRowView: View {
    let rank: Int
    let rating: ELORating
    let allSongs: [MPMediaItem]
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank
            Text("\(rank)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(rank <= 3 ? .gold : .primary)
                .frame(width: 30)
            
            // Song info
            if let song = findSong() {
                HStack(spacing: 8) {
                    AlbumArtworkView(item: song, size: 40)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(song.title ?? "Unknown Track")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        Text(song.artist ?? "Unknown Artist")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Text("\(Int(rating.rating))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            } else {
                Text("Song not found")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(rating.rating))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func findSong() -> MPMediaItem? {
        guard let persistentID = MPMediaEntityPersistentID(rating.itemID) else { return nil }
        return allSongs.first { $0.rankingID == persistentID }
    }
}

#Preview {
    NavigationStack {
        SongsView()
            .environmentObject(MusicLibraryManager())
    }
}