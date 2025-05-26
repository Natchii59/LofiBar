//
//  MusicCategory.swift
//  LofiBar
//
//  Created by Nathan Caron on 25/05/2025.
//

import Foundation

enum MusicCategory: String, CaseIterable, Identifiable {
  case chill
  case focus
  case sleep

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .chill: return "Chill"
    case .focus: return "Focus"
    case .sleep: return "Sleep"
    }
  }

  var fileNames: [String] {
    switch self {
    case .chill:
      return ["one", "two", "three"]
    case .focus:
      return []
    case .sleep:
      return []
    }
  }
  
  static let resourceSubdirectory = "Resources/Sounds/Music"
}
