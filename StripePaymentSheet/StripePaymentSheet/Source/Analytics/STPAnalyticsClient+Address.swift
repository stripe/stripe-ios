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
                                               editDistance: nil)

        self.logAddressControllerEvent(event: .addressShow, addressAnalyticData: analyticData, apiClient: apiClient)
    }

    func logAddressCompleted(addressCountyCode: String, autoCompleteResultedSelected: Bool, editDistance: Int?, apiClient: STPAPIClient) {
        assert(apiClient.publishableKey?.nonEmpty != nil) // A publishable key is required to be set at this point so we can send it in our analytics payload
        let analyticData = AddressAnalyticData(addressCountryCode: addressCountyCode,
                                               autoCompleteResultedSelected: autoCompleteResultedSelected,
                                               editDistance: editDistance)

        self.logAddressControllerEvent(event: .addressCompleted, addressAnalyticData: analyticData, apiClient: apiClient)
    }
}

struct AddressAnalyticData {
    let addressCountryCode: String
    let autoCompleteResultedSelected: Bool?
    let editDistance: Int?

    var analyticsPayload: [String: Any?] {
        return ["address_country_code": addressCountryCode,
                "auto_complete_result_selected": autoCompleteResultedSelected,
                "edit_distance": editDistance, ]
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
