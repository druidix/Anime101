import XCTest
import PencilKit
@testable import Anime101

final class DrawingToolTests: XCTestCase {
    func testAllCases() {
        XCTAssertEqual(DrawingTool.allCases, [.pencil, .eraser])
    }

    func testPencilLabel() {
        XCTAssertEqual(DrawingTool.pencil.label, "Pencil")
    }

    func testEraserLabel() {
        XCTAssertEqual(DrawingTool.eraser.label, "Eraser")
    }

    func testPencilSystemImage() {
        XCTAssertEqual(DrawingTool.pencil.systemImage, "pencil")
    }

    func testEraserSystemImage() {
        XCTAssertEqual(DrawingTool.eraser.systemImage, "eraser")
    }

    func testPencilPKTool() {
        XCTAssertTrue(DrawingTool.pencil.pkTool is PKInkingTool)
    }

    func testEraserPKTool() {
        XCTAssertTrue(DrawingTool.eraser.pkTool is PKEraserTool)
    }
}
