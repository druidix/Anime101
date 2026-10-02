import SwiftUI

/// A panel that slides down from the top of the canvas, can be dragged by its title bar,
/// and closes only through its X button. Taps and strokes elsewhere never dismiss it.
struct FloatingPanel<Content: View>: View {
    /// Resting position (top center, slightly below the top edge) used every time a panel opens.
    static var restingOffset: CGSize { CGSize(width: 0, height: 8) }

    let title: String
    /// Size of the canvas area the panel must stay inside.
    let containerSize: CGSize
    /// Offset from the top-center of the container.
    @Binding var offset: CGSize
    let onClose: () -> Void
    /// Called when the user touches the panel, so the parent can bring it to the front.
    let onInteract: () -> Void
    @ViewBuilder let content: Content

    @State private var panelSize: CGSize = .zero
    @State private var dragStartOffset: CGSize?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleBar
            Divider()
            content
                .padding(12)
        }
        .fixedSize()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color(.separator)))
        .shadow(color: .black.opacity(0.2), radius: 10, y: 3)
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newSize in
            panelSize = newSize
        }
        .offset(clamped(offset))
        .simultaneousGesture(TapGesture().onEnded { onInteract() })
    }

    private var titleBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Spacer(minLength: 16)
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close \(title)")
        }
        .padding(.leading, 12)
        .padding(.trailing, 4)
        .frame(height: 48)
        .contentShape(Rectangle())
        .gesture(dragGesture)
    }

    /// Dragging works only on the title bar so sliders and pads inside the panel never move it.
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .global)
            .onChanged { value in
                if dragStartOffset == nil {
                    dragStartOffset = clamped(offset)
                    onInteract()
                }
                let start = dragStartOffset ?? offset
                offset = clamped(CGSize(
                    width: start.width + value.translation.width,
                    height: start.height + value.translation.height
                ))
            }
            .onEnded { _ in
                dragStartOffset = nil
            }
    }

    /// Keeps the whole panel inside the canvas area.
    private func clamped(_ proposed: CGSize) -> CGSize {
        FloatingPanelLayout.clamp(proposed, panelSize: panelSize, containerSize: containerSize)
    }
}

enum FloatingPanelLayout {
    /// Clamps an offset measured from the container's top center so the panel stays fully inside.
    static func clamp(_ proposed: CGSize, panelSize: CGSize, containerSize: CGSize) -> CGSize {
        let maxX = max(0, (containerSize.width - panelSize.width) / 2)
        let maxY = max(0, containerSize.height - panelSize.height)
        return CGSize(
            width: min(maxX, max(-maxX, proposed.width)),
            height: min(maxY, max(0, proposed.height))
        )
    }
}
