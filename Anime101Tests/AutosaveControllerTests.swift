import XCTest
@testable import Anime101

final class FakeAutosaveTimer: AutosaveTimerScheduling {
    private(set) var isInvalidated = false

    func invalidate() {
        isInvalidated = true
    }
}

final class AutosaveControllerTests: XCTestCase {
    func testDefaultIntervalsAre10And60Seconds() {
        var scheduledIntervals: [TimeInterval] = []
        let controller = AutosaveController { interval, _ in
            scheduledIntervals.append(interval)
            return FakeAutosaveTimer()
        }

        controller.start()

        XCTAssertEqual(scheduledIntervals, [10, 60])
    }

    func testStartSchedulesActivityAndBackstopTimers() {
        var blocks: [() -> Void] = []
        let controller = AutosaveController(activityInterval: 10, backstopInterval: 60) { _, block in
            blocks.append(block)
            return FakeAutosaveTimer()
        }

        controller.start()

        XCTAssertEqual(blocks.count, 2)
    }

    func testActivityTimerFiringInvokesOnActivitySave() {
        var firedBlocks: [() -> Void] = []
        let controller = AutosaveController { _, block in
            firedBlocks.append(block)
            return FakeAutosaveTimer()
        }

        var activitySaveCallCount = 0
        controller.onActivitySave = { activitySaveCallCount += 1 }
        controller.onBackstopSave = { XCTFail("Backstop handler should not fire from the activity timer") }
        controller.start()

        firedBlocks[0]()

        XCTAssertEqual(activitySaveCallCount, 1)
    }

    func testBackstopTimerFiringInvokesOnBackstopSave() {
        var firedBlocks: [() -> Void] = []
        let controller = AutosaveController { _, block in
            firedBlocks.append(block)
            return FakeAutosaveTimer()
        }

        var backstopSaveCallCount = 0
        controller.onActivitySave = { XCTFail("Activity handler should not fire from the backstop timer") }
        controller.onBackstopSave = { backstopSaveCallCount += 1 }
        controller.start()

        firedBlocks[1]()

        XCTAssertEqual(backstopSaveCallCount, 1)
    }

    func testStopInvalidatesBothTimers() {
        var createdTimers: [FakeAutosaveTimer] = []
        let controller = AutosaveController { _, _ in
            let timer = FakeAutosaveTimer()
            createdTimers.append(timer)
            return timer
        }

        controller.start()
        controller.stop()

        XCTAssertEqual(createdTimers.count, 2)
        XCTAssertTrue(createdTimers.allSatisfy(\.isInvalidated))
    }

    func testResetTimersInvalidatesPreviousTimersAndStartsFreshOnes() {
        var createdTimers: [FakeAutosaveTimer] = []
        let controller = AutosaveController { _, _ in
            let timer = FakeAutosaveTimer()
            createdTimers.append(timer)
            return timer
        }

        controller.start()
        let firstBatch = createdTimers
        controller.resetTimers()

        XCTAssertEqual(createdTimers.count, 4)
        XCTAssertTrue(firstBatch.allSatisfy(\.isInvalidated))
        XCTAssertFalse(createdTimers.suffix(2).contains { $0.isInvalidated })
    }

    func testStopClearsTimerReferences() {
        let controller = AutosaveController { _, _ in FakeAutosaveTimer() }

        controller.start()
        controller.stop()

        XCTAssertNil(controller.activityTimer)
        XCTAssertNil(controller.backstopTimer)
    }
}
