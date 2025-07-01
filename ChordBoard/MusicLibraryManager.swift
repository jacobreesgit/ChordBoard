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
    
    private var loadingTask: Task<Void, Never>?
    
    init() {
        authorizationStatus = MPMediaLibrary.authorizationStatus()
        if authorizationStatus == .authorized {
            loadLibraryData()
        }
    }
    
    deinit {
        loadingTask?.cancel()
    }
    
    func requestAuthorization() {
        guard authorizationStatus != .authorized else { return }
        
        MPMediaLibrary.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
                if status == .authorized {
                    self?.loadLibraryData()
                }
            }
        }
    }
    
    private func loadLibraryData() {
        guard !isLoading else { return }
        
        loadingTask?.cancel()
        isLoading = true
        
        loadingTask = Task { @MainActor in
            defer { isLoading = false }
            
            do {
                async let albumsResult = loadAlbums()
                async let artistsResult = loadArtists()
                
                let (loadedAlbums, loadedArtists) = try await (albumsResult, artistsResult)
                
                if !Task.isCancelled {
                    albums = loadedAlbums
                    artists = loadedArtists
                }
            } catch {
                print("Error loading library data: \(error)")
            }
        }
    }
    
    private func loadAlbums() async throws -> [MPMediaItemCollection] {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let query = MPMediaQuery.albums()
                let collections = query.collections ?? []
                
                let sorted = collections.sorted { album1, album2 in
                    let title1 = album1.representativeItem?.albumTitle ?? ""
                    let title2 = album2.representativeItem?.albumTitle ?? ""
                    return title1.localizedCaseInsensitiveCompare(title2) == .orderedAscending
                }
                
                continuation.resume(returning: sorted)
            }
        }
    }
    
    private func loadArtists() async throws -> [MPMediaItemCollection] {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let query = MPMediaQuery.artists()
                let collections = query.collections ?? []
                
                let sorted = collections.sorted { artist1, artist2 in
                    let name1 = artist1.representativeItem?.artist ?? ""
                    let name2 = artist2.representativeItem?.artist ?? ""
                    return name1.localizedCaseInsensitiveCompare(name2) == .orderedAscending
                }
                
                continuation.resume(returning: sorted)
            }
        }
    }
    
    func getSongsForAlbum(_ album: MPMediaItemCollection) -> [MPMediaItem] {
        guard !album.items.isEmpty else { return [] }
        
        return album.items.sorted { song1, song2 in
            let track1 = song1.albumTrackNumber
            let track2 = song2.albumTrackNumber
            return track1 < track2
        }
    }
    
    func getSongsForArtist(_ artist: MPMediaItemCollection) -> [MPMediaItem] {
        guard let artistName = artist.representativeItem?.artist, 
              !artistName.isEmpty else { return [] }
        
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
        guard let artistName = artist.representativeItem?.artist,
              !artistName.isEmpty else { return [] }
        
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