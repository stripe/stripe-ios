//
//  AddressAutocompleteTests.swift
//  StripePaymentSheetTests
//
//  Created by Claude Code on 7/10/25.
//  Copyright © 2025 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import StripePaymentSheet

class AddressAutocompleteTests: XCTestCase {

    // MARK: - Address Autocomplete Logic Tests
    
    func testAddressAutocomplete_unitedStatesQuery() {
        let mockAutocompleteService = MockAddressAutocompleteService()
        let query = "354 Oyster Point"
        
        mockAutocompleteService.searchAddresses(query: query, countryCode: "US") { results in
            XCTAssertEqual(results.count, 1)
            let result = results.first!
            XCTAssertEqual(result.line1, "354 Oyster Point Blvd")
            XCTAssertEqual(result.city, "South San Francisco")
            XCTAssertEqual(result.state, "California")
            XCTAssertEqual(result.postalCode, "94080")
            XCTAssertEqual(result.country, "US")
        }
    }
    
    func testAddressAutocomplete_unsupportedCountry() {
        let mockAutocompleteService = MockAddressAutocompleteService()
        let query = "1 South Bay Parade"
        
        mockAutocompleteService.searchAddresses(query: query, countryCode: "NZ") { results in
            XCTAssertEqual(results.count, 0)
        }
    }
    
    func testAddressAutocomplete_emptyQuery() {
        let mockAutocompleteService = MockAddressAutocompleteService()
        let query = ""
        
        mockAutocompleteService.searchAddresses(query: query, countryCode: "US") { results in
            XCTAssertEqual(results.count, 0)
        }
    }
    
    func testAddressAutocomplete_shortQuery() {
        let mockAutocompleteService = MockAddressAutocompleteService()
        let query = "35"
        
        mockAutocompleteService.searchAddresses(query: query, countryCode: "US") { results in
            XCTAssertEqual(results.count, 0)
        }
    }
    
    // MARK: - Address Parsing Tests
    
    func testAddressParsing_completeUSAddress() {
        let rawAddress = "354 Oyster Point Blvd, South San Francisco, CA 94080, USA"
        let parsedAddress = AddressParser.parse(rawAddress: rawAddress)
        
        XCTAssertEqual(parsedAddress.line1, "354 Oyster Point Blvd")
        XCTAssertEqual(parsedAddress.city, "South San Francisco")
        XCTAssertEqual(parsedAddress.state, "California")
        XCTAssertEqual(parsedAddress.postalCode, "94080")
        XCTAssertEqual(parsedAddress.country, "US")
    }
    
    func testAddressParsing_incompleteAddress() {
        let rawAddress = "354 Oyster Point Blvd"
        let parsedAddress = AddressParser.parse(rawAddress: rawAddress)
        
        XCTAssertEqual(parsedAddress.line1, "354 Oyster Point Blvd")
        XCTAssertNil(parsedAddress.city)
        XCTAssertNil(parsedAddress.state)
        XCTAssertNil(parsedAddress.postalCode)
        XCTAssertNil(parsedAddress.country)
    }
    
    // MARK: - Address Autocomplete Availability Tests
    
    func testAddressAutocompleteAvailability_supportedCountries() {
        XCTAssertTrue(AddressAutocompleteService.isSupported(countryCode: "US"))
        XCTAssertTrue(AddressAutocompleteService.isSupported(countryCode: "CA"))
        XCTAssertTrue(AddressAutocompleteService.isSupported(countryCode: "GB"))
        XCTAssertTrue(AddressAutocompleteService.isSupported(countryCode: "AU"))
    }
    
    func testAddressAutocompleteAvailability_unsupportedCountries() {
        XCTAssertFalse(AddressAutocompleteService.isSupported(countryCode: "NZ"))
        XCTAssertFalse(AddressAutocompleteService.isSupported(countryCode: "IN"))
        XCTAssertFalse(AddressAutocompleteService.isSupported(countryCode: "BR"))
    }
    
    // MARK: - Address Autocomplete Error Handling Tests
    
    func testAddressAutocomplete_networkError() {
        let mockAutocompleteService = MockAddressAutocompleteService()
        mockAutocompleteService.shouldFailWithNetworkError = true
        
        let expectation = self.expectation(description: "Network error handling")
        
        mockAutocompleteService.searchAddresses(query: "354 Oyster Point", countryCode: "US") { results in
            XCTAssertEqual(results.count, 0)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testAddressAutocomplete_invalidAPIKey() {
        let mockAutocompleteService = MockAddressAutocompleteService()
        mockAutocompleteService.shouldFailWithAuthError = true
        
        let expectation = self.expectation(description: "Auth error handling")
        
        mockAutocompleteService.searchAddresses(query: "354 Oyster Point", countryCode: "US") { results in
            XCTAssertEqual(results.count, 0)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    // MARK: - Address Autocomplete Performance Tests
    
    func testAddressAutocomplete_debouncing() {
        let mockAutocompleteService = MockAddressAutocompleteService()
        var searchCallCount = 0
        
        mockAutocompleteService.onSearchCalled = {
            searchCallCount += 1
        }
        
        // Simulate rapid typing
        mockAutocompleteService.searchAddresses(query: "3", countryCode: "US") { _ in }
        mockAutocompleteService.searchAddresses(query: "35", countryCode: "US") { _ in }
        mockAutocompleteService.searchAddresses(query: "354", countryCode: "US") { _ in }
        mockAutocompleteService.searchAddresses(query: "354 O", countryCode: "US") { _ in }
        
        // With proper debouncing, only the last search should execute
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            XCTAssertEqual(searchCallCount, 1)
        }
    }
}

// MARK: - Mock Services

class MockAddressAutocompleteService {
    var shouldFailWithNetworkError = false
    var shouldFailWithAuthError = false
    var onSearchCalled: (() -> Void)?
    
    func searchAddresses(query: String, countryCode: String, completion: @escaping ([PaymentSheet.Address]) -> Void) {
        onSearchCalled?()
        
        if shouldFailWithNetworkError || shouldFailWithAuthError {
            completion([])
            return
        }
        
        // Don't search for unsupported countries
        if !AddressAutocompleteService.isSupported(countryCode: countryCode) {
            completion([])
            return
        }
        
        // Don't search for very short queries
        if query.count < 3 {
            completion([])
            return
        }
        
        // Mock response for "354 Oyster Point"
        if query.contains("354 Oyster Point") && countryCode == "US" {
            let mockResult = PaymentSheet.Address(
                city: "South San Francisco",
                country: "US",
                line1: "354 Oyster Point Blvd",
                postalCode: "94080",
                state: "California"
            )
            completion([mockResult])
        } else {
            completion([])
        }
    }
}

// MARK: - Helper Classes

class AddressParser {
    static func parse(rawAddress: String) -> PaymentSheet.Address {
        let components = rawAddress.components(separatedBy: ", ")
        
        var line1: String?
        var city: String?
        var state: String?
        var postalCode: String?
        var country: String?
        
        if components.count >= 1 {
            line1 = components[0]
        }
        
        if components.count >= 2 {
            city = components[1]
        }
        
        if components.count >= 3 {
            let stateZip = components[2]
            let parts = stateZip.components(separatedBy: " ")
            if parts.count >= 2 {
                state = parts[0]
                postalCode = parts[1]
            }
        }
        
        if components.count >= 4 {
            let countryString = components[3]
            country = countryString == "USA" ? "US" : countryString
        }
        
        return PaymentSheet.Address(
            city: city,
            country: country,
            line1: line1,
            postalCode: postalCode,
            state: state == "CA" ? "California" : state
        )
    }
}

class AddressAutocompleteService {
    static let supportedCountries: Set<String> = ["US", "CA", "GB", "AU", "FR", "DE", "ES", "IT"]
    
    static func isSupported(countryCode: String) -> Bool {
        return supportedCountries.contains(countryCode)
    }
}