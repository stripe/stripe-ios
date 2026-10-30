//
//  AutoCompleteViewControllerTests.swift
//  StripePaymentSheetTests
//
//  Created by Joyce Qin on 10/28/26.
//

import Contacts
import MapKit
import OHHTTPStubs
import OHHTTPStubsSwift
import XCTest

@testable import StripePaymentSheet

#if !os(visionOS)
class AutoCompleteViewControllerTests: XCTestCase {
    @MainActor
    func testAutocompleteFallsBackToMapKitWhenSuggestionsFail() async throws {
        // Given an autocomplete request that fails
        let autocompleteRequested = expectation(description: "Autocomplete suggestions requested")
        let autocompleteStub = stub(condition: isPath("/v1/elements/address/autocomplete")) { _ in
            autocompleteRequested.fulfill()
            return HTTPStubsResponse(jsonObject: ["error": ["message": "Autocomplete unavailable"]], statusCode: 400, headers: nil)
        }
        defer { HTTPStubs.removeStub(autocompleteStub) }

        var configuration = AddressViewController.Configuration()
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_123")

        // When the controller fetches suggestions for the initial search text
        let viewController = AutoCompleteViewController(
            configuration: configuration,
            initialLine1Text: "354 Oyster Point Blvd, South San Francisco, CA",
            selectedCountry: "US"
        )
        await fulfillment(of: [autocompleteRequested], timeout: 5)

        // Then Apple's service supplies the displayed suggestions
        let deadline = Date().addingTimeInterval(30)
        while viewController.currentSource != "apple" && Date() < deadline {
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTAssertEqual(viewController.currentSource, "apple")
        XCTAssertFalse(viewController.results.isEmpty)
        XCTAssertTrue(viewController.results.allSatisfy { $0 is MKLocalSearchCompletion })
    }

    @MainActor
    func testSelectingSuggestionFallsBackToMapKitWhenAddressDetailsFail() async throws {
        // Given a suggestion whose address details request fails
        let detailsStub = stub(condition: isPath("/v1/elements/address/details")) { _ in
            HTTPStubsResponse(jsonObject: ["error": ["message": "Address details unavailable"]], statusCode: 400, headers: nil)
        }
        defer { HTTPStubs.removeStub(detailsStub) }

        var configuration = AddressViewController.Configuration()
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        let viewController = AutoCompleteViewController(
            configuration: configuration,
            initialLine1Text: nil,
            selectedCountry: "US"
        )
        viewController.currentSource = "google"
        viewController.results = [
            try XCTUnwrap(AddressSuggestion.decodedObject(fromAPIResponse: [
                "display_data": [
                    "title": "354 Oyster Point Blvd",
                    "subtitle": "South San Francisco, CA 94080",
                    "matches": [],
                ],
                "place_id": "place_123",
            ])),
        ]

        // ...and MapKit can resolve the suggestion to a full address
        let postalAddress = CNMutablePostalAddress()
        postalAddress.street = "354 Oyster Point Blvd"
        postalAddress.city = "South San Francisco"
        postalAddress.state = "CA"
        postalAddress.postalCode = "94080"
        postalAddress.isoCountryCode = "US"
        let mapItem = MockAddressMapItem()
        mapItem.addressPlacemark = MockAddressPlacemark(
            coordinate: CLLocationCoordinate2D(latitude: 37.665, longitude: -122.384),
            postalAddress: postalAddress
        )
        let mapKitSearched = expectation(description: "MapKit searches for the selected suggestion")
        viewController.searchMapKit = { request in
            XCTAssertEqual(request.naturalLanguageQuery, "354 Oyster Point Blvd, South San Francisco, CA 94080")
            XCTAssertEqual(request.resultTypes, .address)
            mapKitSearched.fulfill()
            return [mapItem]
        }

        let addressSelected = expectation(description: "Delegate receives the MapKit address")
        let delegate = AddressSelectionDelegate { address in
            XCTAssertEqual(address?.line1, "354 Oyster Point Blvd")
            XCTAssertEqual(address?.city, "South San Francisco")
            XCTAssertEqual(address?.state, "CA")
            XCTAssertEqual(address?.postalCode, "94080")
            XCTAssertEqual(address?.country, "US")
            XCTAssertNil(address?.line2)
            addressSelected.fulfill()
        }
        viewController.delegate = delegate

        // When the user selects the suggestion
        viewController.tableView(viewController.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))

        // Then MapKit resolves it and the delegate receives the populated address
        await fulfillment(of: [mapKitSearched, addressSelected], timeout: 5)
    }
}

private final class AddressSelectionDelegate: AutoCompleteViewControllerDelegate {
    let onSelectAddress: (PaymentSheet.Address?) -> Void

    init(onSelectAddress: @escaping (PaymentSheet.Address?) -> Void) {
        self.onSelectAddress = onSelectAddress
    }

    func didSelectAddress(_ address: PaymentSheet.Address?) {
        onSelectAddress(address)
    }

    func didSelectManualEntry(_ line1: String) {
        XCTFail("Expected an autocomplete address selection")
    }
}

private final class MockAddressPlacemark: MKPlacemark {
    // MapKit search results include a name, but initializing a placemark with a postal address does not.
    override var name: String? { postalAddress?.street }
}

private final class MockAddressMapItem: MKMapItem {
    var addressPlacemark: MKPlacemark?

    override var placemark: MKPlacemark { addressPlacemark ?? super.placemark }
}

#endif
