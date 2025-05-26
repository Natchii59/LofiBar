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
      VolumeSlider(
        label: "Master",
        value: Binding(
          get: { audioManager.masterVolume },
          set: { newValue in
            if audioManager.masterVolume != newValue {
              audioManager.masterVolume = newValue
            }
          }
        )
      )
      VolumeSlider(
        label: "Music",
        value: Binding(
          get: { audioManager.musicVolume },
          set: { newValue in
            if audioManager.musicVolume != newValue {
              audioManager.musicVolume = newValue
            }
          }
        )
      )
      ForEach(AmbientSound.allCases) { sound in
        VolumeSlider(
          label: sound.displayName,
          icon: sound.iconName,
          value: Binding(
            get: { audioManager.ambientVolumes[sound] ?? 0 },
            set: { newValue in
              let oldValue = audioManager.ambientVolumes[sound] ?? 0
              if oldValue != newValue {
                audioManager.ambientVolumes[sound] = newValue
              }
            }
          )
        )
      }
    }
  }
}
