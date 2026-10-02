import Foundation

/// An sRGB color with components in 0...1. Stored in `metadata.json`, so it must stay
/// Codable and free of UIKit/SwiftUI types.
struct RGBAColor: Codable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = Self.clamp(red)
        self.green = Self.clamp(green)
        self.blue = Self.clamp(blue)
        self.alpha = Self.clamp(alpha)
    }

    static let black = RGBAColor(red: 0, green: 0, blue: 0)
    static let white = RGBAColor(red: 1, green: 1, blue: 1)

    /// Two colors are treated as the same if every channel rounds to the same 0-255 value.
    func isSameColor(as other: RGBAColor) -> Bool {
        rgb255 == other.rgb255 && Int((alpha * 255).rounded()) == Int((other.alpha * 255).rounded())
    }

    var rgb255: (red: Int, green: Int, blue: Int) {
        (Int((red * 255).rounded()), Int((green * 255).rounded()), Int((blue * 255).rounded()))
    }

    // MARK: - Hex

    /// "#RRGGBB"
    var hexString: String {
        let c = rgb255
        return String(format: "#%02X%02X%02X", c.red, c.green, c.blue)
    }

    /// Accepts "RRGGBB" or "#RRGGBB" (case-insensitive). Returns nil for anything else.
    init?(hex: String) {
        var text = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("#") { text.removeFirst() }
        guard text.count == 6, let value = UInt32(text, radix: 16) else { return nil }
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    // MARK: - HSB

    /// Hue, saturation and brightness in 0...1.
    init(hue: Double, saturation: Double, brightness: Double, alpha: Double = 1) {
        let h = (hue >= 1 ? 0 : max(0, hue)) * 6
        let s = Self.clamp(saturation)
        let v = Self.clamp(brightness)
        let sector = Int(h)
        let f = h - Double(sector)
        let p = v * (1 - s)
        let q = v * (1 - s * f)
        let t = v * (1 - s * (1 - f))
        let rgb: (Double, Double, Double)
        switch sector {
        case 0: rgb = (v, t, p)
        case 1: rgb = (q, v, p)
        case 2: rgb = (p, v, t)
        case 3: rgb = (p, q, v)
        case 4: rgb = (t, p, v)
        default: rgb = (v, p, q)
        }
        self.init(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: alpha)
    }

    var hsb: (hue: Double, saturation: Double, brightness: Double) {
        let maxC = max(red, green, blue)
        let minC = min(red, green, blue)
        let delta = maxC - minC
        let brightness = maxC
        let saturation = maxC == 0 ? 0 : delta / maxC
        guard delta > 0 else { return (0, saturation, brightness) }

        var hue: Double
        if maxC == red {
            hue = (green - blue) / delta
        } else if maxC == green {
            hue = (blue - red) / delta + 2
        } else {
            hue = (red - green) / delta + 4
        }
        hue /= 6
        if hue < 0 { hue += 1 }
        return (hue, saturation, brightness)
    }

    private static func clamp(_ value: Double) -> Double {
        min(1, max(0, value))
    }
}

/// The per-project "previously used colors" list. Index 0 is the most recent.
enum RecentColors {
    static let capacity = 10

    /// Returns the history after drawing a stroke with `color`.
    /// - New color: inserted at index 0, everything shifts one slot right, the oldest beyond
    ///   `capacity` is discarded.
    /// - Color already in the history: history is returned unchanged (no reordering).
    static func recording(_ color: RGBAColor, in history: [RGBAColor]) -> [RGBAColor] {
        guard !history.contains(where: { $0.isSameColor(as: color) }) else { return history }
        return Array(([color] + history).prefix(capacity))
    }
}

/// Preset widths shown in the width selector, in points.
enum StrokeWidths {
    static let pencilPresets: [Double] = [1, 2, 4, 8, 16]
    /// PencilKit's sized (fixed-width bitmap) eraser only accepts ~16.4...80.4 pt; values outside
    /// that range are clamped, so presets stay inside it.
    static let eraserPresets: [Double] = [20, 32, 48, 64]

    /// Default pencil width: 2 pt, the preset closest to the ~2.7 pt pen default the app used before
    /// widths were selectable. Final value to be confirmed during Soma tuning (Milestone 8).
    static let pencilDefault: Double = 2
    static let eraserDefault: Double = 20
}
