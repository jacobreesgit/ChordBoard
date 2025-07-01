//
//  AuthorizationView.swift
//  ChordBoard
//
//  Created by Jacob Rees on 01/07/2025.
//

import SwiftUI
import MediaPlayer

struct AuthorizationView: View {
    @EnvironmentObject var musicLibrary: MusicLibraryManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.house")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Music Library Access")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("ChordBoard needs access to your music library to display your albums and artists.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            if musicLibrary.authorizationStatus == .denied {
                VStack(spacing: 16) {
                    Text("Music library access was denied. Please enable it in Settings to use this feature.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    Button("Open Settings") {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Button("Allow Access") {
                    musicLibrary.requestAuthorization()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

#Preview {
    AuthorizationView()
        .environmentObject(MusicLibraryManager())
}