//
//  RankableItem.swift
//  ChordBoard
//
//  Created by Jacob Rees on 01/07/2025.
//

import Foundation
import MediaPlayer

protocol RankableItem {
    var rankingID: MPMediaEntityPersistentID { get }
    var displayTitle: String { get }
    var displayArtist: String { get }
    var artworkItem: MPMediaItem? { get }
    var itemType: String { get }
}

extension MPMediaItemCollection: RankableItem {
    public var rankingID: MPMediaEntityPersistentID {
        return representativeItem?.albumPersistentID ?? 0
    }
    
    public var displayTitle: String {
        return representativeItem?.albumTitle ?? "Unknown Album"
    }
    
    public var displayArtist: String {
        return representativeItem?.albumArtist ?? representativeItem?.artist ?? "Unknown Artist"
    }
    
    public var artworkItem: MPMediaItem? {
        return representativeItem
    }
    
    public var itemType: String {
        return "album"
    }
}

extension MPMediaItem: RankableItem {
    public var rankingID: MPMediaEntityPersistentID {
        return self.persistentID
    }
    public var displayTitle: String {
        return self.title ?? "Unknown Track"
    }
    
    public var displayArtist: String {
        return self.artist ?? "Unknown Artist"
    }
    
    public var artworkItem: MPMediaItem? {
        return self
    }
    
    public var itemType: String {
        return "song"
    }
}

// Helper extensions for additional properties
extension MPMediaItemCollection {
    var year: String? {
        guard let date = representativeItem?.releaseDate else { return nil }
        return DateFormatter.year.string(from: date)
    }
    
    var trackCount: Int {
        return items.count
    }
}

extension MPMediaItem {
    var albumName: String {
        return albumTitle ?? "Unknown Album"
    }
    
    var duration: String {
        guard playbackDuration > 0 else { return "" }
        return TimeFormatter.mmss(from: playbackDuration)
    }
    
    var trackNumber: String {
        guard albumTrackNumber > 0 else { return "" }
        return "\(albumTrackNumber)"
    }
}