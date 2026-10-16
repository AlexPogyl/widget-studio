import AppKit
import Foundation
import ImageIO

/// Storage for the photos of the photo widget.
///
/// The widget extension runs inside the App Sandbox and cannot read pictures from
/// the user's folders, so the app copies the chosen images into the extension's
/// own container — a place the app (unsandboxed) can write to and the sandboxed
/// extension can read from. No App Group or developer certificate is needed.
enum PhotoStore {

    static let bundleID = "com.alexpogyl.widgetstudio.widgets"
    static let folderName = "photos"

    /// True when running inside the widget extension's sandbox.
    static var isSandboxed: Bool {
        if ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil { return true }
        return FileManager.default.homeDirectoryForCurrentUser.path.contains("/Library/Containers/")
    }

    /// Folder shared by the app and the widget extension.
    static var directory: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let root: URL
        if isSandboxed {
            // Inside the sandbox the home directory *is* the container.
            root = home
        } else {
            root = home.appendingPathComponent("Library/Containers/\(bundleID)/Data", isDirectory: true)
        }
        return root.appendingPathComponent("Library/Application Support/WidgetStudio/\(folderName)",
                                           isDirectory: true)
    }

    static func url(for name: String) -> URL {
        directory.appendingPathComponent(name, isDirectory: false)
    }

    /// Copies an image chosen by the user into the shared folder.
    /// Returns the stored file name.
    static func importImage(from source: URL) -> String? {
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            let ext = source.pathExtension.isEmpty ? "png" : source.pathExtension
            let name = "\(UUID().uuidString).\(ext.lowercased())"
            let destination = directory.appendingPathComponent(name)
            try fileManager.copyItem(at: source, to: destination)
            return name
        } catch {
            NSLog("[WidgetStudio] Failed to import \(source.path): \(error)")
            return nil
        }
    }

    static func remove(_ name: String) {
        try? FileManager.default.removeItem(at: url(for: name))
    }

    /// Small preview used by the inspector.
    static func thumbnail(named name: String, maxPixel: Int = 240) -> NSImage? {
        guard let cg = thumbnailImage(named: name, maxPixel: maxPixel) else { return nil }
        return NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
    }

    /// Decodes a downscaled image — the widget never needs the full resolution.
    static func thumbnailImage(named name: String, maxPixel: Int) -> CGImage? {
        let fileURL = url(for: name)
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}
