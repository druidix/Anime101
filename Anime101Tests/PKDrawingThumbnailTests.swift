import XCTest
import PencilKit
@testable import Anime101

final class PKDrawingThumbnailTests: XCTestCase {
    func testEmptyDrawingProducesImageOfRequestedSize() {
        let drawing = PKDrawing()
        let size = CGSize(width: 100, height: 100)

        let thumbnail = drawing.createThumbnail(size: size)

        XCTAssertEqual(thumbnail.size, size)
    }

    func testCustomSizeIsRespected() {
        let drawing = PKDrawing()
        let size = CGSize(width: 50, height: 200)

        let thumbnail = drawing.createThumbnail(size: size)

        XCTAssertEqual(thumbnail.size, size)
    }

    func testDefaultSizeIsUsedWhenNotSpecified() {
        let drawing = PKDrawing()

        let thumbnail = drawing.createThumbnail()

        XCTAssertEqual(thumbnail.size, CGSize(width: 100, height: 100))
    }
}
