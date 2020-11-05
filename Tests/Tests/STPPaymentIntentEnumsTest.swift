//
//  STPPaymentIntentEnumsTest.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 9/28/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import XCTest

@testable import Stripe

class STPPaymentIntentEnumsTest: XCTestCase {

  func textStatusFromString() {

    XCTAssertEqual(
      STPPaymentIntentStatus.status(from: "requires_payment_method"),
      .requiresPaymentMethod)
    XCTAssertEqual(
      STPPaymentIntentStatus.status(from: "REQUIRES_PAYMENT_METHOD"),
      .requiresPaymentMethod)

    XCTAssertEqual(
      STPPaymentIntentStatus.status(from: "requires_confirmation"),
      .requiresConfirmation)
    XCTAssertEqual(
      STPPaymentIntentStatus.status(from: "REQUIRES_CONFIRMATION"),
      .requiresConfirmation)

    XCTAssertEqual(
      STPPaymentIntentStatus.status(from: "requires_action"),
      .requiresAction)
    XCTAssertEqual(
      STPPaymentIntentStatus.status(from: "REQUIRES_ACTION"),
      .requiresAction)

    XCTAssertEqual(
      STPPaymentIntentStatus.status(from: "processing"),
      .processing)
    XCTAssertEqual(
      STPPaymentIntentStatus.status(from: "PROCESSING"),
      .processing)

    XCTAssertEqual(
      STPPaymentIntentStatus.status(from: "succeeded"),
      .succeeded)
    XCTAssertEqual(
      STPPaymentIntentStatus.status(from: "SUCCEEDED"),
      .succeeded)

    XCTAssertEqual(
      STPPaymentIntentStatus.status(from: "requires_capture"),
      .requiresCapture)
    XCTAssertEqual(
      STPPaymentIntentStatus.status(from: "REQUIRES_CAPTURE"),
      .requiresCapture)

    XCTAssertEqual(
      STPPaymentIntentStatus.status(from: "canceled"),
      .canceled)
    XCTAssertEqual(
      STPPaymentIntentStatus.status(from: "CANCELED"),
      .canceled)

    XCTAssertEqual(
      STPPaymentIntentStatus.status(from: "garbage"),
      .unknown)
    XCTAssertEqual(
      STPPaymentIntentStatus.status(from: "GARBAGE"),
      .unknown)
  }

  func testCaptureMethodFromString() {
    XCTAssertEqual(
      STPPaymentIntentCaptureMethod.captureMethod(from: "manual"),
      .manual)
    XCTAssertEqual(
      STPPaymentIntentCaptureMethod.captureMethod(from: "MANUAL"),
      .manual)

    XCTAssertEqual(
      STPPaymentIntentCaptureMethod.captureMethod(from: "automatic"),
      .automatic)
    XCTAssertEqual(
      STPPaymentIntentCaptureMethod.captureMethod(from: "AUTOMATIC"),
      .automatic)

    XCTAssertEqual(
      STPPaymentIntentCaptureMethod.captureMethod(from: "garbage"),
      .unknown)
    XCTAssertEqual(
      STPPaymentIntentCaptureMethod.captureMethod(from: "GARBAGE"),
      .unknown)
  }

  func testConfirmationMethodFromString() {
    XCTAssertEqual(
      STPPaymentIntentConfirmationMethod.confirmationMethod(from: "automatic"),
      .automatic)
    XCTAssertEqual(
      STPPaymentIntentConfirmationMethod.confirmationMethod(from: "AUTOMATIC"),
      .automatic)

    XCTAssertEqual(
      STPPaymentIntentConfirmationMethod.confirmationMethod(from: "manual"),
      .manual)
    XCTAssertEqual(
      STPPaymentIntentConfirmationMethod.confirmationMethod(from: "MANUAL"),
      .manual)

    XCTAssertEqual(
      STPPaymentIntentConfirmationMethod.confirmationMethod(from: "garbage"),
      .unknown)
    XCTAssertEqual(
      STPPaymentIntentConfirmationMethod.confirmationMethod(from: "GARBAGE"),
      .unknown)
  }

  func testSetupFutureUsageFromString() {
    XCTAssertEqual(
      STPPaymentIntentSetupFutureUsage(string: "on_session"),
      .onSession)
    XCTAssertEqual(
      STPPaymentIntentSetupFutureUsage(string: "ON_SESSION"),
      .onSession)

    XCTAssertEqual(
      STPPaymentIntentSetupFutureUsage(string: "off_session"),
      .offSession)
    XCTAssertEqual(
      STPPaymentIntentSetupFutureUsage(string: "OFF_SESSION"),
      .offSession)

    XCTAssertEqual(
      STPPaymentIntentSetupFutureUsage(string: "garbage"),
      .unknown)
    XCTAssertEqual(
      STPPaymentIntentSetupFutureUsage(string: "GARBAGE"),
      .unknown)
  }
}
