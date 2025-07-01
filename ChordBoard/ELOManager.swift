//
//  ELOManager.swift
//  ChordBoard
//
//  Created by Jacob Rees on 01/07/2025.
//

import Foundation
import SwiftData
import MediaPlayer
import SwiftUI
import Combine

@MainActor
class ELOManager: ObservableObject {
    private let modelContext: ModelContext
    private var ratings: [String: ELORating] = [:]
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadRatings()
    }
    
    private func loadRatings() {
        do {
            let descriptor = FetchDescriptor<ELORating>()
            let allRatings = try modelContext.fetch(descriptor)
            
            ratings = Dictionary(uniqueKeysWithValues: allRatings.map { rating in
                let key = "\(rating.context):\(rating.itemID)"
                return (key, rating)
            })
        } catch {
            print("Error loading ELO ratings: \(error)")
        }
    }
    
    func getRating(for item: RankableItem, context: String) -> ELORating {
        let key = "\(context):\(item.rankingID)"
        
        if let existingRating = ratings[key] {
            return existingRating
        }
        
        // Create new rating
        let newRating = ELORating(
            itemID: String(item.rankingID),
            itemType: item.itemType,
            context: context
        )
        
        modelContext.insert(newRating)
        ratings[key] = newRating
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving new ELO rating: \(error)")
        }
        
        return newRating
    }
    
    func updateRatings(winner: RankableItem, loser: RankableItem, context: String) {
        let winnerRating = getRating(for: winner, context: context)
        let loserRating = getRating(for: loser, context: context)
        
        let expectedWinner = calculateExpectedScore(
            playerRating: winnerRating.rating,
            opponentRating: loserRating.rating
        )
        let expectedLoser = 1.0 - expectedWinner
        
        // Winner gets 1 point, loser gets 0
        let newWinnerRating = winnerRating.rating + Double(winnerRating.kFactor) * (1.0 - expectedWinner)
        let newLoserRating = loserRating.rating + Double(loserRating.kFactor) * (0.0 - expectedLoser)
        
        // Apply rating constraints
        winnerRating.rating = max(100, min(3000, newWinnerRating))
        loserRating.rating = max(100, min(3000, newLoserRating))
        
        // Update battle statistics
        winnerRating.battles += 1
        winnerRating.wins += 1
        winnerRating.lastBattleDate = Date()
        
        loserRating.battles += 1
        loserRating.losses += 1
        loserRating.lastBattleDate = Date()
        
        saveRatings()
    }
    
    func handleTie(item1: RankableItem, item2: RankableItem, context: String) {
        let rating1 = getRating(for: item1, context: context)
        let rating2 = getRating(for: item2, context: context)
        
        let expected1 = calculateExpectedScore(
            playerRating: rating1.rating,
            opponentRating: rating2.rating
        )
        let expected2 = 1.0 - expected1
        
        // Both get 0.5 points for a tie
        let newRating1 = rating1.rating + Double(rating1.kFactor) * (0.5 - expected1)
        let newRating2 = rating2.rating + Double(rating2.kFactor) * (0.5 - expected2)
        
        // Apply rating constraints
        rating1.rating = max(100, min(3000, newRating1))
        rating2.rating = max(100, min(3000, newRating2))
        
        // Update battle statistics
        rating1.battles += 1
        rating1.ties += 1
        rating1.lastBattleDate = Date()
        
        rating2.battles += 1
        rating2.ties += 1
        rating2.lastBattleDate = Date()
        
        saveRatings()
    }
    
    func getRankings(for context: String, limit: Int? = nil) -> [ELORating] {
        do {
            var descriptor = FetchDescriptor<ELORating>(
                predicate: #Predicate { $0.context == context },
                sortBy: [SortDescriptor(\.rating, order: .reverse)]
            )
            
            if let limit = limit {
                descriptor.fetchLimit = limit
            }
            
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching rankings: \(error)")
            return []
        }
    }
    
    func getTopRated(for context: String, count: Int = 10) -> [ELORating] {
        return getRankings(for: context, limit: count)
    }
    
    func getRatingHistory(for item: RankableItem, context: String) -> ELORating? {
        return getRating(for: item, context: context)
    }
    
    func resetRatings(for context: String) {
        do {
            let descriptor = FetchDescriptor<ELORating>(
                predicate: #Predicate { $0.context == context }
            )
            let contextRatings = try modelContext.fetch(descriptor)
            
            for rating in contextRatings {
                modelContext.delete(rating)
            }
            
            try modelContext.save()
            loadRatings() // Reload cache
        } catch {
            print("Error resetting ratings: \(error)")
        }
    }
    
    func deleteAllRatings() {
        do {
            try modelContext.delete(model: ELORating.self)
            try modelContext.delete(model: RankingSession.self)
            try modelContext.save()
            ratings.removeAll()
        } catch {
            print("Error deleting all ratings: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func calculateExpectedScore(playerRating: Double, opponentRating: Double) -> Double {
        return 1.0 / (1.0 + pow(10.0, (opponentRating - playerRating) / 400.0))
    }
    
    private func saveRatings() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving ratings: \(error)")
        }
    }
    
    // MARK: - Statistics
    
    func getContextStatistics(for context: String) -> (totalItems: Int, totalBattles: Int, averageRating: Double) {
        let contextRatings = getRankings(for: context)
        
        let totalItems = contextRatings.count
        let totalBattles = contextRatings.reduce(0) { $0 + $1.battles }
        let averageRating = contextRatings.isEmpty ? 1500.0 : 
            contextRatings.reduce(0.0) { $0 + $1.rating } / Double(contextRatings.count)
        
        return (totalItems, totalBattles, averageRating)
    }
}