//
//  AsyncTests.swift
//  StripeCoreTests
//
//  Created by Mat Schmid on 2024-09-24.
//

@_spi(STP) @testable import StripeCore
import XCTest

class AsyncTests: XCTestCase {

    func testFutureObserveWithImmediateResult() {
        let promise = Promise<Int>(value: 42)
        let expectation = XCTestExpectation(description: "Observe immediate result")

        promise.observe { result in
            XCTAssertEqual(result.successValue, 42)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testFutureObserveWithDelayedResult() {
        let promise = Promise<Int>()
        let expectation = XCTestExpectation(description: "Observe delayed result")

        promise.observe { result in
            XCTAssertEqual(result.successValue, 42)
            expectation.fulfill()
        }

        promise.resolve(with: 42)
        wait(for: [expectation], timeout: 1.0)
    }

    func testFutureChainedSuccess() {
        let promise = Promise<Int>(value: 42)
        let chainedFuture = promise.chained { value in
            return Promise(value: value * 2)
        }

        let expectation = XCTestExpectation(description: "Chained success")

        chainedFuture.observe { result in
            XCTAssertEqual(result.successValue, 84)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testFutureChainedFailure() {
        let promise = Promise<Int>()
        let chainedFuture: Future<Int> = promise.chained { _ in
            return Promise(error: NSError(domain: "test", code: 0, userInfo: nil))
        }

        let expectation = XCTestExpectation(description: "Chained failure")

        chainedFuture.observe { result in
            XCTAssertNotNil(result.failureValue)
            expectation.fulfill()
        }

        promise.reject(with: NSError(domain: "test", code: 0, userInfo: nil))
        wait(for: [expectation], timeout: 1.0)
    }

    func testFutureTransformed() {
        let promise = Promise<Int>(value: 42)
        let transformedFuture = promise.transformed { value in
            return value * 2
        }

        let expectation = XCTestExpectation(description: "Transformed success")

        transformedFuture.observe { result in
            XCTAssertEqual(result.successValue, 84)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testFutureTransformedFailure() {
        let promise = Promise<Int>()
        let transformedFuture = promise.transformed { value in
            return value * 2
        }

        let expectation = XCTestExpectation(description: "Transformed failure")

        transformedFuture.observe { result in
            XCTAssertNotNil(result.failureValue)
            expectation.fulfill()
        }

        promise.reject(with: NSError(domain: "test", code: 0, userInfo: nil))
        wait(for: [expectation], timeout: 1.0)
    }

    func testPromiseResolved() {
        let promise = Promise<Int>()
        let expectation = XCTestExpectation(description: "Promise resolved")

        promise.observe { result in
            XCTAssertEqual(result.successValue, 42)
            expectation.fulfill()
        }

        promise.resolve(with: 42)
        wait(for: [expectation], timeout: 1.0)
    }

    func testPromiseRejected() {
        let promise = Promise<Int>()
        let expectation = XCTestExpectation(description: "Promise rejected")

        promise.observe { result in
            XCTAssertNotNil(result.failureValue)
            expectation.fulfill()
        }

        promise.reject(with: NSError(domain: "test", code: 0, userInfo: nil))
        wait(for: [expectation], timeout: 1.0)
    }

    func testPromiseFullfill() {
        let promise = Promise<Int>()
        let expectation = XCTestExpectation(description: "Promise fullfill")

        promise.observe { result in
            XCTAssertEqual(result.successValue, 42)
            expectation.fulfill()
        }

        promise.fullfill(with: .success(42))
        wait(for: [expectation], timeout: 1.0)
    }
}

private extension Result {
    var successValue: Success? {
        try? get()
    }

    var failureValue: Error? {
        guard case .failure(let error) = self else {
            return nil
        }
        return error
    }
}
