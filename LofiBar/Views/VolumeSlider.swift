//
//  VolumeSlider.swift
//  LofiBar
//
//  Created by Nathan Caron on 25/05/2025.
//

import SwiftUI

struct VolumeSlider: View {
  let label: String
  var icon: String? = nil
  @Binding var value: Float

  var body: some View {
    HStack {
      if let icon = icon {
        Image(systemName: icon)
          .frame(width: 20)
      }
      Text(label)
        .frame(minWidth: 50, alignment: .leading)
      Slider(value: $value, in: 0...1)
    }
  }
}
