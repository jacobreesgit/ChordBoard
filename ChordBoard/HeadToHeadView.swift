//
//  HeadToHeadView.swift
//  ChordBoard
//
//  Created by Jacob Rees on 01/07/2025.
//

import SwiftUI
import MediaPlayer
import SwiftData

struct HeadToHeadView: View {
    let items: [RankableItem]
    let context: String
    let contextDisplayName: String
    let eloManager: ELOManager
    
    @StateObject private var battleEngine: BattleEngine
    @Environment(\.dismiss) private var dismiss
    @State private var showingResults = false
    @State private var animatingChoice = false
    @State private var selectedSide: BattleSide?
    
    private enum BattleSide {
        case left, right
    }
    
    init(items: [RankableItem], context: String, contextDisplayName: String, eloManager: ELOManager, modelContext: ModelContext) {
        self.items = items
        self.context = context
        self.contextDisplayName = contextDisplayName
        self.eloManager = eloManager
        self._battleEngine = StateObject(wrappedValue: BattleEngine(eloManager: eloManager, modelContext: modelContext))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Header
                progressHeader
                
                if let battle = battleEngine.currentBattle {
                    // Battle Interface
                    battleInterface(battle: battle)
                } else if battleEngine.isComplete {
                    // Completion View
                    completionView
                } else {
                    // Loading View
                    ProgressView("Setting up battles...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Battle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if battleEngine.isComplete {
                        Button("Results") {
                            showingResults = true
                        }
                    }
                }
            }
            .onAppear {
                battleEngine.setupBattle(items: items, context: context)
            }
        }
        .sheet(isPresented: $showingResults) {
            RankingResultsView(context: context, contextDisplayName: contextDisplayName)
        }
    }
    
    private var progressHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Text(contextDisplayName)
                    .font(.headline)
                
                Spacer()
                
                Text("\(battleEngine.completedBattles) / \(battleEngine.currentSession?.totalBattles ?? 0)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: battleEngine.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(radius: 1)
    }
    
    private func battleInterface(battle: BattlePair) -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Battle Cards
            HStack(spacing: 20) {
                // Left Item
                BattleCard(
                    item: battle.item1,
                    expectedScore: calculateExpectedScore(for: battle.item1, against: battle.item2),
                    isSelected: selectedSide == .left,
                    isAnimating: animatingChoice && selectedSide == .left,
                    action: {
                        selectWinner(battle.item1)
                    },
                    eloManager: eloManager,
                    context: context
                )
                
                // VS Separator
                VStack {
                    Text("VS")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    let ratingDiff = calculateRatingDifference(battle.item1, battle.item2)
                    if ratingDiff > 200 {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }
                .frame(width: 60)
                
                // Right Item
                BattleCard(
                    item: battle.item2,
                    expectedScore: calculateExpectedScore(for: battle.item2, against: battle.item1),
                    isSelected: selectedSide == .right,
                    isAnimating: animatingChoice && selectedSide == .right,
                    action: {
                        selectWinner(battle.item2)
                    },
                    eloManager: eloManager,
                    context: context
                )
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Action Buttons
            actionButtons(battle: battle)
                .padding(.horizontal)
                .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private func actionButtons(battle: BattlePair) -> some View {
        VStack(spacing: 12) {
            Button(action: { likeBoth() }) {
                HStack {
                    Image(systemName: "heart")
                    Text("Like Both")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.pink)
                .foregroundColor(.white)
                .rounded()
            }
            
            Button(action: { skip() }) {
                HStack {
                    Image(systemName: "forward")
                    Text("Skip This Battle")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .rounded()
            }
        }
    }
    
    private var completionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "trophy")
                .font(.system(size: 60))
                .foregroundColor(.gold)
            
            Text("Battle Complete!")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("You completed \(battleEngine.completedBattles) battles")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("View Results") {
                showingResults = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Actions
    
    private func selectWinner(_ winner: RankableItem) {
        selectedSide = winner.rankingID == battleEngine.currentBattle?.item1.rankingID ? .left : .right
        
        withAnimation(.easeInOut(duration: 0.3)) {
            animatingChoice = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            battleEngine.processBattleResult(.selectWinner(winner))
            resetAnimation()
        }
    }
    
    private func likeBoth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            animatingChoice = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            battleEngine.processBattleResult(.likeBoth)
            resetAnimation()
        }
    }
    
    private func skip() {
        battleEngine.processBattleResult(.skip)
    }
    
    private func resetAnimation() {
        animatingChoice = false
        selectedSide = nil
    }
    
    private func calculateExpectedScore(for item: RankableItem, against opponent: RankableItem) -> Double {
        let itemRating = eloManager.getRating(for: item, context: context).rating
        let opponentRating = eloManager.getRating(for: opponent, context: context).rating
        return 1.0 / (1.0 + pow(10.0, (opponentRating - itemRating) / 400.0))
    }
    
    private func calculateRatingDifference(_ item1: RankableItem, _ item2: RankableItem) -> Double {
        let rating1 = eloManager.getRating(for: item1, context: context).rating
        let rating2 = eloManager.getRating(for: item2, context: context).rating
        return abs(rating1 - rating2)
    }
}

struct BattleCard: View {
    let item: RankableItem
    let expectedScore: Double
    let isSelected: Bool
    let isAnimating: Bool
    let action: () -> Void
    let eloManager: ELOManager
    let context: String
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Artwork
                AlbumArtworkView(item: item.artworkItem, size: 120)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                
                // Item Info
                VStack(spacing: 4) {
                    Text(item.displayTitle)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text(item.displayArtist)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                    
                    if let albumItem = item as? MPMediaItem {
                        Text(albumItem.albumName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                    }
                    
                    if let collectionItem = item as? MPMediaItemCollection,
                       let year = collectionItem.year {
                        Text(year)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Expected Score
                Text("Win Chance: \(Int(expectedScore * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .rounded()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue.opacity(0.2) : Color(.systemBackground))
            .rounded()
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAnimating)
    }
}

extension View {
    func rounded() -> some View {
        clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

extension Color {
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
}

#Preview {
    let container = try! ModelContainer(for: ELORating.self, RankingSession.self)
    let eloManager = ELOManager(modelContext: container.mainContext)
    
    return HeadToHeadView(
        items: [],
        context: "preview",
        contextDisplayName: "Preview Battle",
        eloManager: eloManager,
        modelContext: container.mainContext
    )
}