//
//  ELOModels.swift
//  ChordBoard
//
//  Created by Jacob Rees on 01/07/2025.
//

import Foundation
import SwiftData
import MediaPlayer

@Model
class ELORating {
    var itemID: String
    var itemType: String
    var context: String
    var rating: Double
    var battles: Int
    var wins: Int
    var losses: Int
    var ties: Int
    var lastBattleDate: Date
    var createdDate: Date
    
    init(itemID: String, itemType: String, context: String, rating: Double = 1500.0) {
        self.itemID = itemID
        self.itemType = itemType
        self.context = context
        self.rating = rating
        self.battles = 0
        self.wins = 0
        self.losses = 0
        self.ties = 0
        self.lastBattleDate = Date()
        self.createdDate = Date()
    }
    
    var kFactor: Int {
        return battles < 10 ? 32 : 16
    }
    
    var winRate: Double {
        guard battles > 0 else { return 0.0 }
        return Double(wins) / Double(battles)
    }
    
    var confidence: Double {
        switch battles {
        case 0..<5: return 0.2
        case 5..<15: return 0.5
        case 15..<30: return 0.7
        case 30..<50: return 0.85
        default: return 1.0
        }
    }
}

@Model
class RankingSession {
    var sessionID: String
    var context: String
    var completedAt: Date?
    var totalBattles: Int
    var completedBattles: Int
    var createdAt: Date
    
    init(context: String, totalBattles: Int) {
        self.sessionID = UUID().uuidString
        self.context = context
        self.totalBattles = totalBattles
        self.completedBattles = 0
        self.createdAt = Date()
    }
    
    var isComplete: Bool {
        return completedBattles >= totalBattles
    }
    
    var progress: Double {
        guard totalBattles > 0 else { return 1.0 }
        return Double(completedBattles) / Double(totalBattles)
    }
}

enum RankingContext: String, CaseIterable {
    case artistAlbums = "artist_albums"
    case artistSongs = "artist_songs"
    case albumSongs = "album_songs"
    case allSongs = "global_songs"
    
    func contextKey(for id: String?) -> String {
        switch self {
        case .artistAlbums: return "artist_albums:\(id ?? "")"
        case .artistSongs: return "artist_songs:\(id ?? "")"
        case .albumSongs: return "album_songs:\(id ?? "")"
        case .allSongs: return "global_songs"
        }
    }
    
    var displayName: String {
        switch self {
        case .artistAlbums: return "Artist Albums"
        case .artistSongs: return "Artist Songs"
        case .albumSongs: return "Album Songs"
        case .allSongs: return "All Songs"
        }
    }
}

enum BattleAction {
    case selectWinner(RankableItem)
    case likeBoth
    case skip
}

struct BattlePair {
    let item1: RankableItem
    let item2: RankableItem
    let context: String
    
    var expectedScore1: Double {
        // This will be calculated by ELOManager when needed
        return 0.5
    }
    
    var expectedScore2: Double {
        return 1.0 - expectedScore1
    }
    
    var ratingDifference: Double {
        // This will be calculated by ELOManager when needed
        return 0.0
    }
}