//
//  MockComponentAnalyticsClient.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 11/7/24.
//

@testable import StripeConnect
@_spi(STP) import StripeCoreTestUtils
import XCTest

class MockComponentAnalyticsClient: ComponentAnalyticsClient {
    var loggedEvents: [any ConnectAnalyticEvent] = []
    var loggedClientErrors: [(domain: String, code: Int)] = []

    init(commonFields: CommonFields) {
        super.init(client: MockAnalyticsClientV2(), commonFields: commonFields)
    }

    override func log<Event: ConnectAnalyticEvent>(event: Event) {
        loggedEvents.append(event)
    }

    override func logClientError(_ error: any Error,
                                 file: StaticString = #file,
                                 line: UInt = #line) {
        loggedClientErrors.append(((error as NSError).domain,
                                   (error as NSError).code))
    }

    func lastEvent<T: ConnectAnalyticEvent>(ofType t: T.Type,
                                            file: StaticString = #file,
                                            line: UInt = #line) throws -> T {
        try XCTUnwrap(loggedEvents.compactMap { $0 as? T }.last,
                      "loggedEvents: \(loggedEvents)",
                      file: file,
                      line: line)
    }
}

/*
 Because `any ConnectAnalyticEvent` does not conform to Equatable, we have to
 define some helpers for testing for equality.
 */

extension ConnectAnalyticEvent {
    func isEqual(to other: any ConnectAnalyticEvent) -> Bool {
        guard let typedOther = other as? Self else {
            return false
        }
        return typedOther == self
    }
}

extension Optional where Wrapped == (any ConnectAnalyticEvent) {
    func isEqual(to other: (any ConnectAnalyticEvent)?) -> Bool {
        if self == nil && other == nil {
            return true
        }
        guard let self, let other else {
            return false
        }
        return self.isEqual(to: other)
    }
}

extension Array where Element == (any ConnectAnalyticEvent) {
    func isEqual(to other: [any ConnectAnalyticEvent]) -> Bool {
        guard count == other.count else {
            return false
        }

        return zip(self, other).allSatisfy { $0.isEqual(to: $1) }
    }
}

func XCTAssertEqual(_ actual: (any ConnectAnalyticEvent)?,
                    _ expected: (any ConnectAnalyticEvent)?,
                    _ message: String? = nil,
                    file: StaticString = #file,
                    line: UInt = #line) {
    var failureMessage = "\(String(describing: actual)) does not match expected value \(String(describing: expected))"
    if let message {
        failureMessage = "\(failureMessage) - \(message)"
    }
    XCTAssert(expected.isEqual(to: actual), failureMessage, file: file, line: line)
}

func XCTAssertEqual(_ actual: [any ConnectAnalyticEvent],
                    _ expected: [any ConnectAnalyticEvent],
                    _ message: String? = nil,
                    file: StaticString = #file,
                    line: UInt = #line) {
    var failureMessage = "\(actual) does not match expected value \(expected)"
    if let message {
        failureMessage = "\(failureMessage) - \(message)"
    }
    XCTAssert(expected.isEqual(to: actual), failureMessage, file: file, line: line)
}
