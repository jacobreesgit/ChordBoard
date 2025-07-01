//
//  RanksView.swift
//  ChordBoard
//
//  Created by Jacob Rees on 01/07/2025.
//

import SwiftUI

struct RanksView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Ranks")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Coming Soon")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .navigationTitle("Ranks")
    }
}

#Preview {
    NavigationStack {
        RanksView()
    }
}