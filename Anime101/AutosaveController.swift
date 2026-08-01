import Foundation

protocol AutosaveTimerScheduling: AnyObject {
    func invalidate()
}

extension Timer: AutosaveTimerScheduling {}

/// Drives the two autosave cadences described in Milestone 6: a short "activity" timer that
/// saves only if the drawing changed since the last save, and a longer "backstop" timer that
/// saves unconditionally so idle changes are never left unpersisted for too long.
final class AutosaveController {
    typealias TimerFactory = (TimeInterval, @escaping () -> Void) -> AutosaveTimerScheduling

    let activityInterval: TimeInterval
    let backstopInterval: TimeInterval

    var onActivitySave: (() -> Void)?
    var onBackstopSave: (() -> Void)?

    private(set) var activityTimer: AutosaveTimerScheduling?
    private(set) var backstopTimer: AutosaveTimerScheduling?
    private let makeTimer: TimerFactory

    init(
        activityInterval: TimeInterval = 10,
        backstopInterval: TimeInterval = 60,
        timerFactory: @escaping TimerFactory = { interval, block in
            Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in block() }
        }
    ) {
        self.activityInterval = activityInterval
        self.backstopInterval = backstopInterval
        self.makeTimer = timerFactory
    }

    func start() {
        stop()
        activityTimer = makeTimer(activityInterval) { [weak self] in
            self?.onActivitySave?()
        }
        backstopTimer = makeTimer(backstopInterval) { [weak self] in
            self?.onBackstopSave?()
        }
    }

    func stop() {
        activityTimer?.invalidate()
        activityTimer = nil
        backstopTimer?.invalidate()
        backstopTimer = nil
    }

    /// Restarts both timers from now. Called after a manual save so the next autosave
    /// cadence is measured from that point rather than firing shortly after.
    func resetTimers() {
        start()
    }

    deinit {
        stop()
    }
}
