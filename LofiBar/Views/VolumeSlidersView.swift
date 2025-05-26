//
//  VolumeSlidersView.swift
//  LofiBar
//
//  Created by Nathan Caron on 25/05/2025.
//

import SwiftUI

struct VolumeSlidersView: View {
  @ObservedObject private var audioManager = AudioManager.shared

  var body: some View {
    VStack(spacing: 10) {
      VolumeSlider(label: "Master", value: $audioManager.masterVolume)
      VolumeSlider(label: "Music", value: $audioManager.musicVolume)
      ForEach(AmbientSound.allCases) { sound in
        VolumeSlider(
          label: sound.displayName,
          icon: sound.iconName,
          value: Binding(
            get: { audioManager.ambientVolumes[sound] ?? 0 },
            set: { audioManager.ambientVolumes[sound] = $0 }
          )
        )
      }
    }
  }
}
