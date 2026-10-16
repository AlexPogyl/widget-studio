import AppKit
import SwiftUI

/// Codable RGBA colour used by every widget setting.
///
/// Stored as plain numbers so that the configuration file stays human readable.
struct RGBA: Codable, Equatable, Hashable {
    var r: Double
    var g: Double
    var b: Double
    var a: Double

    init(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    init(color: Color) {
        let ns = NSColor(color).usingColorSpace(.sRGB) ?? .black
        self.init(Double(ns.redComponent),
                  Double(ns.greenComponent),
                  Double(ns.blueComponent),
                  Double(ns.alphaComponent))
    }

    init(hex: String, alpha: Double = 1) {
        var value = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted).uppercased()
        if value.count == 3 { value = value.map { "\($0)\($0)" }.joined() }
        var int: UInt64 = 0
        Scanner(string: value).scanHexInt64(&int)
        self.init(Double((int >> 16) & 0xFF) / 255.0,
                  Double((int >> 8) & 0xFF) / 255.0,
                  Double(int & 0xFF) / 255.0,
                  alpha)
    }

    var color: Color { Color(.sRGB, red: r, green: g, blue: b, opacity: a) }
    var nsColor: NSColor { NSColor(srgbRed: r, green: g, blue: b, alpha: a) }

    func withAlpha(_ alpha: Double) -> RGBA { RGBA(r, g, b, alpha) }

    var hexString: String {
        String(format: "#%02X%02X%02X",
               Int((r.clamped01 * 255).rounded()),
               Int((g.clamped01 * 255).rounded()),
               Int((b.clamped01 * 255).rounded()))
    }

    static let white = RGBA(1, 1, 1)
    static let black = RGBA(0, 0, 0)
    static let clear = RGBA(0, 0, 0, 0)
}

/// A single value of a widget setting.
///
/// Encoded to plain JSON scalars (`true`, `64`, `"rounded"`, `{"r":…}`) so the
/// config file can be edited by hand.
enum SettingValue: Equatable {
    case bool(Bool)
    case integer(Int)
    case number(Double)
    case text(String)
    case color(RGBA)
}

extension SettingValue: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .integer(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .text(value)
        } else if let value = try? container.decode(RGBA.self) {
            self = .color(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Unsupported setting value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let value): try container.encode(value)
        case .integer(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .text(let value): try container.encode(value)
        case .color(let value): try container.encode(value)
        }
    }
}

extension SettingValue {
    var boolValue: Bool { if case .bool(let v) = self { return v }; return false }
    var doubleValue: Double {
        switch self {
        case .number(let v): return v
        case .integer(let v): return Double(v)
        case .bool(let v): return v ? 1 : 0
        default: return 0
        }
    }
    var intValue: Int { Int(doubleValue.rounded()) }
    var stringValue: String { if case .text(let v) = self { return v }; return "" }
    var colorValue: RGBA { if case .color(let v) = self { return v }; return .white }
}

extension Double {
    var clamped01: Double { min(max(self, 0), 1) }
}
