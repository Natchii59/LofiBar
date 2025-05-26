//
//  AudioManager.swift
//  LofiBar
//
//  Created by Nathan Caron on 23/05/2025.
//

import AVFoundation
import Cocoa

/// Manages background music and ambient sounds for a menu bar macOS application.
///
/// Use this singleton (`AudioManager.shared`) to control all audio behaviors, including music playback,
/// ambient sounds, system sleep/wake handling, and synchronized volume control.
///
/// Designed as an `ObservableObject` for SwiftUI integration.
final class AudioManager: NSObject, ObservableObject {
  /// The shared singleton instance of AudioManager.
  static let shared = AudioManager()

  // MARK: - Private Properties

  /// The audio player for the current music track.
  private var musicPlayer: AVAudioPlayer?
  /// The index of the current music track in the playlist.
  private var currentMusicIndex: Int = 0
  /// Dictionary mapping each ambient sound to its associated audio player.
  private var ambientPlayers: [AmbientSound: AVAudioPlayer] = [:]

  // MARK: - Published Properties

  /// The currently selected music category. Changes trigger new music playback.
  @Published var selectedMusicCategory: MusicCategory = .chill {
    didSet { playMusic(for: selectedMusicCategory) }
  }
  /// Indicates whether audio playback is active.
  @Published var isPlaying: Bool = false {
    didSet { updatePlaybackState() }
  }
  /// The master volume for all audio (range 0.0...1.0).
  @Published var masterVolume: Float = 1.0 {
    didSet { setMasterVolume(masterVolume) }
  }
  /// The volume for music tracks only (range 0.0...1.0).
  @Published var musicVolume: Float = 0.5 {
    didSet { setMusicVolume(musicVolume) }
  }
  /// The volume for each ambient sound, keyed by sound type (range 0.0...1.0).
  @Published var ambientVolumes: [AmbientSound: Float] = [:] {
    didSet {
      updateChangedAmbientVolumes(oldValue: oldValue, newValue: ambientVolumes)
    }
  }

  // MARK: - Computed Properties

  /// Returns true if music can be played according to playback state and volume settings.
  private var canPlayMusic: Bool {
    isPlaying && masterVolume > 0 && musicVolume > 0
  }

  // MARK: - Initialization

  /// Initializes the singleton instance, observes system sleep/wake, preloads audio, and starts playback.
  private override init() {
    super.init()
    observeSystemSleep()
    setupAmbientPlayers()
    playMusic(for: selectedMusicCategory)
    updatePlaybackState()
  }

  deinit {
    NSWorkspace.shared.notificationCenter.removeObserver(self)
  }

  // MARK: - System Sleep / Wake Management

  /// Observes system sleep and wake notifications to manage audio resources appropriately.
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

  /// Handles system sleep: stops and releases all audio resources.
  /// - Parameter note: The notification received before system sleep.
  @objc private func handleSleepNote(_ note: Notification) {
    stopAllAndRelease()
    isPlaying = false
  }

  /// Handles system wake: reloads audio players and resumes playback states.
  /// - Parameter note: The notification received after system wake.
  @objc private func handleWakeNote(_ note: Notification) {
    setupAmbientPlayers()
    playMusic(for: selectedMusicCategory)
    updatePlaybackState()
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
        let url = ResourceManager.shared.url(
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
        if ambientVolumes[sound] == nil {
          ambientVolumes[sound] = 0
        }
      } catch {
        print("Failed to load ambient sound: \(sound)", error)
      }
    }
  }

  // MARK: - Music Playback

  /// Loads and plays the first track of the given music category.
  /// - Parameter category: The music category to play.
  private func playMusic(for category: MusicCategory) {
    currentMusicIndex = 0
    playCurrentMusicTrack()
  }

  /// Plays the current music track based on `currentMusicIndex`.
  private func playCurrentMusicTrack() {
    stopMusic()

    let fileNames = selectedMusicCategory.fileNames
    guard !fileNames.isEmpty, currentMusicIndex < fileNames.count else {
      return
    }
    let fileName = fileNames[currentMusicIndex]
    guard
      let url = ResourceManager.shared.url(
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

  // MARK: - Selective Ambient Sound Management

  /// Updates only ambient players whose volume actually changed.
  /// - Parameters:
  ///   - oldValue: The previous ambient volumes.
  ///   - newValue: The current ambient volumes.
  private func updateChangedAmbientVolumes(
    oldValue: [AmbientSound: Float],
    newValue: [AmbientSound: Float]
  ) {
    for (sound, newVolume) in newValue {
      let oldVolume = oldValue[sound] ?? 0
      if newVolume != oldVolume {
        setAmbientVolume(for: sound, volume: newVolume)
      }
    }
  }

  /// Sets the volume and playback state for a specific ambient sound.
  /// - Parameters:
  ///   - sound: The ambient sound type.
  ///   - volume: The new volume for that sound (0.0...1.0).
  private func setAmbientVolume(for sound: AmbientSound, volume: Float) {
    guard let player = ambientPlayers[sound] else { return }
    let effectiveVolume = volume * masterVolume
    player.volume = effectiveVolume
    if effectiveVolume > 0 && isPlaying {
      if !player.isPlaying {
        player.play()
      }
    } else {
      if player.isPlaying {
        player.pause()
      }
    }
  }

  // MARK: - Volume & Playback State Updates

  /// Updates all volumes for master volume changes.
  /// - Parameter newMasterVolume: The new master volume (0.0...1.0).
  private func setMasterVolume(_ newMasterVolume: Float) {
    setMusicVolume(musicVolume)
    for sound in AmbientSound.allCases {
      setAmbientVolume(for: sound, volume: ambientVolumes[sound] ?? 0)
    }
  }

  /// Updates only the music volume (does not affect ambients).
  /// - Parameter newMusicVolume: The new music volume (0.0...1.0).
  private func setMusicVolume(_ newMusicVolume: Float) {
    let effectiveMusicVolume = newMusicVolume * masterVolume
    musicPlayer?.volume = effectiveMusicVolume
    updateMusicPlaybackState()
  }

  /// Updates playback state for all players when play/pause changes.
  private func updatePlaybackState() {
    if !isPlaying || masterVolume == 0 {
      pauseAll()
    } else {
      updateMusicPlaybackState()
      // Resume only ambient sounds whose volume > 0
      for sound in AmbientSound.allCases {
        setAmbientVolume(for: sound, volume: ambientVolumes[sound] ?? 0)
      }
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
    updatePlaybackState()
  }
}

// MARK: - AVAudioPlayerDelegate

extension AudioManager: AVAudioPlayerDelegate {
  /// Called when the current music track finishes playing. Advances to the next track and loops if needed.
  ///
  /// - Parameters:
  ///   - player: The audio player that finished playback.
  ///   - flag: Indicates whether playback finished successfully.
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
