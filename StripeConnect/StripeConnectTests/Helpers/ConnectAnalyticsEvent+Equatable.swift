//
//  ConnectAnalyticsEvent+Equatable.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 11/7/24.
//

@testable import StripeConnect
import XCTest

///*
// Because `any ConnectAnalyticEvent` does not conform to Equatable, we have to
// define some helpers for testing for equality.
// */
//
//extension ConnectAnalyticEvent {
//    func isEqual(to other: any ConnectAnalyticEvent) -> Bool {
//        guard let typedOther = other as? Self else {
//            return false
//        }
//        return typedOther == self
//    }
//}
//
//extension Array where Element == (any ConnectAnalyticEvent) {
//    func isEqual(to other: [any ConnectAnalyticEvent]) -> Bool {
//        guard count == other.count else {
//            return false
//        }
//
//        return zip(self, other).allSatisfy { $0.isEqual(to: $1) }
//    }
//}
//
//func XCTAssertEqual(_ actual: any ConnectAnalyticEvent,
//                    _ expected: any ConnectAnalyticEvent,
//                    _ message: String? = nil,
//                    file: StaticString = #file,
//                    line: UInt = #line) {
//    var failureMessage = "\(actual) does not match expected value \(expected)"
//    if let message {
//        failureMessage = "\(message)\n\(failureMessage)"
//    }
//    XCTAssert(expected.isEqual(to: actual), failureMessage, file: file, line: line)
//}
//
//func XCTAssertEqual(_ actual: [any ConnectAnalyticEvent],
//                    _ expected: [any ConnectAnalyticEvent],
//                    _ message: String? = nil,
//                    file: StaticString = #file,
//                    line: UInt = #line) {
//    var failureMessage = "\(actual) does not match expected value \(expected)"
//    if let message {
//        failureMessage = "\(message)\n\(failureMessage)"
//    }
//    XCTAssert(expected.isEqual(to: actual), failureMessage, file: file, line: line)
//}
