//
//  PaymentIntentParamsTest.swift
//  StripeApplePayTests
//
//  Created by David Estes on 12/26/24.
//  Copyright © 2024 Stripe, Inc. All rights reserved.
//

import XCTest
@testable @_spi(STP) import StripeApplePay

class PaymentIntentParamsTest: XCTestCase {
    
    func testClientSecretValidation() {
        // Test invalid client secrets
        XCTAssertFalse(
            StripeAPI.PaymentIntentParams.isClientSecretValid("pi_12345"),
            "'pi_12345' is not a valid client secret."
        )
        XCTAssertFalse(
            StripeAPI.PaymentIntentParams.isClientSecretValid("pi_12345_secret_"),
            "'pi_12345_secret_' is not a valid client secret."
        )
        XCTAssertFalse(
            StripeAPI.PaymentIntentParams.isClientSecretValid(
                "pi_a1b2c3_secret_x7y8z9pi_a1b2c3_secret_x7y8z9"
            ),
            "'pi_a1b2c3_secret_x7y8z9pi_a1b2c3_secret_x7y8z9' is not a valid client secret."
        )
        XCTAssertFalse(
            StripeAPI.PaymentIntentParams.isClientSecretValid("seti_a1b2c3_secret_x7y8z9"),
            "'seti_a1b2c3_secret_x7y8z9' is not a valid client secret."
        )
        
        // Test valid regular client secrets
        XCTAssertTrue(
            StripeAPI.PaymentIntentParams.isClientSecretValid("pi_a1b2c3_secret_x7y8z9"),
            "'pi_a1b2c3_secret_x7y8z9' is a valid client secret."
        )
        XCTAssertTrue(
            StripeAPI.PaymentIntentParams.isClientSecretValid(
                "pi_1CkiBMLENEVhOs7YMtUehLau_secret_s4O8SDh7s6spSmHDw1VaYPGZA"
            ),
            "'pi_1CkiBMLENEVhOs7YMtUehLau_secret_s4O8SDh7s6spSmHDw1VaYPGZA' is a valid client secret."
        )
        
        // Test valid scoped client secrets
        XCTAssertTrue(
            StripeAPI.PaymentIntentParams.isClientSecretValid("pi_3RddVUHh8VvNDQ8j1CFgLC0y_scoped_secret_JouqJt9ahCKgh6B9r6"),
            "'pi_3RddVUHh8VvNDQ8j1CFgLC0y_scoped_secret_JouqJt9ahCKgh6B9r6' is a valid scoped client secret."
        )
        XCTAssertTrue(
            StripeAPI.PaymentIntentParams.isClientSecretValid("pi_1CkiBMLENEVhOs7YMtUehLau_scoped_secret_s4O8SDh7s6spSmHDw1VaYPGZA"),
            "'pi_1CkiBMLENEVhOs7YMtUehLau_scoped_secret_s4O8SDh7s6spSmHDw1VaYPGZA' is a valid scoped client secret."
        )
        
        // Test invalid scoped client secrets
        XCTAssertFalse(
            StripeAPI.PaymentIntentParams.isClientSecretValid("pi_12345_scoped_secret_"),
            "'pi_12345_scoped_secret_' is not a valid client secret."
        )
    }
    
    func testIdFromClientSecret() {
        // Test regular client secrets
        XCTAssertEqual(
            StripeAPI.PaymentIntent.id(fromClientSecret: "pi_123_secret_XYZ"),
            "pi_123"
        )
        XCTAssertEqual(
            StripeAPI.PaymentIntent.id(
                fromClientSecret: "pi_123_secret_RandomlyContains_secret_WhichIsFine"
            ),
            "pi_123"
        )
        XCTAssertEqual(
            StripeAPI.PaymentIntent.id(fromClientSecret: "pi_1CkiBMLENEVhOs7YMtUehLau_secret_s4O8SDh7s6spSmHDw1VaYPGZA"),
            "pi_1CkiBMLENEVhOs7YMtUehLau"
        )
        
        // Test scoped client secrets
        XCTAssertEqual(
            StripeAPI.PaymentIntent.id(fromClientSecret: "pi_3RddVUHh8VvNDQ8j1CFgLC0y_scoped_secret_JouqJt9ahCKgh6B9r6"),
            "pi_3RddVUHh8VvNDQ8j1CFgLC0y"
        )
        XCTAssertEqual(
            StripeAPI.PaymentIntent.id(fromClientSecret: "pi_1CkiBMLENEVhOs7YMtUehLau_scoped_secret_s4O8SDh7s6spSmHDw1VaYPGZA"),
            "pi_1CkiBMLENEVhOs7YMtUehLau"
        )
        
        // Test invalid client secrets
        XCTAssertNil(StripeAPI.PaymentIntent.id(fromClientSecret: ""))
        XCTAssertNil(StripeAPI.PaymentIntent.id(fromClientSecret: "po_123_secret_HasBadPrefix"))
        XCTAssertNil(StripeAPI.PaymentIntent.id(fromClientSecret: "MissingSentinalForSplitting"))
        XCTAssertNil(StripeAPI.PaymentIntent.id(fromClientSecret: "pi_123_scoped_secret_"))
    }
} 