import XCTest
@testable import Anime101

final class CanvasViewHolderTests: XCTestCase {
    func testCanUndoIsFalseWithNoCanvasAttached() {
        let holder = CanvasViewHolder()
        XCTAssertFalse(holder.canUndo)
    }

    func testCanRedoIsFalseWithNoCanvasAttached() {
        let holder = CanvasViewHolder()
        XCTAssertFalse(holder.canRedo)
    }

    func testUndoDoesNotCrashWithNoCanvasAttached() {
        let holder = CanvasViewHolder()
        holder.undo()
    }

    func testRedoDoesNotCrashWithNoCanvasAttached() {
        let holder = CanvasViewHolder()
        holder.redo()
    }
}
