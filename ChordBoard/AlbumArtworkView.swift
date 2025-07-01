//
//  AlbumArtworkView.swift
//  ChordBoard
//
//  Created by Jacob Rees on 01/07/2025.
//

import SwiftUI
import MediaPlayer

struct AlbumArtworkView: View {
    let item: MPMediaItem?
    let size: CGFloat
    
    var body: some View {
        Group {
            if let artwork = item?.artwork,
               let image = artwork.image(at: CGSize(width: size, height: size)) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: size * 0.4))
                    .foregroundColor(.secondary)
                    .background(Color.gray.opacity(0.2))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

#Preview {
    VStack {
        AlbumArtworkView(item: nil, size: 100)
        AlbumArtworkView(item: nil, size: 50)
        AlbumArtworkView(item: nil, size: 40)
    }
}