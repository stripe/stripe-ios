//
//  TimeoutTests.swift
//  StripeCore
//
//  Created by Joyce Qin on 10/28/25.
//

import Foundation

@_spi(STP) @testable import StripeCore
import XCTest

class TimeoutTests: XCTestCase {
    func testWithTimeout_allOperationsCompleteBeforeTimeout() async {
        let operation1 = AsyncOperation<String>(
            operation: {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                return "Result1"
            },
            onCancel: {}
        )

        let operation2 = AsyncOperation<Int>(
            operation: {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                return 42
            },
            onCancel: {}
        )

        let operation3 = AsyncOperation<Bool>(
            operation: {
                try await Task.sleep(nanoseconds: 300_000_000) // 0.3s
                return true
            },
            onCancel: {}
        )

        let (result1, result2, result3) = await withTimeout(
            timeout: 1.0,
            operation1, operation2, operation3
        )

        // Results should match operation positions, not completion order
        guard case .success(let value1) = result1 else {
            XCTFail("Operation 1 should succeed")
            return
        }
        XCTAssertEqual(value1, "Result1")

        guard case .success(let value2) = result2 else {
            XCTFail("Operation 2 should succeed")
            return
        }
        XCTAssertEqual(value2, 42)

        guard case .success(let value3) = result3 else {
            XCTFail("Operation 3 should succeed")
            return
        }
        XCTAssertEqual(value3, true)
    }

    func testWithTimeout_allOperationsTimeout() async {
        var cancel1Called = false
        var cancel2Called = false

        let operation1 = AsyncOperation<String>(
            operation: {
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5s
                return "Should not complete"
            },
            onCancel: {
                cancel1Called = true
            }
        )

        let operation2 = AsyncOperation<Int>(
            operation: {
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5s
                return 999
            },
            onCancel: {
                cancel2Called = true
            }
        )

        let (result1, result2) = await withTimeout(
            timeout: 0.1,
            operation1, operation2
        )

        guard case .failure(let error1) = result1 else {
            XCTFail("Operation 1 should not complete")
            return
        }
        XCTAssertEqual(error1 as? TimeoutError, TimeoutError.timeout)

        guard case .failure(let error2) = result2 else {
            XCTFail("Operation 2 should not complete")
            return
        }
        XCTAssertEqual(error2 as? TimeoutError, TimeoutError.timeout)

        // Give cancel handlers time to run
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(cancel1Called)
        XCTAssertTrue(cancel2Called)
    }

    func testWithTimeout_someOperationsTimeout() async {
        let operation1 = AsyncOperation<String>(
            operation: {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1s - completes
                return "Fast"
            },
            onCancel: {}
        )

        let operation2 = AsyncOperation<String>(
            operation: {
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5s - times out
                return "Slow"
            },
            onCancel: {}
        )

        let (result1, result2) = await withTimeout(
            timeout: 1,
            operation1, operation2
        )

        guard case .success(let value) = result1 else {
            XCTFail("Operation 1 should succeed")
            return
        }
        XCTAssertEqual(value, "Fast")

        guard case .failure(let error) = result2 else {
            XCTFail("Operation 2 should not complete")
            return
        }
        XCTAssertEqual(error as? TimeoutError, TimeoutError.timeout)
    }

    func testWithTimeout_singleOperation() async {
        let operation = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                return "Single"
            },
            onCancel: {}
        )

        let result = await withTimeout(timeout: 1.0, operation)

        guard case .success(let value) = result else {
            XCTFail("Operation should succeed")
            return
        }
        XCTAssertEqual(value, "Single")
    }

    func testWithTimeout_singleOperationTimesOut() async {
        let operation = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5s
                return "Should timeout"
            },
            onCancel: {}
        )

        let result = await withTimeout(timeout: 0.1, operation)

        guard case .failure(let error) = result else {
            XCTFail("Operation should not complete")
            return
        }
        XCTAssertEqual(error as? TimeoutError, TimeoutError.timeout)
    }

    func testWithTimeout_operationsThrowErrors() async {
        enum TestError: Error {
            case test
        }

        let operation1 = AsyncOperation<Error>(
            operation: {
                throw TestError.test
            },
            onCancel: {}
        )

        let operation2 = AsyncOperation<String>(
            operation: {
                return "Success"
            },
            onCancel: {}
        )

        let (result1, result2) = await withTimeout(
            timeout: 1.0,
            operation1, operation2
        )

        guard case .failure(let error) = result1 else {
            XCTFail("Operation 1 should throw error")
            return
        }
        XCTAssertEqual(error as? TestError, TestError.test)

        guard case .success(let value) = result2 else {
            XCTFail("Operation 2 should succeed")
            return
        }
        XCTAssertEqual(value, "Success")
    }

    func testWithTimeout_parallel() async {
        // All operations start at the same time, so total time should be ~0.5s
        let startTime = Date()

        let operation1 = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 400_000_000) // 0.4s
                return 1
            },
            onCancel: {}
        )

        let operation2 = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 400_000_000) // 0.4s
                return 2
            },
            onCancel: {}
        )

        let operation3 = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 400_000_000) // 0.4s
                return 3
            },
            onCancel: {}
        )

        let (result1, result2, result3) = await withTimeout(
            timeout: 1.0,
            operation1, operation2, operation3
        )

        let elapsed = Date().timeIntervalSince(startTime)

        XCTAssertEqual(try result1.get(), 1)
        XCTAssertEqual(try result2.get(), 2)
        XCTAssertEqual(try result3.get(), 3)

        // Should complete in ~0.4s (parallel execution), not 1.2s (sequential)
        XCTAssertLessThan(elapsed, 0.8)
    }

    func testWithTimeout_cancellationHandlersCalledOnTimeout() async {
        let expectation1 = XCTestExpectation(description: "Cancel handler 1 called")
        let expectation2 = XCTestExpectation(description: "Cancel handler 2 called")

        let operation1 = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5s
                return "A"
            },
            onCancel: {
                expectation1.fulfill()
            }
        )

        let operation2 = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5s
                return "B"
            },
            onCancel: {
                expectation2.fulfill()
            }
        )

        _ = await withTimeout(timeout: 0.1, operation1, operation2)

        await fulfillment(of: [expectation1, expectation2], timeout: 1.0)
    }

}
