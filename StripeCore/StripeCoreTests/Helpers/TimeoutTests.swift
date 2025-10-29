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

    // MARK: - runWithTimeout Tests

    func testRunWithTimeout_operationCompletesBeforeTimeout() async throws {
        let operation = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                return "Success"
            },
            onCancel: {}
        )

        let result = try await runWithTimeout(timeout: 1.0, operation)
        XCTAssertEqual(result, "Success")
    }

    func testRunWithTimeout_operationTimesOut() async throws {
        var cancelCalled = false
        let operation = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2s
                return "Should not complete"
            },
            onCancel: {
                cancelCalled = true
            }
        )

        let result = try await runWithTimeout(timeout: 0.1, operation)
        XCTAssertNil(result)

        // Give the cancel handler time to run
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(cancelCalled)
    }

    func testRunWithTimeout_operationThrowsError() async throws {
        struct TestError: Error {}

        let operation = AsyncOperation(
            operation: {
                throw TestError()
            },
            onCancel: {}
        )

        do {
            _ = try await runWithTimeout(timeout: 1.0, operation)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }

    func testRunWithTimeout_cancellationHandlerCalledOnTimeout() async throws {
        let expectation = XCTestExpectation(description: "Cancel handler called")

        let operation = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5s
                return 42
            },
            onCancel: {
                expectation.fulfill()
            }
        )

        let result = try await runWithTimeout(timeout: 0.1, operation)
        XCTAssertNil(result)

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testRunWithTimeout_cancellationHandlerCalledOnSuccess() async throws {
        let expectation = XCTestExpectation(description: "Cancel handler called even on success")

        let operation = AsyncOperation(
            operation: {
                return "Quick result"
            },
            onCancel: {
                expectation.fulfill()
            }
        )

        let result = try await runWithTimeout(timeout: 1.0, operation)
        XCTAssertEqual(result, "Quick result")

        // Cancel handler should still be called due to defer block
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // MARK: - withTimeout Tests

    func testWithTimeout_allOperationsCompleteBeforeTimeout() async {
        let operation1 = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                return "Result1"
            },
            onCancel: {}
        )

        let operation2 = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                return 42
            },
            onCancel: {}
        )

        let operation3 = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                return true
            },
            onCancel: {}
        )

        let (result1, result2, result3) = await withTimeout(
            timeout: 1.0,
            operation1, operation2, operation3
        )

        XCTAssertEqual(result1, "Result1")
        XCTAssertEqual(result2, 42)
        XCTAssertEqual(result3, true)
    }

    func testWithTimeout_allOperationsTimeout() async {
        var cancel1Called = false
        var cancel2Called = false

        let operation1 = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5s
                return "Should not complete"
            },
            onCancel: {
                cancel1Called = true
            }
        )

        let operation2 = AsyncOperation(
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

        XCTAssertNil(result1)
        XCTAssertNil(result2)

        // Give cancel handlers time to run
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(cancel1Called)
        XCTAssertTrue(cancel2Called)
    }

    func testWithTimeout_someOperationsTimeout() async {
        let operation1 = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1s - completes
                return "Fast"
            },
            onCancel: {}
        )

        let operation2 = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5s - times out
                return "Slow"
            },
            onCancel: {}
        )

        let (result1, result2) = await withTimeout(
            timeout: 0.5,
            operation1, operation2
        )

        XCTAssertEqual(result1, "Fast")
        XCTAssertNil(result2)
    }

    func testWithTimeout_singleOperation() async {
        let operation = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                return "Single"
            },
            onCancel: {}
        )

        let (result, ) = await withTimeout(timeout: 1.0, operation)

        XCTAssertEqual(result, "Single")
    }

    func testWithTimeout_singleOperationTimesOut() async {
        let operation = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5s
                return "Should timeout"
            },
            onCancel: {}
        )

        let (result, ) = await withTimeout(timeout: 0.1, operation)

        XCTAssertNil(result)
    }

    func testWithTimeout_operationsThrowErrors() async {
        struct TestError: Error {}

        let operation1 = AsyncOperation<Error>(
            operation: {
                throw TestError()
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

        XCTAssertNil(result1) // Threw error
        XCTAssertEqual(result2, "Success")
    }

    func testWithTimeout_sharedTimeoutSemantics() async {
        // All operations start at the same time, so total time should be ~0.5s
        // This tests that the timeout is shared across all operations
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

        XCTAssertEqual(result1, 1)
        XCTAssertEqual(result2, 2)
        XCTAssertEqual(result3, 3)

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

    func testWithTimeout_zeroTimeout() async {
        let operation1 = AsyncOperation(
            operation: {
                return "Instant"
            },
            onCancel: {}
        )

        let operation2 = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 100_000_000)
                return "Delayed"
            },
            onCancel: {}
        )

        let (result1, result2) = await withTimeout(
            timeout: 0.0,
            operation1, operation2
        )

        // With zero timeout, even instant operations might not complete
        // depending on scheduling, so we just verify the function handles it
        XCTAssertNil(result2) // Definitely won't complete
        // result1 may or may not complete depending on scheduling
    }

    // MARK: - withResultTimeout Tests

    func testWithResultTimeout_allOperationsSucceed() async {
        let operation1 = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                return "Result1"
            },
            onCancel: {}
        )

        let operation2 = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                return 42
            },
            onCancel: {}
        )

        let operation3 = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                return true
            },
            onCancel: {}
        )

        let (result1, result2, result3) = await withResultTimeout(
            timeout: 1.0,
            operation1, operation2, operation3
        )

        // Verify all succeeded
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

    func testWithResultTimeout_allOperationsTimeout() async {
        let operation1 = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5s
                return "Should not complete"
            },
            onCancel: {}
        )

        let operation2 = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5s
                return 999
            },
            onCancel: {}
        )

        let (result1, result2) = await withResultTimeout(
            timeout: 0.1,
            operation1, operation2
        )

        // Verify both timed out
        guard case .failure(let error1) = result1,
              error1 is TimeoutError else {
            XCTFail("Operation 1 should timeout")
            return
        }

        guard case .failure(let error2) = result2,
              error2 is TimeoutError else {
            XCTFail("Operation 2 should timeout")
            return
        }
    }

    func testWithResultTimeout_mixedSuccessAndTimeout() async {
        let operation1 = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1s - completes
                return "Fast"
            },
            onCancel: {}
        )

        let operation2 = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5s - times out
                return "Slow"
            },
            onCancel: {}
        )

        let operation3 = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 200_000_000) // 0.2s - completes
                return "Medium"
            },
            onCancel: {}
        )

        let (result1, result2, result3) = await withResultTimeout(
            timeout: 0.5,
            operation1, operation2, operation3
        )

        // Operation 1 should succeed
        guard case .success(let value1) = result1 else {
            XCTFail("Operation 1 should succeed")
            return
        }
        XCTAssertEqual(value1, "Fast")

        // Operation 2 should timeout
        guard case .failure(let error2) = result2,
              error2 is TimeoutError else {
            XCTFail("Operation 2 should timeout")
            return
        }

        // Operation 3 should succeed
        guard case .success(let value3) = result3 else {
            XCTFail("Operation 3 should succeed")
            return
        }
        XCTAssertEqual(value3, "Medium")
    }

    func testWithResultTimeout_operationsThrowErrors() async {
        struct TestError: Error {}

        let operation1 = AsyncOperation(
            operation: {
                throw TestError()
            },
            onCancel: {}
        )

        let operation2 = AsyncOperation(
            operation: {
                return "Success"
            },
            onCancel: {}
        )

        let (result1, result2) = await withResultTimeout(
            timeout: 1.0,
            operation1, operation2
        )

        // Operation 1 should fail with TestError
        guard case .failure(let error1) = result1,
              error1 is TestError else {
            XCTFail("Operation 1 should fail with TestError")
            return
        }

        // Operation 2 should succeed
        guard case .success(let value2) = result2 else {
            XCTFail("Operation 2 should succeed")
            return
        }
        XCTAssertEqual(value2, "Success")
    }

    func testWithResultTimeout_mixedSuccessTimeoutAndError() async {
        struct CustomError: Error {}

        let operation1 = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1s - completes
                return 1
            },
            onCancel: {}
        )

        let operation2 = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 50_000_000) // 0.05s
                throw CustomError()
            },
            onCancel: {}
        )

        let operation3 = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5s - times out
                return 3
            },
            onCancel: {}
        )

        let (result1, result2, result3) = await withResultTimeout(
            timeout: 0.5,
            operation1, operation2, operation3
        )

        // Operation 1 should succeed
        guard case .success(let value1) = result1 else {
            XCTFail("Operation 1 should succeed")
            return
        }
        XCTAssertEqual(value1, 1)

        // Operation 2 should fail with CustomError
        guard case .failure(let error2) = result2,
              error2 is CustomError else {
            XCTFail("Operation 2 should fail with CustomError")
            return
        }

        // Operation 3 should timeout
        guard case .failure(let error3) = result3,
              error3 is TimeoutError else {
            XCTFail("Operation 3 should timeout")
            return
        }
    }

    func testWithResultTimeout_singleOperation() async {
        let operation = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                return "Single"
            },
            onCancel: {}
        )

        let (result, ) = await withResultTimeout(timeout: 1.0, operation)

        guard case .success(let value) = result else {
            XCTFail("Operation should succeed")
            return
        }
        XCTAssertEqual(value, "Single")
    }

    func testWithResultTimeout_singleOperationTimesOut() async {
        let operation = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5s
                return "Should timeout"
            },
            onCancel: {}
        )

        let (result, ) = await withResultTimeout(timeout: 0.1, operation)

        guard case .failure(let error) = result,
              error is TimeoutError else {
            XCTFail("Operation should timeout")
            return
        }
    }

    func testWithResultTimeout_parallelExecution() async {
        // Verify operations run in parallel by checking total execution time
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

        let (result1, result2, result3) = await withResultTimeout(
            timeout: 1.0,
            operation1, operation2, operation3
        )

        let elapsed = Date().timeIntervalSince(startTime)

        // All should succeed
        guard case .success(let value1) = result1 else {
            XCTFail("Operation 1 should succeed")
            return
        }
        XCTAssertEqual(value1, 1)

        guard case .success(let value2) = result2 else {
            XCTFail("Operation 2 should succeed")
            return
        }
        XCTAssertEqual(value2, 2)

        guard case .success(let value3) = result3 else {
            XCTFail("Operation 3 should succeed")
            return
        }
        XCTAssertEqual(value3, 3)

        // Should complete in ~0.4s (parallel execution), not 1.2s (sequential)
        XCTAssertLessThan(elapsed, 0.8)
    }

    func testWithResultTimeout_cancellationHandlersCalled() async {
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

        _ = await withResultTimeout(timeout: 0.1, operation1, operation2)

        await fulfillment(of: [expectation1, expectation2], timeout: 1.0)
    }

    func testWithResultTimeout_resultPositionMatchesOperation() async {
        // Verify that each result corresponds to its operation position
        // even when operations complete out of order
        let operation1 = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 300_000_000) // 0.3s - completes last
                return "First"
            },
            onCancel: {}
        )

        let operation2 = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1s - completes first
                return "Second"
            },
            onCancel: {}
        )

        let operation3 = AsyncOperation(
            operation: {
                try await Task.sleep(nanoseconds: 200_000_000) // 0.2s - completes second
                return "Third"
            },
            onCancel: {}
        )

        let (result1, result2, result3) = await withResultTimeout(
            timeout: 1.0,
            operation1, operation2, operation3
        )

        // Results should match operation positions, not completion order
        guard case .success(let value1) = result1 else {
            XCTFail("Operation 1 should succeed")
            return
        }
        XCTAssertEqual(value1, "First")

        guard case .success(let value2) = result2 else {
            XCTFail("Operation 2 should succeed")
            return
        }
        XCTAssertEqual(value2, "Second")

        guard case .success(let value3) = result3 else {
            XCTFail("Operation 3 should succeed")
            return
        }
        XCTAssertEqual(value3, "Third")
    }
}
