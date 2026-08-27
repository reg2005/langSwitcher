import XCTest
import Cocoa
@testable import LangSwitcher

final class DoubleTapModifierDetectorTests: XCTestCase {
    func testDoubleShiftTriggersWithinInterval() {
        var detector = DoubleTapModifierDetector(modifier: .shift)

        XCTAssertFalse(tap(.shift, at: 1.0, detector: &detector))
        XCTAssertTrue(tap(.shift, at: 1.3, detector: &detector))
    }

    func testDoubleOptionTriggersWithinInterval() {
        var detector = DoubleTapModifierDetector(modifier: .option)

        XCTAssertFalse(tap(.option, at: 1.0, detector: &detector))
        XCTAssertTrue(tap(.option, at: 1.3, detector: &detector))
    }

    func testDoubleTapDoesNotTriggerAfterTimeout() {
        var detector = DoubleTapModifierDetector(modifier: .option)

        XCTAssertFalse(tap(.option, at: 1.0, detector: &detector))
        XCTAssertFalse(tap(.option, at: 1.5, detector: &detector))
    }

    func testOtherKeyBetweenTapsCancelsSequence() {
        var detector = DoubleTapModifierDetector(modifier: .option)

        XCTAssertFalse(tap(.option, at: 1.0, detector: &detector))
        detector.handleOtherKeyDown()
        XCTAssertFalse(tap(.option, at: 1.2, detector: &detector))
    }

    func testOtherModifierCancelsSequence() {
        var detector = DoubleTapModifierDetector(modifier: .option)

        XCTAssertFalse(tap(.option, at: 1.0, detector: &detector))
        XCTAssertFalse(detector.handleModifierFlags([.option, .shift], at: 1.1))
        XCTAssertFalse(detector.handleModifierFlags([], at: 1.15))
        XCTAssertFalse(tap(.option, at: 1.2, detector: &detector))
    }

    func testShiftDoesNotTriggerOptionDetector() {
        var detector = DoubleTapModifierDetector(modifier: .option)

        XCTAssertFalse(tap(.shift, at: 1.0, detector: &detector))
        XCTAssertFalse(tap(.shift, at: 1.2, detector: &detector))
    }

    private func tap(
        _ modifier: NSEvent.ModifierFlags,
        at timestamp: TimeInterval,
        detector: inout DoubleTapModifierDetector
    ) -> Bool {
        XCTAssertFalse(detector.handleModifierFlags(modifier, at: timestamp))
        return detector.handleModifierFlags([], at: timestamp + 0.01)
    }
}
