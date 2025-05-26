//
//  CategorySelectorView.swift
//  LofiBar
//
//  Created by Nathan Caron on 25/05/2025.
//

import SwiftUI

struct CategorySelectorView: View {
  @ObservedObject private var audioManager = AudioManager.shared

  var body: some View {
    VStack(alignment: .leading) {
      Text("Music Category")
        .font(.subheadline)
      Picker("", selection: $audioManager.selectedMusicCategory) {
        ForEach(MusicCategory.allCases) { category in
          Text(category.displayName).tag(category)
        }
      }
      .pickerStyle(RadioGroupPickerStyle())
    }
  }
}
