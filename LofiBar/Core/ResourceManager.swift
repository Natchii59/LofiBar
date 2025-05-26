//
//  ResourceManager.swift
//  LofiBar
//
//  Created by Nathan Caron on 26/05/2025.
//

import Foundation

/// Singleton class responsible for managing and accessing resources located in Resources.bundle.
final class ResourceManager {
  /// Shared singleton instance of ResourceManager.
  static let shared = ResourceManager()

  /// Reference to the Resources.bundle.
  private let bundle: Bundle

  /// Private initializer to ensure only one instance is created.
  /// Locates the Resources.bundle in the main app bundle and initializes the `bundle` property.
  /// If the bundle cannot be found, the app will crash with a clear error message.
  private init() {
    guard
      let bundleURL = Bundle.main.url(
        forResource: "Resources",
        withExtension: "bundle"
      ),
      let bundle = Bundle(url: bundleURL)
    else {
      fatalError("❌ Resources.bundle not found")
    }
    self.bundle = bundle
  }

  /// Returns all file URLs contained within the Resources.bundle.
  /// - Returns: An array of URLs for every file found recursively in the bundle.
  func allResourceURLs() -> [URL] {
    guard let rootURL = bundle.resourceURL else { return [] }
    return fetchAllFiles(at: rootURL)
  }

  /// Returns the URL for a resource given its name, extension, and optional subdirectory inside the bundle.
  /// - Parameters:
  ///   - resource: The name of the resource file (without extension).
  ///   - ext: The file extension of the resource (e.g., "png"). Pass nil if none.
  ///   - subdirectory: The subdirectory within the bundle where the resource is located, or nil.
  /// - Returns: The URL for the resource if it exists, otherwise nil.
  func url(
    forResource resource: String?,
    withExtension ext: String?,
    subdirectory: String?
  ) -> URL? {
    return bundle.url(
      forResource: resource,
      withExtension: ext,
      subdirectory: subdirectory
    )
  }

  /// Returns all relative paths of files within the Resources.bundle.
  /// Useful for displaying or exploring the contents of the bundle.
  /// - Returns: An array of relative file paths as Strings.
  func allRelativePaths() -> [String] {
    let baseURL = bundle.resourceURL!
    return fetchAllFiles(at: baseURL)
      .map { $0.path.replacingOccurrences(of: baseURL.path + "/", with: "") }
  }

  /// Recursively fetches all file URLs starting from a given directory URL.
  /// - Parameter url: The root directory to start searching from.
  /// - Returns: An array of file URLs (excluding directories).
  private func fetchAllFiles(at url: URL) -> [URL] {
    var urls: [URL] = []
    if let enumerator = FileManager.default.enumerator(
      at: url,
      includingPropertiesForKeys: nil
    ) {
      for case let fileURL as URL in enumerator {
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(
          atPath: fileURL.path,
          isDirectory: &isDirectory
        ),
          !isDirectory.boolValue
        {
          urls.append(fileURL)
        }
      }
    }
    return urls
  }
}
