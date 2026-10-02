import SwiftUI

/// Contents of the width panel. Shows the presets for whichever tool is active,
/// with the current width highlighted.
struct WidthPickerPanelContent: View {
    let tool: DrawingTool
    let selectedWidth: Double
    let inkColor: Color
    let onSelect: (Double) -> Void

    private var presets: [Double] {
        switch tool {
        case .pencil: return StrokeWidths.pencilPresets
        case .eraser: return StrokeWidths.eraserPresets
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(presets, id: \.self) { width in
                widthButton(width)
            }
        }
    }

    private func widthButton(_ width: Double) -> some View {
        let isSelected = width == selectedWidth
        return Button {
            onSelect(width)
        } label: {
            VStack(spacing: 6) {
                sample(width)
                    .frame(width: 64, height: 64)
                Text("\(Int(width)) pt")
                    .font(.caption.weight(isSelected ? .bold : .regular))
            }
            .padding(6)
            .background(
                isSelected ? Color.accentColor.opacity(0.15) : Color(.systemGray6),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 3)
            )
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(Int(width)) points")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private func sample(_ width: Double) -> some View {
        switch tool {
        case .pencil:
            Capsule()
                .fill(inkColor)
                .overlay(Capsule().strokeBorder(Color(.separator), lineWidth: 0.5))
                .frame(width: 48, height: width)
        case .eraser:
            // Eraser footprint; capped so the largest preset still fits in its container.
            let diameter = min(width, 60)
            Circle()
                .strokeBorder(Color.secondary, style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                .frame(width: diameter, height: diameter)
        }
    }
}
