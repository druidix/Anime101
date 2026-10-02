import SwiftUI
import UIKit

extension RGBAColor {
    var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    var swiftUIColor: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    /// One-tap colors shown in the picker.
    static let quickPicks: [RGBAColor] = [
        "#000000", "#FFFFFF", "#808080", "#E53935", "#FB8C00", "#FDD835",
        "#43A047", "#00897B", "#1E88E5", "#8E24AA", "#EC407A", "#795548",
    ].compactMap { RGBAColor(hex: $0) }
}

/// Contents of the color picker panel: current color, hue/saturation/brightness controls,
/// RGB sliders, hex entry, quick picks and the 10 previously used colors.
struct ColorPickerPanelContent: View {
    @Binding var color: RGBAColor
    let recentColors: [RGBAColor]

    /// Kept separately because hue cannot be recovered from grays (saturation 0) or black.
    @State private var hue: Double = 0
    @State private var hexText = ""

    private let panelWidth: CGFloat = 300

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            currentColorRow
            SaturationBrightnessPad(hue: hue, color: $color)
                .frame(height: 150)
            HueSlider(hue: hueBinding)
                .frame(height: 28)
            rgbSliders
            section("Quick picks") {
                swatchGrid(columns: 6) {
                    ForEach(RGBAColor.quickPicks, id: \.self) { swatchButton($0) }
                }
            }
            section("Previously used") {
                swatchGrid(columns: 5) {
                    ForEach(0..<RecentColors.capacity, id: \.self) { index in
                        if index < recentColors.count {
                            swatchButton(recentColors[index])
                        } else {
                            emptySlot
                        }
                    }
                }
            }
        }
        .frame(width: panelWidth)
        .onAppear(perform: syncFromColor)
        .onChange(of: color) { _, _ in syncFromColor() }
    }

    // MARK: - Pieces

    private var currentColorRow: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(color.swiftUIColor)
                .frame(width: 80, height: 80)
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(.separator), lineWidth: 1))
                .accessibilityLabel("Current color \(color.hexString)")
            VStack(alignment: .leading, spacing: 6) {
                Text("Current color")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("#RRGGBB", text: $hexText)
                    .font(.body.monospaced())
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .frame(width: 120)
                    .onSubmit(applyHex)
            }
        }
    }

    private var rgbSliders: some View {
        VStack(spacing: 4) {
            channelSlider("R", \.red, tint: .red)
            channelSlider("G", \.green, tint: .green)
            channelSlider("B", \.blue, tint: .blue)
        }
    }

    private func channelSlider(_ label: String, _ channel: WritableKeyPath<RGBAColor, Double>, tint: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption.bold())
                .frame(width: 14)
            Slider(
                value: Binding(
                    get: { color[keyPath: channel] * 255 },
                    set: { newValue in
                        var updated = color
                        updated[keyPath: channel] = newValue / 255
                        color = updated
                    }
                ),
                in: 0...255,
                step: 1
            )
            .tint(tint)
            Text("\(Int((color[keyPath: channel] * 255).rounded()))")
                .font(.caption.monospacedDigit())
                .frame(width: 30, alignment: .trailing)
        }
    }

    private func section<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func swatchGrid<C: View>(columns: Int, @ViewBuilder content: () -> C) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(44), spacing: 8), count: columns), alignment: .leading, spacing: 8) {
            content()
        }
    }

    private func swatchButton(_ swatch: RGBAColor) -> some View {
        let isCurrent = swatch.isSameColor(as: color)
        return Button {
            color = swatch
        } label: {
            RoundedRectangle(cornerRadius: 8)
                .fill(swatch.swiftUIColor)
                .frame(width: 44, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isCurrent ? Color.accentColor : Color(.separator), lineWidth: isCurrent ? 3 : 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(swatch.hexString)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }

    private var emptySlot: some View {
        RoundedRectangle(cornerRadius: 8)
            .strokeBorder(Color(.separator), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            .frame(width: 44, height: 44)
            .accessibilityHidden(true)
    }

    // MARK: - Syncing

    private var hueBinding: Binding<Double> {
        Binding(
            get: { hue },
            set: { newHue in
                hue = newHue
                let current = color.hsb
                color = RGBAColor(hue: newHue, saturation: current.saturation, brightness: current.brightness, alpha: color.alpha)
            }
        )
    }

    private func syncFromColor() {
        hexText = color.hexString
        let current = color.hsb
        // Grays and black carry no hue; keep the slider where the user left it.
        if current.saturation > 0.001 && current.brightness > 0.001 {
            hue = current.hue
        }
    }

    private func applyHex() {
        if let parsed = RGBAColor(hex: hexText) {
            color = parsed
        } else {
            hexText = color.hexString
        }
    }
}

/// Square pad: horizontal axis is saturation, vertical axis is brightness, for the current hue.
struct SaturationBrightnessPad: View {
    let hue: Double
    @Binding var color: RGBAColor

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let current = color.hsb
            ZStack {
                Color(hue: hue, saturation: 1, brightness: 1)
                LinearGradient(colors: [.white, .white.opacity(0)], startPoint: .leading, endPoint: .trailing)
                LinearGradient(colors: [.black.opacity(0), .black], startPoint: .top, endPoint: .bottom)
                Circle()
                    .strokeBorder(.white, lineWidth: 2)
                    .background(Circle().stroke(.black.opacity(0.5), lineWidth: 1))
                    .frame(width: 22, height: 22)
                    .position(x: current.saturation * size.width, y: (1 - current.brightness) * size.height)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let saturation = min(1, max(0, value.location.x / size.width))
                        let brightness = 1 - min(1, max(0, value.location.y / size.height))
                        color = RGBAColor(hue: hue, saturation: saturation, brightness: brightness, alpha: color.alpha)
                    }
            )
        }
        .accessibilityLabel("Saturation and brightness")
    }
}

/// Horizontal rainbow bar for choosing hue.
struct HueSlider: View {
    @Binding var hue: Double

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            ZStack(alignment: .leading) {
                LinearGradient(
                    colors: stride(from: 0.0, through: 1.0, by: 1.0 / 6).map { Color(hue: $0, saturation: 1, brightness: 1) },
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .clipShape(Capsule())
                Circle()
                    .fill(Color(hue: hue, saturation: 1, brightness: 1))
                    .overlay(Circle().strokeBorder(.white, lineWidth: 3))
                    .shadow(radius: 1)
                    .frame(width: geometry.size.height, height: geometry.size.height)
                    .offset(x: hue * (width - geometry.size.height))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        hue = min(0.999, max(0, value.location.x / width))
                    }
            )
        }
        .accessibilityLabel("Hue")
    }
}
