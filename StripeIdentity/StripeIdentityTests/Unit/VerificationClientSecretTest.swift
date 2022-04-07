//
//  VerificationClientSecretTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 3/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest

@testable import StripeIdentity

final class VerificationClientSecretTest: XCTestCase {

    func testValidSecrets() {
        verifySecret(secretString: "vi_abc123_secret_test_xyz456", expectedSessionId: "vi_abc123", expectedUrlToken: "xyz456")
        verifySecret(secretString: " vi_abc123_secret_test_xyz456 ", expectedSessionId: "vi_abc123", expectedUrlToken: "xyz456")
        verifySecret(secretString: "vi_abc123_secret_live_xyz456", expectedSessionId: "vi_abc123", expectedUrlToken: "xyz456")
        verifySecret(secretString: " vi_abc123_secret_live_xyz456 ", expectedSessionId: "vi_abc123", expectedUrlToken: "xyz456")
        verifySecret(secretString: "vs_abc123_secret_test_xyz456", expectedSessionId: "vs_abc123", expectedUrlToken: "xyz456")
        verifySecret(secretString: " vs_abc123_secret_test_xyz456 ", expectedSessionId: "vs_abc123", expectedUrlToken: "xyz456")
        verifySecret(secretString: "vs_abc123_secret_live_xyz456", expectedSessionId: "vs_abc123", expectedUrlToken: "xyz456")
        verifySecret(secretString: " vs_abc123_secret_live_xyz456 ", expectedSessionId: "vs_abc123", expectedUrlToken: "xyz456")
    }

    func testInvalidSecrets() {
        XCTAssertNil(VerificationClientSecret(string: ""))
        XCTAssertNil(VerificationClientSecret(string: "123"))
        XCTAssertNil(VerificationClientSecret(string: "vi_abc123_abc_xyz456"))
        XCTAssertNil(VerificationClientSecret(string: "viabc123secretxyz456"))
        XCTAssertNil(VerificationClientSecret(string: "vi__abc123_secret_xyz456"))
        XCTAssertNil(VerificationClientSecret(string: "vt_abc123_secret_xyz456"))
        XCTAssertNil(VerificationClientSecret(string: "vs_abc1-23_secret_xyz456"))
    }

    private func verifySecret(
        secretString: String,
        expectedSessionId: String,
        expectedUrlToken: String,
        file: StaticString = #file,
        line: UInt = #line) {
        guard let secret = VerificationClientSecret(string: secretString) else {
            return XCTFail("Invalid client secret")
        }

        XCTAssertEqual(
            secret.verificationSessionId,
            expectedSessionId,
            "`verificationSessionId` does not match",
            file: file,
            line: line
        )
        XCTAssertEqual(
            secret.urlToken,
            expectedUrlToken,
            "`urlToken` does not match",
            file: file,
            line: line
        )
    }
}
