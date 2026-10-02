import XCTest
@testable import Anime101

final class FloatingPanelLayoutTests: XCTestCase {
    private let panel = CGSize(width: 300, height: 400)
    private let container = CGSize(width: 800, height: 1000)

    func testOffsetInsideBoundsIsUnchanged() {
        let offset = CGSize(width: 100, height: 200)
        XCTAssertEqual(FloatingPanelLayout.clamp(offset, panelSize: panel, containerSize: container), offset)
    }

    func testOffsetIsClampedToLeftAndRightEdges() {
        // Centered panel can move (800 - 300) / 2 = 250 either way.
        XCTAssertEqual(FloatingPanelLayout.clamp(CGSize(width: 900, height: 0), panelSize: panel, containerSize: container).width, 250)
        XCTAssertEqual(FloatingPanelLayout.clamp(CGSize(width: -900, height: 0), panelSize: panel, containerSize: container).width, -250)
    }

    func testOffsetIsClampedToTopAndBottomEdges() {
        XCTAssertEqual(FloatingPanelLayout.clamp(CGSize(width: 0, height: -50), panelSize: panel, containerSize: container).height, 0)
        XCTAssertEqual(FloatingPanelLayout.clamp(CGSize(width: 0, height: 5000), panelSize: panel, containerSize: container).height, 600)
    }

    func testPanelLargerThanContainerPinsToTopCenter() {
        let tiny = CGSize(width: 200, height: 200)
        XCTAssertEqual(FloatingPanelLayout.clamp(CGSize(width: 40, height: 40), panelSize: panel, containerSize: tiny), .zero)
    }
}
