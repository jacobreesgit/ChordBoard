//
//  RanksView.swift
//  ChordBoard
//
//  Created by Jacob Rees on 01/07/2025.
//

import SwiftUI
import MediaPlayer
import SwiftData

struct RanksView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryManager
    @Environment(\.modelContext) private var modelContext
    @StateObject private var eloManager: ELOManager
    @State private var selectedContext: RankingContext = .allSongs
    
    init() {
        let container = try! ModelContainer(for: ELORating.self, RankingSession.self)
        self._eloManager = StateObject(wrappedValue: ELOManager(modelContext: container.mainContext))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if musicLibrary.authorizationStatus == .authorized {
                    rankingOverview
                } else {
                    AuthorizationView()
                }
            }
            .navigationTitle("Rankings")
        }
    }
    
    private var rankingOverview: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Header
                headerSection
                
                // Context Cards
                ForEach(RankingContext.allCases, id: \.self) { context in
                    RankingContextCard(
                        context: context,
                        eloManager: eloManager,
                        musicLibrary: musicLibrary
                    )
                }
            }
            .padding()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Music Rankings")
                .font(.title)
                .fontWeight(.bold)
            
            Text("View all your ranking results across different contexts")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct RankingContextCard: View {
    let context: RankingContext
    let eloManager: ELOManager
    let musicLibrary: MusicLibraryManager
    
    var body: some View {
        NavigationLink(destination: destinationView) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(contextDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: contextIcon)
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                // Statistics
                let stats = eloManager.getContextStatistics(for: contextKey)
                
                HStack {
                    StatView(title: "Items", value: "\(stats.totalItems)")
                    Spacer()
                    StatView(title: "Battles", value: "\(stats.totalBattles)")
                    Spacer()
                    StatView(title: "Avg Rating", value: "\(Int(stats.averageRating))")
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .rounded()
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var contextDescription: String {
        switch context {
        case .artistAlbums: return "Compare albums within each artist"
        case .artistSongs: return "Compare songs within each artist"
        case .albumSongs: return "Compare songs within each album"
        case .allSongs: return "Global song rankings across your library"
        }
    }
    
    private var contextIcon: String {
        switch context {
        case .artistAlbums: return "opticaldisc"
        case .artistSongs: return "music.note"
        case .albumSongs: return "music.note.list"
        case .allSongs: return "crown"
        }
    }
    
    private var contextKey: String {
        // For overview, we'll look at global contexts or aggregate
        switch context {
        case .allSongs: return context.contextKey(for: nil)
        default: return "" // Will show 0 stats for context-specific items
        }
    }
    
    @ViewBuilder
    private var destinationView: some View {
        switch context {
        case .allSongs:
            RankingResultsView(
                context: context.contextKey(for: nil),
                contextDisplayName: context.displayName
            )
            .environmentObject(musicLibrary)
        
        default:
            ContextSpecificRankingsView(
                context: context,
                eloManager: eloManager,
                musicLibrary: musicLibrary
            )
        }
    }
}

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ContextSpecificRankingsView: View {
    let context: RankingContext
    let eloManager: ELOManager
    let musicLibrary: MusicLibraryManager
    
    var body: some View {
        List {
            Section {
                Text("Context-specific rankings show results grouped by \(contextGrouping)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // This would need more complex implementation to show
            // artist-specific or album-specific rankings
            Section("Available Rankings") {
                switch context {
                case .artistAlbums:
                    ForEach(musicLibrary.artists, id: \.persistentID) { artist in
                        if musicLibrary.getAlbumsForArtist(artist).count >= 2 {
                            NavigationLink(destination: 
                                RankingResultsView(
                                    context: context.contextKey(for: String(artist.rankingID)),
                                    contextDisplayName: "Albums by \(artist.displayArtist)"
                                )
                                .environmentObject(musicLibrary)
                            ) {
                                ArtistRankingRowView(artist: artist, context: context, eloManager: eloManager)
                            }
                        }
                    }
                
                case .artistSongs:
                    ForEach(musicLibrary.artists, id: \.persistentID) { artist in
                        if musicLibrary.getSongsForArtist(artist).count >= 2 {
                            NavigationLink(destination: 
                                RankingResultsView(
                                    context: context.contextKey(for: String(artist.rankingID)),
                                    contextDisplayName: "Songs by \(artist.displayArtist)"
                                )
                                .environmentObject(musicLibrary)
                            ) {
                                ArtistRankingRowView(artist: artist, context: context, eloManager: eloManager)
                            }
                        }
                    }
                
                case .albumSongs:
                    ForEach(musicLibrary.albums, id: \.persistentID) { album in
                        if musicLibrary.getSongsForAlbum(album).count >= 2 {
                            NavigationLink(destination: 
                                RankingResultsView(
                                    context: context.contextKey(for: String(album.rankingID)),
                                    contextDisplayName: "Songs from \(album.displayTitle)"
                                )
                                .environmentObject(musicLibrary)
                            ) {
                                AlbumRankingRowView(album: album, eloManager: eloManager)
                            }
                        }
                    }
                
                default:
                    EmptyView()
                }
            }
        }
        .navigationTitle(context.displayName)
    }
    
    private var contextGrouping: String {
        switch context {
        case .artistAlbums: return "artist"
        case .artistSongs: return "artist"
        case .albumSongs: return "album"
        case .allSongs: return "library"
        }
    }
}

struct ArtistRankingRowView: View {
    let artist: MPMediaItemCollection
    let context: RankingContext
    let eloManager: ELOManager
    
    var body: some View {
        HStack {
            AlbumArtworkView(item: artist.representativeItem, size: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(artist.displayArtist)
                    .font(.headline)
                
                Text(contextDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            let stats = eloManager.getContextStatistics(for: context.contextKey(for: String(artist.rankingID)))
            Text("\(stats.totalBattles) battles")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var contextDescription: String {
        switch context {
        case .artistAlbums: return "Album rankings"
        case .artistSongs: return "Song rankings"
        default: return ""
        }
    }
}

struct AlbumRankingRowView: View {
    let album: MPMediaItemCollection
    let eloManager: ELOManager
    
    var body: some View {
        HStack {
            AlbumArtworkView(item: album.representativeItem, size: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(album.displayTitle)
                    .font(.headline)
                
                Text(album.displayArtist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            let stats = eloManager.getContextStatistics(for: RankingContext.albumSongs.contextKey(for: String(album.rankingID)))
            Text("\(stats.totalBattles) battles")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        RanksView()
            .environmentObject(MusicLibraryManager())
    }
}