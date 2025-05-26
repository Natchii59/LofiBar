//
//  MainMenu.swift
//  LofiBar
//
//  Created by Nathan Caron on 23/05/2025.
//

import SwiftUI

// This is our custom menu that will appear when users
// click on the menu bar icon
class MainMenu: NSObject {
  // A new menu instance ready to add items to
  let menu = NSMenu()

  // function called by LofiBarApp to create the menu
  func build() -> NSMenu {
    // Initialse the custom now playing view
    let content = ContentView()

    // We need this to allow use to stick a SwiftUI view into a
    // a location an NSView would normally be placed
    let contentView = NSHostingController(rootView: content)

    // Setting a size for our now playing view
    contentView.view.layoutSubtreeIfNeeded()
    let fittingSize = contentView.view.fittingSize
    
    contentView.view.frame.size = CGSize(width: 300, height: fittingSize.height)

    // This is where we actually add our now playing view to the menu
    let customMenuItem = NSMenuItem()
    customMenuItem.view = contentView.view
    menu.addItem(customMenuItem)

    // Adding a seperator
    menu.addItem(NSMenuItem.separator())

    // We add an About pane.
    let aboutMenuItem = NSMenuItem(
      title: "About LofiBar",
      action: #selector(about),
      keyEquivalent: ""
    )
    // This is important so that our #selector
    // targets the `about` func in this file
    aboutMenuItem.target = self

    // This is where we actually add our about item to the menu
    menu.addItem(aboutMenuItem)

    // Adding a seperator
    menu.addItem(NSMenuItem.separator())

    // Adding a quit menu item
    let quitMenuItem = NSMenuItem(
      title: "Quit LofiBar",
      action: #selector(quit),
      keyEquivalent: "q"
    )
    quitMenuItem.target = self
    menu.addItem(quitMenuItem)

    return menu
  }

  // The selector that opens a standard about pane.
  // You can see we also customise what appears in our
  // about pane by creating a Credits.html file in the root
  // of the project
  @objc func about(sender: NSMenuItem) {
    NSApp.activate()
    NSApp.orderFrontStandardAboutPanel()
  }

  // The selector that quits the app
  @objc func quit(sender: NSMenuItem) {
    NSApp.terminate(self)
  }
}
