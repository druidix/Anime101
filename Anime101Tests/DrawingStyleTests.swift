import XCTest
import PencilKit
@testable import Anime101

final class DrawingStyleTests: XCTestCase {
    private func color(_ hex: String) -> RGBAColor { RGBAColor(hex: hex)! }

    // MARK: - RecentColors

    func testHistoryStartsEmptyForNewProject() {
        let project = Project(id: UUID(), name: "New", createdAt: Date(), modifiedAt: Date())
        XCTAssertTrue(project.recentColors.isEmpty)
        XCTAssertEqual(project.initialActiveColor, .black)
    }

    func testNewestColorGoesToIndexZeroAndOthersShiftRight() {
        var history: [RGBAColor] = []
        history = RecentColors.recording(color("#FF0000"), in: history)
        history = RecentColors.recording(color("#00FF00"), in: history)
        history = RecentColors.recording(color("#0000FF"), in: history)
        XCTAssertEqual(history, [color("#0000FF"), color("#00FF00"), color("#FF0000")])
    }

    func testHistoryIsCappedAtTenAndOldestIsDiscarded() {
        var history: [RGBAColor] = []
        for i in 1...11 {
            history = RecentColors.recording(RGBAColor(red: Double(i) / 20, green: 0, blue: 0), in: history)
        }
        XCTAssertEqual(history.count, 10)
        XCTAssertEqual(history.first, RGBAColor(red: 11.0 / 20, green: 0, blue: 0), "Newest at top left")
        XCTAssertEqual(history.last, RGBAColor(red: 2.0 / 20, green: 0, blue: 0), "First pick fell off the end")
    }

    func testDuplicateColorLeavesHistoryUnchanged() {
        let history = [color("#0000FF"), color("#00FF00"), color("#FF0000")]
        XCTAssertEqual(RecentColors.recording(color("#FF0000"), in: history), history)
    }

    func testNearlyIdenticalColorsCountAsDuplicates() {
        let history = [RGBAColor(red: 0.5, green: 0.5, blue: 0.5)]
        XCTAssertEqual(RecentColors.recording(RGBAColor(red: 0.5001, green: 0.5, blue: 0.5), in: history), history)
    }

    // MARK: - RGBAColor

    func testHexRoundTrip() {
        XCTAssertEqual(color("#1E88E5").hexString, "#1E88E5")
        XCTAssertEqual(RGBAColor(hex: "ff8000")?.hexString, "#FF8000")
    }

    func testInvalidHexIsRejected() {
        XCTAssertNil(RGBAColor(hex: "#12345"))
        XCTAssertNil(RGBAColor(hex: "GGGGGG"))
        XCTAssertNil(RGBAColor(hex: ""))
    }

    func testHSBPrimaries() {
        XCTAssertEqual(RGBAColor(hue: 0, saturation: 1, brightness: 1).hexString, "#FF0000")
        XCTAssertEqual(RGBAColor(hue: 1.0 / 3, saturation: 1, brightness: 1).hexString, "#00FF00")
        XCTAssertEqual(RGBAColor(hue: 2.0 / 3, saturation: 1, brightness: 1).hexString, "#0000FF")
        XCTAssertEqual(RGBAColor(hue: 0.5, saturation: 0, brightness: 1).hexString, "#FFFFFF")
        XCTAssertEqual(RGBAColor(hue: 0.5, saturation: 1, brightness: 0).hexString, "#000000")
    }

    func testHSBRoundTrip() {
        for hex in ["#1E88E5", "#E53935", "#FDD835", "#8E24AA", "#795548"] {
            let original = color(hex)
            let hsb = original.hsb
            let rebuilt = RGBAColor(hue: hsb.hue, saturation: hsb.saturation, brightness: hsb.brightness)
            XCTAssertEqual(rebuilt.hexString, hex)
        }
    }

    func testComponentsAreClamped() {
        let c = RGBAColor(red: 2, green: -1, blue: 0.5)
        XCTAssertEqual(c.red, 1)
        XCTAssertEqual(c.green, 0)
    }

    // MARK: - Project fields

    func testMetadataWithoutNewKeysStillDecodes() throws {
        let legacyJSON = """
        {"id":"\(UUID().uuidString)","name":"Old","createdAt":"2026-07-20T10:00:00Z","modifiedAt":"2026-08-01T10:00:00Z"}
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let project = try decoder.decode(Project.self, from: Data(legacyJSON.utf8))

        XCTAssertEqual(project.name, "Old")
        XCTAssertTrue(project.recentColors.isEmpty)
        XCTAssertNil(project.pencilWidth)
        XCTAssertEqual(project.effectivePencilWidth, StrokeWidths.pencilDefault)
        XCTAssertEqual(project.effectiveEraserWidth, StrokeWidths.eraserDefault)
    }

    func testNewFieldsRoundTrip() throws {
        let project = Project(
            id: UUID(), name: "Styled",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            modifiedAt: Date(timeIntervalSince1970: 1_700_000_100),
            recentColors: [color("#E53935"), color("#1E88E5")],
            pencilWidth: 8, eraserWidth: 32
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        XCTAssertEqual(try decoder.decode(Project.self, from: encoder.encode(project)), project)
    }

    func testInitialActiveColorIsMostRecentHistoryColor() {
        let project = Project(id: UUID(), name: "P", createdAt: Date(), modifiedAt: Date(),
                              recentColors: [color("#43A047"), color("#E53935")])
        XCTAssertEqual(project.initialActiveColor, color("#43A047"))
    }

    func testSaveAsCopyKeepsHistoryAndWidthsWithNewIdentity() {
        let original = Project(id: UUID(), name: "Original", createdAt: .distantPast, modifiedAt: .distantPast,
                               recentColors: [color("#E53935")], pencilWidth: 4, eraserWidth: 64)
        let copy = original.copy(named: "Copy")

        XCTAssertNotEqual(copy.id, original.id)
        XCTAssertEqual(copy.name, "Copy")
        XCTAssertGreaterThan(copy.createdAt, original.createdAt)
        XCTAssertEqual(copy.recentColors, original.recentColors)
        XCTAssertEqual(copy.pencilWidth, 4)
        XCTAssertEqual(copy.eraserWidth, 64)
    }

    // MARK: - Presets and tools

    func testPresets() {
        XCTAssertEqual(StrokeWidths.pencilPresets, [1, 2, 4, 8, 16])
        XCTAssertEqual(StrokeWidths.eraserPresets, [20, 32, 48, 64])
        XCTAssertTrue(StrokeWidths.pencilPresets.contains(StrokeWidths.pencilDefault))
        XCTAssertTrue(StrokeWidths.eraserPresets.contains(StrokeWidths.eraserDefault))
    }

    func testPencilToolUsesStyleColorAndWidth() throws {
        let style = ToolStyle(color: color("#E53935"), pencilWidth: 8, eraserWidth: 32)
        let tool = try XCTUnwrap(DrawingTool.pencil.pkTool(style: style) as? PKInkingTool)
        XCTAssertEqual(tool.width, 8, accuracy: 0.01)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        tool.color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        XCTAssertEqual(Double(red), 0xE5 / 255.0, accuracy: 0.01)
        XCTAssertEqual(Double(green), 0x39 / 255.0, accuracy: 0.01)
    }

    func testEraserToolUsesEraserWidth() throws {
        let style = ToolStyle(color: .black, pencilWidth: 1, eraserWidth: 32)
        let tool = try XCTUnwrap(DrawingTool.eraser.pkTool(style: style) as? PKEraserTool)
        // A sized bitmap eraser comes back as PencilKit's fixed-width bitmap type: it still erases
        // only the touched pixels (partial erase), unlike .vector which removes whole strokes.
        XCTAssertNotEqual(tool.eraserType, .vector)
        XCTAssertEqual(tool.width, 32, accuracy: 0.01)
    }

    func testEraserPresetsAreInsidePencilKitRange() {
        let range = PKEraserTool(.bitmap, width: 32).eraserType.validWidthRange
        for width in StrokeWidths.eraserPresets {
            XCTAssertTrue(range.contains(CGFloat(width)), "\(width) pt would be clamped to \(range)")
        }
    }

    // MARK: - Persistence per project

    func testHistoryAndWidthsPersistPerProject() throws {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent("Anime101StyleTests_\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: base) }
        let store = ProjectStore(baseDirectory: base)

        var a = store.createProject(name: "A")
        let b = store.createProject(name: "B")
        a.recentColors = [color("#E53935")]
        a.pencilWidth = 16
        a.eraserWidth = 48
        XCTAssertTrue(store.save(project: a, drawing: PKDrawing(), thumbnail: UIImage()))

        let reloadedA = try XCTUnwrap(store.loadProject(id: a.id)).project
        let reloadedB = try XCTUnwrap(store.loadProject(id: b.id)).project
        XCTAssertEqual(reloadedA.recentColors, [color("#E53935")])
        XCTAssertEqual(reloadedA.pencilWidth, 16)
        XCTAssertEqual(reloadedA.eraserWidth, 48)
        XCTAssertTrue(reloadedB.recentColors.isEmpty, "Other projects are unaffected")
        XCTAssertEqual(reloadedB.effectivePencilWidth, StrokeWidths.pencilDefault)

        let c = store.createProject(name: "C")
        XCTAssertTrue(c.recentColors.isEmpty, "New projects start fresh")
        XCTAssertNil(c.pencilWidth)
    }
}
