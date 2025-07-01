//
//  ArtistsView.swift
//  ChordBoard
//
//  Created by Jacob Rees on 01/07/2025.
//

import SwiftUI
import MediaPlayer
import SwiftData

struct ArtistsView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryManager
    
    let columns = [
        GridItem(.adaptive(minimum: 120, maximum: 150), spacing: 16)
    ]
    
    var body: some View {
        Group {
            if musicLibrary.authorizationStatus == .authorized {
                if musicLibrary.isLoading {
                    ProgressView("Loading Artists...")
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(musicLibrary.artists, id: \.persistentID) { artist in
                                NavigationLink(destination: ArtistDetailView(artist: artist)
                                    .environmentObject(musicLibrary)) {
                                    ArtistGridItemView(artist: artist)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            } else {
                AuthorizationView()
            }
        }
        .navigationTitle("Artists")
        .onAppear {
            if musicLibrary.authorizationStatus == .notDetermined {
                musicLibrary.requestAuthorization()
            }
        }
    }
}

struct ArtistGridItemView: View {
    let artist: MPMediaItemCollection
    
    var body: some View {
        VStack(spacing: 8) {
            AlbumArtworkView(item: artist.representativeItem, size: 100)
            
            Text(artist.representativeItem?.artist ?? "Unknown Artist")
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundColor(.primary)
        }
    }
}

struct ArtistDetailView: View {
    let artist: MPMediaItemCollection
    @EnvironmentObject var musicLibrary: MusicLibraryManager
    @Environment(\.modelContext) private var modelContext
    @StateObject private var eloManager: ELOManager
    @State private var showingAlbumRanking = false
    @State private var showingSongRanking = false
    
    init(artist: MPMediaItemCollection) {
        self.artist = artist
        let container = try! ModelContainer(for: ELORating.self, RankingSession.self)
        self._eloManager = StateObject(wrappedValue: ELOManager(modelContext: container.mainContext))
    }
    
    var songs: [MPMediaItem] {
        musicLibrary.getSongsForArtist(artist)
    }
    
    var albums: [MPMediaItemCollection] {
        musicLibrary.getAlbumsForArtist(artist)
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    AlbumArtworkView(item: artist.representativeItem, size: 120)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(artist.representativeItem?.artist ?? "Unknown Artist")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("\(songs.count) songs • \(albums.count) albums")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            if songs.count >= 2 {
                                Button("Rank Songs") {
                                    showingSongRanking = true
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            
                            if albums.count >= 2 {
                                Button("Rank Albums") {
                                    showingAlbumRanking = true
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            
            if !songs.isEmpty {
                Section("Songs") {
                    ForEach(songs, id: \.persistentID) { song in
                        ArtistSongRowView(song: song)
                    }
                }
            }
            
            if !albums.isEmpty {
                Section("Albums") {
                    ForEach(albums, id: \.persistentID) { album in
                        NavigationLink(destination: AlbumDetailView(album: album)
                            .environmentObject(musicLibrary)) {
                            ArtistAlbumRowView(album: album)
                        }
                    }
                }
            }
        }
        .navigationTitle("Artist")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAlbumRanking) {
            HeadToHeadView(
                items: albums,
                context: RankingContext.artistAlbums.contextKey(for: String(artist.rankingID)),
                contextDisplayName: "Albums by \(artist.displayArtist)",
                eloManager: eloManager,
                modelContext: modelContext
            )
        }
        .sheet(isPresented: $showingSongRanking) {
            HeadToHeadView(
                items: songs,
                context: RankingContext.artistSongs.contextKey(for: String(artist.rankingID)),
                contextDisplayName: "Songs by \(artist.displayArtist)",
                eloManager: eloManager,
                modelContext: modelContext
            )
        }
    }
}

struct ArtistSongRowView: View {
    let song: MPMediaItem
    
    var body: some View {
        HStack {
            AlbumArtworkView(item: song, size: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title ?? "Unknown Track")
                    .font(.body)
                
                Text(song.albumTitle ?? "Unknown Album")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if song.playbackDuration > 0 {
                Text(TimeFormatter.mmss(from: song.playbackDuration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct ArtistAlbumRowView: View {
    let album: MPMediaItemCollection
    
    var body: some View {
        HStack {
            AlbumArtworkView(item: album.representativeItem, size: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(album.representativeItem?.albumTitle ?? "Unknown Album")
                    .font(.body)
                
                if let year = album.representativeItem?.releaseDate {
                    Text(DateFormatter.year.string(from: year))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        ArtistsView()
            .environmentObject(MusicLibraryManager())
    }
}