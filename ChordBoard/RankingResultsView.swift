//
//  RankingResultsView.swift
//  ChordBoard
//
//  Created by Jacob Rees on 01/07/2025.
//

import SwiftUI
import MediaPlayer
import SwiftData

struct RankingResultsView: View {
    let context: String
    let contextDisplayName: String
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var eloManager: ELOManager
    @State private var rankings: [ELORating] = []
    @State private var isLoading = true
    
    init(context: String, contextDisplayName: String) {
        self.context = context
        self.contextDisplayName = contextDisplayName
        let container = try! ModelContainer(for: ELORating.self, RankingSession.self)
        self._eloManager = StateObject(wrappedValue: ELOManager(modelContext: container.mainContext))
    }
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading rankings...")
                } else if rankings.isEmpty {
                    emptyState
                } else {
                    rankingsList
                }
            }
            .navigationTitle(contextDisplayName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadRankings()
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Rankings Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Complete some battles to see rankings here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var rankingsList: some View {
        List {
            Section {
                statisticsSection
            }
            
            Section("Rankings") {
                ForEach(Array(rankings.enumerated()), id: \.element.id) { index, rating in
                    RankingRowView(
                        rank: index + 1,
                        rating: rating,
                        context: context
                    )
                }
            }
        }
    }
    
    private var statisticsSection: some View {
        let stats = eloManager.getContextStatistics(for: context)
        
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Items")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(stats.totalItems)")
                    .font(.headline)
            }
            
            Spacer()
            
            VStack(alignment: .center, spacing: 4) {
                Text("Total Battles")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(stats.totalBattles)")
                    .font(.headline)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Avg Rating")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(Int(stats.averageRating))")
                    .font(.headline)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func loadRankings() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            rankings = eloManager.getRankings(for: context)
            isLoading = false
        }
    }
}

struct RankingRowView: View {
    let rank: Int
    let rating: ELORating
    let context: String
    
    @EnvironmentObject var musicLibrary: MusicLibraryManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank Badge
            rankBadge
            
            // Item Info
            if let item = findItem() {
                HStack(spacing: 12) {
                    AlbumArtworkView(item: item.artworkItem, size: 50)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.displayTitle)
                            .font(.headline)
                            .lineLimit(2)
                        
                        Text(item.displayArtist)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        if let song = item as? MPMediaItem {
                            Text(song.albumName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    // Rating Info
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(rating.rating))")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("\(rating.battles) battles")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        confidenceIndicator
                    }
                }
            } else {
                // Fallback for items not found in current library
                VStack(alignment: .leading, spacing: 2) {
                    Text("Item \(rating.itemID)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Not found in library")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(rating.rating))")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("\(rating.battles) battles")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var rankBadge: some View {
        ZStack {
            Circle()
                .fill(rankColor)
                .frame(width: 30, height: 30)
            
            Text("\(rank)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .gold
        case 2: return .gray
        case 3: return Color.brown
        default: return .blue
        }
    }
    
    private var confidenceIndicator: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(index < Int(rating.confidence * 5) ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 4, height: 4)
            }
        }
    }
    
    private func findItem() -> RankableItem? {
        guard let persistentID = MPMediaEntityPersistentID(rating.itemID) else { return nil }
        
        if rating.itemType == "album" {
            return musicLibrary.albums.first { collection in
                collection.rankingID == persistentID
            }
        } else {
            // For songs, we need to search through all albums
            for album in musicLibrary.albums {
                if let song = album.items.first(where: { $0.rankingID == persistentID }) {
                    return song
                }
            }
            
            // Also check artist songs
            for artist in musicLibrary.artists {
                let songs = musicLibrary.getSongsForArtist(artist)
                if let song = songs.first(where: { $0.rankingID == persistentID }) {
                    return song
                }
            }
        }
        
        return nil
    }
}

#Preview {
    RankingResultsView(
        context: "preview",
        contextDisplayName: "Preview Rankings"
    )
    .environmentObject(MusicLibraryManager())
}