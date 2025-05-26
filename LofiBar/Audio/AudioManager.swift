//
//  AudioManager.swift
//  LofiBar
//
//  Created by Nathan Caron on 23/05/2025.
//

import AVFoundation
import Cocoa

/// Manages background music and ambient sounds for a menu bar macOS application.
final class AudioManager: NSObject, ObservableObject {
  static let shared = AudioManager()

  /// The audio player for the current music track.
  private var musicPlayer: AVAudioPlayer?
  /// The index of the current music track in the playlist.
  private var currentMusicIndex: Int = 0
  /// Dictionary mapping each ambient sound to its associated audio player.
  private var ambientPlayers: [AmbientSound: AVAudioPlayer] = [:]

  // MARK: - Published Properties

  @Published var selectedMusicCategory: MusicCategory = .chill {
    didSet { playMusic(for: selectedMusicCategory) }
  }
  @Published var isPlaying: Bool = false {
    didSet { updateAllPlaybackState() }
  }
  @Published var masterVolume: Float = 1.0 {
    didSet { updateAllVolumes() }
  }
  @Published var musicVolume: Float = 0.5 {
    didSet { updateMusicVolumes() }
  }
  @Published var ambientVolumes: [AmbientSound: Float] = [:] {
    didSet { updateAmbientVolumes() }
  }

  // MARK: - Computed Properties

  private var canPlayMusic: Bool {
    isPlaying && masterVolume > 0 && musicVolume > 0
  }

  // MARK: - Initialization

  private override init() {
    super.init()
    observeSystemSleep()
    setupAmbientPlayers()
    playMusic(for: selectedMusicCategory)
    updateAllPlaybackState()
  }

  deinit {
    NSWorkspace.shared.notificationCenter.removeObserver(self)
  }

  // MARK: - System Sleep

  /// Observes system sleep and wake notifications to manage audio resources.
  private func observeSystemSleep() {
    let center = NSWorkspace.shared.notificationCenter
    center.addObserver(
      self,
      selector: #selector(handleSleepNote(_:)),
      name: NSWorkspace.willSleepNotification,
      object: nil
    )
    center.addObserver(
      self,
      selector: #selector(handleWakeNote(_:)),
      name: NSWorkspace.didWakeNotification,
      object: nil
    )
  }

  /// Stops and releases all audio players before sleep.
  @objc private func handleSleepNote(_ note: Notification) {
    stopAllAndRelease()
    isPlaying = false
  }

  /// Re-initializes audio players after wake.
  @objc private func handleWakeNote(_ note: Notification) {
    setupAmbientPlayers()
    playMusic(for: selectedMusicCategory)
    updateAllPlaybackState()
  }

  /// Stops and releases all music and ambient players.
  private func stopAllAndRelease() {
    musicPlayer?.stop()
    musicPlayer = nil
    ambientPlayers.values.forEach { $0.stop() }
    ambientPlayers.removeAll()
  }

  // MARK: - Setup

  /// Preloads all ambient sound players at startup for instant playback.
  private func setupAmbientPlayers() {
    for sound in AmbientSound.allCases {
      guard
        let url = Bundle.main.url(
          forResource: sound.rawValue,
          withExtension: "mp3",
          subdirectory: AmbientSound.resourceSubdirectory
        )
      else { continue }
      do {
        let player = try AVAudioPlayer(contentsOf: url)
        player.numberOfLoops = -1
        player.volume = 0
        player.prepareToPlay()
        ambientPlayers[sound] = player
        ambientVolumes[sound] = 0
      } catch {
        print("Failed to load ambient sound: \(sound)", error)
      }
    }
  }

  // MARK: - Music Playback

  /// Loads and plays the first track of the specified music category.
  private func playMusic(for category: MusicCategory) {
    currentMusicIndex = 0
    playCurrentMusicTrack()
  }

  /// Plays the current music track based on the currentMusicIndex.
  private func playCurrentMusicTrack() {
    stopMusic()

    let fileNames = selectedMusicCategory.fileNames
    guard !fileNames.isEmpty, currentMusicIndex < fileNames.count else {
      return
    }
    let fileName = fileNames[currentMusicIndex]
    guard
      let url = Bundle.main.url(
        forResource: fileName,
        withExtension: "mp3",
        subdirectory: MusicCategory.resourceSubdirectory
      )
    else {
      print("Failed to find music: \(fileName)")
      return
    }
    do {
      let player = try AVAudioPlayer(contentsOf: url)
      player.delegate = self
      player.volume = musicVolume * masterVolume
      player.prepareToPlay()
      musicPlayer = player
      if canPlayMusic {
        player.play()
      }
    } catch {
      print("Failed to load music: \(fileName)", error)
    }
  }

  /// Stops playback of the current music track.
  private func stopMusic() {
    musicPlayer?.stop()
    musicPlayer = nil
  }

  // MARK: - Ambient Sound Management

  /// Updates the volume and play/pause state of all ambient players according to their current volume and global state.
  private func updateAmbientVolumes() {
    for (sound, player) in ambientPlayers {
      let volume = (ambientVolumes[sound] ?? 0) * masterVolume
      player.volume = volume
      if volume > 0 && isPlaying && !player.isPlaying {
        player.play()
      } else if (volume == 0 || !isPlaying || masterVolume == 0)
        && player.isPlaying
      {
        player.pause()
      }
    }
  }

  // MARK: - Volume & Playback State Updates

  /// Updates the volume for all audio outputs (music and ambient sounds) based on current property values.
  private func updateAllVolumes() {
    updateMusicVolumes()
    updateAmbientVolumes()
    updateAllPlaybackState()
  }

  /// Updates the volume for the music player and ensures playback is consistent.
  private func updateMusicVolumes() {
    let effectiveMusicVolume = musicVolume * masterVolume
    musicPlayer?.volume = effectiveMusicVolume
    updateMusicPlaybackState()
  }

  /// Pauses or resumes all music and ambient players based on master volume, music volume, and isPlaying state.
  private func updateAllPlaybackState() {
    if masterVolume == 0 || !isPlaying {
      pauseAll()
    } else {
      updateMusicPlaybackState()
      updateAmbientVolumes()
    }
  }

  /// Pauses or resumes music playback according to music volume, master volume, and isPlaying state.
  private func updateMusicPlaybackState() {
    guard let player = musicPlayer else { return }
    if canPlayMusic {
      // If we're at the end of the track, advance to the next (fixes play/pause bug)
      if player.currentTime >= player.duration {
        audioPlayerDidFinishPlaying(player, successfully: true)
      } else if !player.isPlaying {
        player.play()
      }
    } else {
      if player.isPlaying {
        player.pause()
      }
    }
  }

  // MARK: - Playback Controls

  /// Pauses playback of all music and ambient sounds.
  private func pauseAll() {
    musicPlayer?.pause()
    ambientPlayers.values.forEach { $0.pause() }
  }

  /// Resumes playback of all music and ambient sounds (if their volume is greater than 0).
  private func resumeAll() {
    updateAllPlaybackState()
  }
}

// MARK: - AVAudioPlayerDelegate

extension AudioManager: AVAudioPlayerDelegate {
  /// Called when the current music track finishes playing. Advances to the next track, looping if needed.
  func audioPlayerDidFinishPlaying(
    _ player: AVAudioPlayer,
    successfully flag: Bool
  ) {
    let fileNames = selectedMusicCategory.fileNames
    guard !fileNames.isEmpty else { return }
    currentMusicIndex += 1
    if currentMusicIndex >= fileNames.count {
      currentMusicIndex = 0  // Loop back to the first track
    }
    playCurrentMusicTrack()
  }
}
