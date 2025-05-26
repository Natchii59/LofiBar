//
//  ContentView.swift
//  LofiBar
//
//  Created by Nathan Caron on 23/05/2025.
//

import SwiftUI

struct ContentView: View {
  @StateObject private var audioManager = AudioManager.shared

  var body: some View {
    VStack(spacing: 12) {
      HeaderView()
      Divider()
      CategorySelectorView()
      Divider()
      VolumeSlidersView()
    }
    .padding(12)
  }
}
#Preview {
  ContentView()
}
