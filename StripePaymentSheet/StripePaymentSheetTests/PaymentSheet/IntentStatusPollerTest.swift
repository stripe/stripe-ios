//
//  IntentStatusPollerTest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 9/14/23.
//

@testable import StripePaymentSheet
import XCTest

final class IntentStatusPollerTest: XCTestCase {
    private enum TestStatus: Equatable {
        case pending
        case succeeded
        case failed
    }

    private let retryInterval = 0.1
    private var sut: IntentStatusPoller<TestStatus, TestStatus>!
    private var retriever: MockStatusRetriever<TestStatus>!
    private var updates: [TestStatus]!
    private var updateExpectation: XCTestExpectation?

    override func setUp() {
        super.setUp()
        retriever = MockStatusRetriever()
        updates = []
        sut = IntentStatusPoller(
            retryInterval: retryInterval,
            retrieveValue: retriever.retrieve,
            status: \.self,
            didUpdate: { [weak self] status in
                self?.updates.append(status)
                self?.updateExpectation?.fulfill()
            }
        )
    }

    override func tearDown() {
        sut.suspendPolling()
        sut = nil
        retriever = nil
        updates = nil
        updateExpectation = nil
        super.tearDown()
    }

    func testPollingCanBeSuspendedAndResumed() {
        // Given a pending status
        retriever.statuses = [.pending, .pending, .pending]
        retriever.expectation = expectation(description: "Poll three times")
        retriever.expectation?.expectedFulfillmentCount = 3
        updateExpectation = expectation(description: "Report the first status")

        // When polling begins
        sut.beginPolling()

        // Then it polls repeatedly and reports the status once
        wait(for: [retriever.expectation!, updateExpectation!], timeout: retryInterval * 6)
        XCTAssertEqual(updates, [.pending])

        // When polling is suspended
        sut.suspendPolling()
        retriever.statuses = [.succeeded]
        let suspendedRetrieval = expectation(description: "Do not retrieve while suspended")
        suspendedRetrieval.isInverted = true
        retriever.expectation = suspendedRetrieval
        updateExpectation = expectation(description: "Do not report while suspended")
        updateExpectation?.isInverted = true

        // Then it does not retrieve or report a status
        wait(for: [suspendedRetrieval, updateExpectation!], timeout: retryInterval * 2)
        XCTAssertEqual(updates, [.pending])

        // When polling resumes with a succeeded status
        retriever.expectation = expectation(description: "Retrieve after resuming")
        updateExpectation = expectation(description: "Report succeeded")
        sut.beginPolling()

        // Then it reports the new status
        wait(for: [retriever.expectation!, updateExpectation!], timeout: retryInterval * 2)
        XCTAssertEqual(updates, [.pending, .succeeded])
    }

    func testPollOnceReportsTheCurrentStatus() {
        // Given a pending status while continuous polling is inactive
        retriever.statuses = [.pending]
        retriever.expectation = expectation(description: "Retrieve once")
        updateExpectation = expectation(description: "Report once")
        let completionExpectation = expectation(description: "Complete once")

        // When polling once
        sut.pollOnce { status in
            XCTAssertEqual(status, .pending)
            completionExpectation.fulfill()
        }

        // Then it reports and returns the current status
        wait(for: [retriever.expectation!, updateExpectation!, completionExpectation], timeout: retryInterval * 2)
        XCTAssertEqual(updates, [.pending])
    }

    func testPollingContinuesAfterRetrievalFailure() {
        // Given a transient retrieval failure followed by a pending status
        retriever.statuses = [nil, .pending]
        retriever.expectation = expectation(description: "Retry after failure")
        retriever.expectation?.expectedFulfillmentCount = 2
        updateExpectation = expectation(description: "Report recovered status")

        // When polling begins
        sut.beginPolling()

        // Then it retries and reports the next status
        wait(for: [retriever.expectation!, updateExpectation!], timeout: retryInterval * 4)
        XCTAssertEqual(updates, [.pending])
    }

    func testResponseFromSuspendedPollingGenerationIsIgnored() {
        // Given an in-flight request from the first polling generation
        retriever.automaticallyCompletes = false
        retriever.expectation = expectation(description: "Start two generations")
        retriever.expectation?.expectedFulfillmentCount = 2
        sut.beginPolling()

        // When polling is suspended and resumed before the first request completes
        sut.suspendPolling()
        sut.beginPolling()
        wait(for: [retriever.expectation!], timeout: retryInterval * 2)
        updateExpectation = expectation(description: "Report only the current generation")
        retriever.completeRequest(at: 0, with: .failed)
        retriever.completeRequest(at: 0, with: .pending)

        // Then the stale response is ignored
        wait(for: [updateExpectation!], timeout: retryInterval * 2)
        XCTAssertEqual(updates, [.pending])
    }
}

private final class MockStatusRetriever<Status> {
    var automaticallyCompletes = true
    var expectation: XCTestExpectation?
    var statuses: [Status?] = []
    private var pendingCompletions: [(Status?) -> Void] = []

    func retrieve(completion: @escaping (Status?) -> Void) {
        expectation?.fulfill()
        if automaticallyCompletes {
            completion(statuses.isEmpty ? nil : statuses.removeFirst())
        } else {
            pendingCompletions.append(completion)
        }
    }

    func completeRequest(at index: Int, with status: Status?) {
        pendingCompletions.remove(at: index)(status)
    }
}
