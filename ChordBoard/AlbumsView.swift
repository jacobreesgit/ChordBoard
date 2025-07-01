//
//  AlbumsView.swift
//  ChordBoard
//
//  Created by Jacob Rees on 01/07/2025.
//

import SwiftUI
import MediaPlayer
import SwiftData

struct AlbumsView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryManager
    
    let columns = [
        GridItem(.adaptive(minimum: 120, maximum: 150), spacing: 16)
    ]
    
    var body: some View {
        Group {
            if musicLibrary.authorizationStatus == .authorized {
                if musicLibrary.isLoading {
                    ProgressView("Loading Albums...")
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(musicLibrary.albums, id: \.persistentID) { album in
                                NavigationLink(destination: AlbumDetailView(album: album)
                                    .environmentObject(musicLibrary)) {
                                    AlbumGridItemView(album: album)
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
        .navigationTitle("Albums")
        .onAppear {
            if musicLibrary.authorizationStatus == .notDetermined {
                musicLibrary.requestAuthorization()
            }
        }
    }
}

struct AlbumGridItemView: View {
    let album: MPMediaItemCollection
    
    var body: some View {
        VStack(spacing: 8) {
            AlbumArtworkView(item: album.representativeItem, size: 100)
            
            VStack(spacing: 2) {
                Text(album.representativeItem?.albumTitle ?? "Unknown Album")
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                Text(album.representativeItem?.albumArtist ?? "Unknown Artist")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct AlbumDetailView: View {
    let album: MPMediaItemCollection
    @EnvironmentObject var musicLibrary: MusicLibraryManager
    @Environment(\.modelContext) private var modelContext
    @StateObject private var eloManager: ELOManager
    @State private var showingSongRanking = false
    
    init(album: MPMediaItemCollection) {
        self.album = album
        let container = try! ModelContainer(for: ELORating.self, RankingSession.self)
        self._eloManager = StateObject(wrappedValue: ELOManager(modelContext: container.mainContext))
    }
    
    var songs: [MPMediaItem] {
        musicLibrary.getSongsForAlbum(album)
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    AlbumArtworkView(item: album.representativeItem, size: 120)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(album.representativeItem?.albumTitle ?? "Unknown Album")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(album.representativeItem?.albumArtist ?? "Unknown Artist")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let year = album.representativeItem?.releaseDate {
                            Text(DateFormatter.year.string(from: year))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if songs.count >= 2 {
                            Button("Rank Songs") {
                                showingSongRanking = true
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            
            Section("Songs") {
                ForEach(songs, id: \.persistentID) { song in
                    SongRowView(song: song)
                }
            }
        }
        .navigationTitle("Album")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSongRanking) {
            HeadToHeadView(
                items: songs,
                context: RankingContext.albumSongs.contextKey(for: String(album.rankingID)),
                contextDisplayName: "Songs from \(album.displayTitle)",
                eloManager: eloManager,
                modelContext: modelContext
            )
        }
    }
}

struct SongRowView: View {
    let song: MPMediaItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                if song.albumTrackNumber > 0 {
                    Text("\(song.albumTrackNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 20, alignment: .trailing)
                }
                
                Text(song.title ?? "Unknown Track")
                    .font(.body)
                
                Spacer()
                
                if song.playbackDuration > 0 {
                    Text(TimeFormatter.mmss(from: song.playbackDuration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AlbumsView()
            .environmentObject(MusicLibraryManager())
    }
}