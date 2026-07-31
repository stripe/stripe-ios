//
//  STPAnalyticsClient+Address.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 7/25/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

extension STPAnalyticsClient {

    func logAddressControllerEvent(
        event: STPAnalyticEvent,
        addressAnalyticData: AddressAnalyticData?,
        apiClient: STPAPIClient
    ) {
        var additionalParams = [:] as [String: Any]
        additionalParams["address_data_blob"] = addressAnalyticData?.analyticsPayload

        let analytic = AddressAnalytic(event: event,
                                       params: additionalParams)

        log(analytic: analytic, apiClient: apiClient)
    }

    // MARK: - Address

    func logAddressShow(defaultCountryCode: String, apiClient: STPAPIClient) {
        assert(apiClient.publishableKey?.nonEmpty != nil) // A publishable key is required to be set at this point so we can send it in our analytics payload
        let analyticData = AddressAnalyticData(addressCountryCode: defaultCountryCode,
                                               autoCompleteResultedSelected: nil,
                                               editDistance: nil,
                                               timeToComplete: nil)

        self.logAddressControllerEvent(event: .addressShow, addressAnalyticData: analyticData, apiClient: apiClient)
    }

    func logAddressCompleted(addressCountyCode: String, autoCompleteResultedSelected: Bool, editDistance: Int?, timeToComplete: TimeInterval?, apiClient: STPAPIClient) {
        assert(apiClient.publishableKey?.nonEmpty != nil) // A publishable key is required to be set at this point so we can send it in our analytics payload
        let analyticData = AddressAnalyticData(addressCountryCode: addressCountyCode,
                                               autoCompleteResultedSelected: autoCompleteResultedSelected,
                                               editDistance: editDistance,
                                               timeToComplete: timeToComplete)

        self.logAddressControllerEvent(event: .addressCompleted, addressAnalyticData: analyticData, apiClient: apiClient)
    }

    func logBillingAddressCompleted(addressCountryCode: String, autoCompleteResultedSelected: Bool, editDistance: Int?, timeToComplete: TimeInterval?, apiClient: STPAPIClient) {
        assert(apiClient.publishableKey?.nonEmpty != nil) // A publishable key is required to be set at this point so we can send it in our analytics payload
        let analyticData = AddressAnalyticData(addressCountryCode: addressCountryCode,
                                               autoCompleteResultedSelected: autoCompleteResultedSelected,
                                               editDistance: editDistance,
                                               timeToComplete: timeToComplete)

        self.logAddressControllerEvent(event: .mcbillingAddressCompleted, addressAnalyticData: analyticData, apiClient: apiClient)
    }

    func logCustomerSheetBillingAddressCompleted(addressCountryCode: String, autoCompleteResultedSelected: Bool, editDistance: Int?, timeToComplete: TimeInterval?, apiClient: STPAPIClient) {
        assert(apiClient.publishableKey?.nonEmpty != nil) // A publishable key is required to be set at this point so we can send it in our analytics payload
        let analyticData = AddressAnalyticData(addressCountryCode: addressCountryCode,
                                               autoCompleteResultedSelected: autoCompleteResultedSelected,
                                               editDistance: editDistance,
                                               timeToComplete: timeToComplete)

        self.logAddressControllerEvent(event: .csbillingAddressCompleted, addressAnalyticData: analyticData, apiClient: apiClient)
    }

    // MARK: - Autocomplete

    func logAddressAutocompleteStart(sessionToken: String, apiClient: STPAPIClient) {
        assert(apiClient.publishableKey?.nonEmpty != nil) // A publishable key is required to be set at this point so we can send it in our analytics payload
        log(analytic: AddressAnalytic(event: .addressAutocompleteStart, params: [
            "autocomplete_session_token": sessionToken,
        ]), apiClient: apiClient)
    }

    func logAddressAutocompleteSuggestions(resultCount: Int, autocompleteSessionToken: String, source: String, sessionElapsed: TimeInterval, timeToFetch: TimeInterval?, apiClient: STPAPIClient) {
        assert(apiClient.publishableKey?.nonEmpty != nil) // A publishable key is required to be set at this point so we can send it in our analytics payload
        var params: [String: Any] = [
            "result_count": resultCount,
            "autocomplete_session_token": autocompleteSessionToken,
            "source": source,
            "session_elapsed": sessionElapsed,
        ]
        if let timeToFetch { params["time_to_fetch"] = timeToFetch }
        log(analytic: AddressAnalytic(event: .addressAutocompleteSuggestions, params: params), apiClient: apiClient)
    }

    func logAddressAutocompleteSelected(queryLength: Int, autocompleteSessionToken: String, source: String, sessionElapsed: TimeInterval, placeId: String?, timeToFetch: TimeInterval?, apiClient: STPAPIClient) {
        assert(apiClient.publishableKey?.nonEmpty != nil) // A publishable key is required to be set at this point so we can send it in our analytics payload
        var params: [String: Any] = [
            "query_length": queryLength,
            "autocomplete_session_token": autocompleteSessionToken,
            "source": source,
            "session_elapsed": sessionElapsed,
        ]
        if let placeId { params["place_id"] = placeId }
        if let timeToFetch { params["time_to_fetch"] = timeToFetch }
        log(analytic: AddressAnalytic(event: .addressAutocompleteSelected, params: params), apiClient: apiClient)
    }

    func logAddressAutocompleteError(error: Error, autocompleteSessionToken: String, duration: TimeInterval, apiClient: STPAPIClient) {
        assert(apiClient.publishableKey?.nonEmpty != nil) // A publishable key is required to be set at this point so we can send it in our analytics payload
        var params = error.serializeForV1Analytics()
        params["autocomplete_session_token"] = autocompleteSessionToken
        params["duration"] = duration
        log(analytic: AddressAnalytic(event: .addressAutocompleteError, params: params), apiClient: apiClient)
    }
}

struct AddressAnalyticData {
    let addressCountryCode: String
    let autoCompleteResultedSelected: Bool?
    let editDistance: Int?
    let timeToComplete: TimeInterval?

    var analyticsPayload: [String: Any?] {
        return ["address_country_code": addressCountryCode,
                "auto_complete_result_selected": autoCompleteResultedSelected,
                "edit_distance": editDistance,
                "time_to_complete": timeToComplete,]
    }
}

extension PaymentSheet.Address {
    init(from address: AddressViewController.AddressDetails.Address) {
        line1 = address.line1
        line2 = address.line2
        city = address.city
        state = address.state
        country = address.country
        postalCode = address.postalCode
    }

    func editDistance(from otherAddress: PaymentSheet.Address) -> Int {
        var editDistance = 0
        editDistance += (line1 ?? "").editDistance(to: otherAddress.line1 ?? "")
        editDistance += (line2 ?? "").editDistance(to: otherAddress.line2 ?? "")
        editDistance += (city ?? "").editDistance(to: otherAddress.city ?? "")
        editDistance += (state ?? "").editDistance(to: otherAddress.state ?? "")
        editDistance += (country ?? "").editDistance(to: otherAddress.country ?? "")
        editDistance += (postalCode ?? "").editDistance(to: otherAddress.postalCode ?? "")

        return editDistance
    }
}

struct AddressAnalytic: Analytic {
    let event: STPAnalyticEvent
    let params: [String: Any]
}
