//
//  SongsView.swift
//  ChordBoard
//
//  Created by Jacob Rees on 01/07/2025.
//

import SwiftUI

struct SongsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Songs")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Coming Soon")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .navigationTitle("Songs")
    }
}

#Preview {
    NavigationStack {
        SongsView()
    }
}