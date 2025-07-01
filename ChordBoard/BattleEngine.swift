//
//  BattleEngine.swift
//  ChordBoard
//
//  Created by Jacob Rees on 01/07/2025.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
class BattleEngine: ObservableObject {
    private let eloManager: ELOManager
    private let modelContext: ModelContext
    
    var items: [RankableItem] = []
    var context: String = ""
    var currentSession: RankingSession?
    var currentBattle: BattlePair?
    var battleQueue: [BattlePair] = []
    var completedBattles: Int = 0
    var skippedBattles: Int = 0
    
    private let maxRatingDifference: Double = 600.0
    private let targetBattlesPerItem: Int = 15
    
    init(eloManager: ELOManager, modelContext: ModelContext) {
        self.eloManager = eloManager
        self.modelContext = modelContext
    }
    
    func setupBattle(items: [RankableItem], context: String) {
        self.items = items
        self.context = context
        self.completedBattles = 0
        self.skippedBattles = 0
        
        guard items.count >= 2 else {
            print("Need at least 2 items to battle")
            return
        }
        
        // Create battle queue with smart pairing
        generateBattleQueue()
        
        // Create or update session
        let totalBattles = battleQueue.count
        currentSession = RankingSession(context: context, totalBattles: totalBattles)
        modelContext.insert(currentSession!)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving battle session: \(error)")
        }
        
        // Start first battle
        getNextBattle()
    }
    
    @discardableResult
    func getNextBattle() -> BattlePair? {
        guard !battleQueue.isEmpty else {
            completeBattleSession()
            return nil
        }
        
        currentBattle = battleQueue.removeFirst()
        return currentBattle
    }
    
    func processBattleResult(_ action: BattleAction) {
        guard let battle = currentBattle else { return }
        
        switch action {
        case .selectWinner(let winner):
            let loser = (winner.rankingID == battle.item1.rankingID) ? battle.item2 : battle.item1
            eloManager.updateRatings(winner: winner, loser: loser, context: context)
            completedBattles += 1
            
        case .likeBoth:
            eloManager.handleTie(item1: battle.item1, item2: battle.item2, context: context)
            completedBattles += 1
            
        case .skip:
            skippedBattles += 1
        }
        
        // Update session progress
        currentSession?.completedBattles = completedBattles
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving battle progress: \(error)")
        }
        
        // Get next battle
        getNextBattle()
    }
    
    var isComplete: Bool {
        return battleQueue.isEmpty
    }
    
    var progress: Double {
        guard let session = currentSession, session.totalBattles > 0 else { return 0.0 }
        return Double(completedBattles) / Double(session.totalBattles)
    }
    
    var battlesRemaining: Int {
        return battleQueue.count
    }
    
    // MARK: - Private Methods
    
    private func generateBattleQueue() {
        battleQueue.removeAll()
        
        let itemCount = items.count
        guard itemCount >= 2 else { return }
        
        // For small collections, do round-robin
        if itemCount <= 10 {
            generateRoundRobinBattles()
        } else {
            generateSmartBattles()
        }
        
        // Shuffle to avoid predictable patterns
        battleQueue.shuffle()
    }
    
    private func generateRoundRobinBattles() {
        for i in 0..<items.count {
            for j in (i+1)..<items.count {
                let battle = BattlePair(item1: items[i], item2: items[j], context: context)
                battleQueue.append(battle)
            }
        }
    }
    
    private func generateSmartBattles() {
        // Get current ratings for all items
        let itemsWithRatings = items.map { item in
            (item: item, rating: eloManager.getRating(for: item, context: context))
        }
        
        // Sort by current rating
        let sortedItems = itemsWithRatings.sorted { $0.rating.rating > $1.rating.rating }
        
        var battlesPerItem: [String: Int] = [:]
        
        // Generate battles focusing on items with similar ratings
        for i in 0..<sortedItems.count {
            let currentItem = sortedItems[i]
            let currentBattles = battlesPerItem[String(currentItem.item.rankingID)] ?? 0
            
            guard currentBattles < targetBattlesPerItem else { continue }
            
            // Find suitable opponents (similar rating, not over-battled)
            var opponents: [(item: RankableItem, rating: ELORating)] = []
            
            // Look for opponents within rating range
            for j in 0..<sortedItems.count {
                guard i != j else { continue }
                
                let potentialOpponent = sortedItems[j]
                let opponentBattles = battlesPerItem[String(potentialOpponent.item.rankingID)] ?? 0
                
                guard opponentBattles < targetBattlesPerItem else { continue }
                
                let ratingDiff = abs(currentItem.rating.rating - potentialOpponent.rating.rating)
                guard ratingDiff <= maxRatingDifference else { continue }
                
                opponents.append(potentialOpponent)
            }
            
            // Battle with closest-rated opponents first
            opponents.sort { abs($0.rating.rating - currentItem.rating.rating) < abs($1.rating.rating - currentItem.rating.rating) }
            
            // Add battles with top opponents
            let maxOpponents = min(opponents.count, targetBattlesPerItem - currentBattles)
            for opponentIndex in 0..<maxOpponents {
                let opponent = opponents[opponentIndex]
                
                let battle = BattlePair(item1: currentItem.item, item2: opponent.item, context: context)
                battleQueue.append(battle)
                
                battlesPerItem[String(currentItem.item.rankingID)] = (battlesPerItem[String(currentItem.item.rankingID)] ?? 0) + 1
                battlesPerItem[String(opponent.item.rankingID)] = (battlesPerItem[String(opponent.item.rankingID)] ?? 0) + 1
            }
        }
        
        // If we don't have enough battles, add some random ones
        if battleQueue.count < items.count * 3 {
            addRandomBattles(current: battleQueue.count, target: items.count * 3)
        }
    }
    
    private func addRandomBattles(current: Int, target: Int) {
        let needed = target - current
        
        for _ in 0..<needed {
            let item1 = items.randomElement()!
            let item2 = items.randomElement()!
            
            guard item1.rankingID != item2.rankingID else { continue }
            
            // Check if this battle already exists
            let battleExists = battleQueue.contains { battle in
                (battle.item1.rankingID == item1.rankingID && battle.item2.rankingID == item2.rankingID) ||
                (battle.item1.rankingID == item2.rankingID && battle.item2.rankingID == item1.rankingID)
            }
            
            if !battleExists {
                let battle = BattlePair(item1: item1, item2: item2, context: context)
                battleQueue.append(battle)
            }
        }
    }
    
    private func completeBattleSession() {
        currentSession?.completedAt = Date()
        currentSession?.completedBattles = completedBattles
        
        do {
            try modelContext.save()
        } catch {
            print("Error completing battle session: \(error)")
        }
    }
}