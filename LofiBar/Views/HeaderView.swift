//
//  HeaderView.swift
//  LofiBar
//
//  Created by Nathan Caron on 25/05/2025.
//

import SwiftUI

struct HeaderView: View {
  @ObservedObject private var audioManager = AudioManager.shared

  var body: some View {
    HStack {
      Text("LofiBar")
        .font(.headline)

      Spacer()

      Button(action: {
        audioManager.isPlaying.toggle()
      }) {
        Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
      }
      .buttonStyle(.borderless)
    }
  }
}
