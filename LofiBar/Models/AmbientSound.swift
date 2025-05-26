//
//  AmbientSound.swift
//  LofiBar
//
//  Created by Nathan Caron on 25/05/2025.
//

import Foundation

enum AmbientSound: String, CaseIterable, Identifiable {
  case rain
  case wind
  case alpha

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .rain: return "Rain"
    case .wind: return "Wind"
    case .alpha: return "Alpha"
    }
  }

  var iconName: String {
    switch self {
    case .rain: return "cloud.rain.fill"
    case .wind: return "wind"
    case .alpha: return "textformat.characters"
    }
  }

  static let resourceSubdirectory = "Resources/Sounds/Ambient"
}
