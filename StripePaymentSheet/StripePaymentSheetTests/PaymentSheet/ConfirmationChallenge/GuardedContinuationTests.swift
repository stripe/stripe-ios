//
//  GuardedContinuationTests.swift
//  StripePaymentSheetTests
//

@_spi(InternalOnlyAPI) @testable import StripeCore
@_spi(InternalOnlyAPI) @testable import StripePaymentSheet
import XCTest

final class GuardedContinuationTests: XCTestCase {
    @MainActor
    func testBodyExecutesOnMainActor() async {
        // Given a caller on the main actor
        // When withGuardedContinuation invokes its body synchronously
        let ranOnMainThread = await withGuardedContinuation { resume in
            resume(Thread.isMainThread)
        }

        // Then the body ran without hopping off the caller's executor.
        // (Without @MainActor on withGuardedContinuation, this would be false:
        // a plain nonisolated async function doesn't inherit the caller's executor.)
        XCTAssertTrue(ranOnMainThread)
    }

    @MainActor
    func testSecondResumeIsIgnoredInsteadOfTrapping() async {
        // Given a completion handler that will be invoked more than once
        STPAssertTestUtil.shouldSuppressNextSTPAlert = true

        // When it resumes twice
        let value = await withGuardedContinuation { resume in
            resume(1)
            resume(2) // Should be dropped (with a debug assertion), not crash.
        }

        // Then only the first resume wins, and the second was reported via the debug assertion
        XCTAssertEqual(value, 1)
        XCTAssertEqual(STPAssertTestUtil.lastAssertMessage, "Completion handler invoked more than once")
    }
}
