//
//  LofiBarApp.swift
//  LofiBar
//
//  Created by Nathan Caron on 23/05/2025.
//

import Cocoa
import SwiftUI

@main
struct LofiBarApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  var body: some Scene {
    Settings {
      EmptyView()
    }
  }
}

class AppDelegate: NSObject, NSApplicationDelegate {
  static private(set) var instance: AppDelegate!

  // The NSStatusBar manages a collection of status items displayed within a system-wide menu bar.
  lazy var statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

  // Create an instance of our custom main menu we are building
  let menu = MainMenu()

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    AppDelegate.instance = self

    // Here we are using a custom icon found in Assets.xcassets
    statusBarItem.button?.image = NSImage(named: NSImage.Name("LofiBar"))
    statusBarItem.button?.imagePosition = .imageLeading

    // Assign our custom menu to the status bar
    statusBarItem.menu = menu.build()
  }
}
