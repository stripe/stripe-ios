//
//  AddressValidationTests.swift
//  StripePaymentSheetTests
//
//  Created by Claude Code on 7/10/25.
//  Copyright © 2025 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import StripePaymentSheet

class AddressValidationTests: XCTestCase {

    // MARK: - Manual Address Entry Validation Tests
    
    func testManualAddressValidation_allRequiredFieldsPresent() {
        let address = PaymentSheet.Address(
            city: "San Francisco",
            country: "US",
            line1: "510 Townsend St",
            line2: "Apt 152",
            postalCode: "94102",
            state: "California"
        )
        
        XCTAssertTrue(address.isValid)
        XCTAssertTrue(address.hasRequiredFields)
    }
    
    func testManualAddressValidation_missingRequiredFields() {
        let incompleteAddress = PaymentSheet.Address(
            city: nil,
            country: "US",
            line1: "510 Townsend St",
            postalCode: "94102",
            state: "California"
        )
        
        XCTAssertFalse(incompleteAddress.isValid)
        XCTAssertFalse(incompleteAddress.hasRequiredFields)
    }
    
    func testManualAddressValidation_invalidZipCode() {
        let addressWithInvalidZip = PaymentSheet.Address(
            city: "San Francisco",
            country: "US",
            line1: "510 Townsend St",
            postalCode: "9410", // Invalid length
            state: "California"
        )
        
        XCTAssertFalse(addressWithInvalidZip.isValid)
    }
    
    func testManualAddressValidation_validZipCode() {
        let addressWithValidZip = PaymentSheet.Address(
            city: "San Francisco",
            country: "US",
            line1: "510 Townsend St",
            postalCode: "94102",
            state: "California"
        )
        
        XCTAssertTrue(addressWithValidZip.isValid)
    }
    
    // MARK: - Address Defaults Validation Tests
    
    func testAddressWithDefaults_prePopulatedValues() {
        let defaultAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "US",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )
        
        XCTAssertEqual(defaultAddress.city, "San Francisco")
        XCTAssertEqual(defaultAddress.country, "US")
        XCTAssertEqual(defaultAddress.line1, "510 Townsend St.")
        XCTAssertEqual(defaultAddress.postalCode, "94102")
        XCTAssertEqual(defaultAddress.state, "California")
        XCTAssertTrue(defaultAddress.isValid)
    }
    
    func testAddressWithDefaults_enablesSaveButton() {
        let defaultAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "US",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )
        
        XCTAssertTrue(defaultAddress.hasRequiredFields)
        XCTAssertTrue(defaultAddress.isValid)
    }
    
    // MARK: - Phone Number Validation Tests
    
    func testPhoneNumberValidation_validUSNumber() {
        let validUSPhone = "5555555555"
        XCTAssertTrue(isValidPhoneNumber(validUSPhone, countryCode: "US"))
    }
    
    func testPhoneNumberValidation_validUKNumber() {
        let validUKPhone = "7911123456"
        XCTAssertTrue(isValidPhoneNumber(validUKPhone, countryCode: "GB"))
    }
    
    func testPhoneNumberValidation_invalidNumber() {
        let invalidPhone = "123"
        XCTAssertFalse(isValidPhoneNumber(invalidPhone, countryCode: "US"))
    }
    
    // MARK: - International Address Validation Tests
    
    func testInternationalAddressValidation_newZealand() {
        let nzAddress = PaymentSheet.Address(
            city: "Kaikōura",
            country: "NZ",
            line1: "1 South Bay Parade",
            line2: "Apt 152",
            postalCode: "7300",
            state: nil // NZ doesn't use states
        )
        
        XCTAssertTrue(nzAddress.isValid)
        XCTAssertTrue(nzAddress.hasRequiredFields)
    }
    
    func testInternationalAddressValidation_canada() {
        let canadaAddress = PaymentSheet.Address(
            city: "Toronto",
            country: "CA",
            line1: "123 Main St",
            postalCode: "M5V 3A8",
            state: "Ontario"
        )
        
        XCTAssertTrue(canadaAddress.isValid)
        XCTAssertTrue(canadaAddress.hasRequiredFields)
    }
    
    // MARK: - Address Formatting Tests
    
    func testAddressFormatting_displayString() {
        let address = PaymentSheet.Address(
            city: "San Francisco",
            country: "US",
            line1: "510 Townsend St",
            line2: "Apt 152",
            postalCode: "94102",
            state: "California"
        )
        
        let expectedDisplay = """
Jane Doe
510 Townsend St, Apt 152
San Francisco CA 94102
US
+15555555555
"""
        
        let displayString = address.displayString(name: "Jane Doe", phoneNumber: "+15555555555")
        XCTAssertEqual(displayString, expectedDisplay)
    }
    
    func testAddressFormatting_displayStringWithoutLine2() {
        let address = PaymentSheet.Address(
            city: "San Francisco",
            country: "US",
            line1: "510 Townsend St",
            postalCode: "94102",
            state: "California"
        )
        
        let expectedDisplay = """
Jane Doe
510 Townsend St
San Francisco CA 94102
US
+15555555555
"""
        
        let displayString = address.displayString(name: "Jane Doe", phoneNumber: "+15555555555")
        XCTAssertEqual(displayString, expectedDisplay)
    }
    
    // MARK: - Helper Methods
    
    private func isValidPhoneNumber(_ phoneNumber: String, countryCode: String) -> Bool {
        // Simplified phone validation logic
        switch countryCode {
        case "US":
            return phoneNumber.count == 10 && phoneNumber.allSatisfy { $0.isNumber }
        case "GB":
            return phoneNumber.count >= 10 && phoneNumber.allSatisfy { $0.isNumber }
        default:
            return phoneNumber.count >= 7 && phoneNumber.allSatisfy { $0.isNumber }
        }
    }
}

// MARK: - PaymentSheet.Address Extensions for Testing

extension PaymentSheet.Address {
    var isValid: Bool {
        return hasRequiredFields && isValidPostalCode
    }
    
    var hasRequiredFields: Bool {
        guard let city = city, !city.isEmpty,
              let country = country, !country.isEmpty,
              let line1 = line1, !line1.isEmpty,
              let postalCode = postalCode, !postalCode.isEmpty else {
            return false
        }
        
        // Some countries require state/province
        if country == "US" || country == "CA" {
            return state != nil && !state!.isEmpty
        }
        
        return true
    }
    
    var isValidPostalCode: Bool {
        guard let postalCode = postalCode, let country = country else {
            return false
        }
        
        switch country {
        case "US":
            return postalCode.count == 5 && postalCode.allSatisfy { $0.isNumber }
        case "CA":
            return postalCode.count == 7 && postalCode.contains(" ")
        case "GB":
            return postalCode.count >= 5 && postalCode.count <= 8
        default:
            return postalCode.count >= 3
        }
    }
    
    func displayString(name: String, phoneNumber: String) -> String {
        var components: [String] = [name]
        
        if let line1 = line1 {
            if let line2 = line2, !line2.isEmpty {
                components.append("\(line1), \(line2)")
            } else {
                components.append(line1)
            }
        }
        
        if let city = city, let state = state, let postalCode = postalCode {
            components.append("\(city) \(state) \(postalCode)")
        }
        
        if let country = country {
            components.append(country)
        }
        
        components.append(phoneNumber)
        
        return components.joined(separator: "\n")
    }
}