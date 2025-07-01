//
//  MusicLibraryManager.swift
//  ChordBoard
//
//  Created by Jacob Rees on 01/07/2025.
//

import Foundation
import MediaPlayer
import SwiftUI
import Combine

@MainActor
class MusicLibraryManager: ObservableObject {
    @Published var authorizationStatus: MPMediaLibraryAuthorizationStatus = .notDetermined
    @Published var albums: [MPMediaItemCollection] = []
    @Published var artists: [MPMediaItemCollection] = []
    @Published var isLoading = false
    
    init() {
        authorizationStatus = MPMediaLibrary.authorizationStatus()
        if authorizationStatus == .authorized {
            loadLibraryData()
        }
    }
    
    func requestAuthorization() {
        MPMediaLibrary.requestAuthorization { [weak self] status in
            Task { @MainActor in
                self?.authorizationStatus = status
                if status == .authorized {
                    self?.loadLibraryData()
                }
            }
        }
    }
    
    private func loadLibraryData() {
        isLoading = true
        
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.loadAlbums() }
                group.addTask { await self.loadArtists() }
            }
            isLoading = false
        }
    }
    
    private func loadAlbums() async {
        let query = MPMediaQuery.albums()
        let collections = query.collections ?? []
        
        await MainActor.run {
            albums = collections.sorted { album1, album2 in
                let title1 = album1.representativeItem?.albumTitle ?? ""
                let title2 = album2.representativeItem?.albumTitle ?? ""
                return title1.localizedCaseInsensitiveCompare(title2) == .orderedAscending
            }
        }
    }
    
    private func loadArtists() async {
        let query = MPMediaQuery.artists()
        let collections = query.collections ?? []
        
        await MainActor.run {
            artists = collections.sorted { artist1, artist2 in
                let name1 = artist1.representativeItem?.artist ?? ""
                let name2 = artist2.representativeItem?.artist ?? ""
                return name1.localizedCaseInsensitiveCompare(name2) == .orderedAscending
            }
        }
    }
    
    func getSongsForAlbum(_ album: MPMediaItemCollection) -> [MPMediaItem] {
        return album.items.sorted { song1, song2 in
            let track1 = song1.albumTrackNumber
            let track2 = song2.albumTrackNumber
            return track1 < track2
        }
    }
    
    func getSongsForArtist(_ artist: MPMediaItemCollection) -> [MPMediaItem] {
        guard let artistName = artist.representativeItem?.artist else { return [] }
        
        let query = MPMediaQuery.songs()
        let predicate = MPMediaPropertyPredicate(value: artistName, forProperty: MPMediaItemPropertyArtist)
        query.addFilterPredicate(predicate)
        
        return query.items?.sorted { song1, song2 in
            let title1 = song1.title ?? ""
            let title2 = song2.title ?? ""
            return title1.localizedCaseInsensitiveCompare(title2) == .orderedAscending
        } ?? []
    }
    
    func getAlbumsForArtist(_ artist: MPMediaItemCollection) -> [MPMediaItemCollection] {
        guard let artistName = artist.representativeItem?.artist else { return [] }
        
        let query = MPMediaQuery.albums()
        let predicate = MPMediaPropertyPredicate(value: artistName, forProperty: MPMediaItemPropertyAlbumArtist)
        query.addFilterPredicate(predicate)
        
        return query.collections?.sorted { album1, album2 in
            let title1 = album1.representativeItem?.albumTitle ?? ""
            let title2 = album2.representativeItem?.albumTitle ?? ""
            return title1.localizedCaseInsensitiveCompare(title2) == .orderedAscending
        } ?? []
    }
}