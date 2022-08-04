//
//  STPAnalyticsClient+Address.swift
//  StripeiOS
//
//  Created by Nick Porter on 7/25/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

extension STPAnalyticsClient {
    
    func logAddressControllerEvent(
        event: STPAnalyticEvent,
        addressAnalyticData: AddressAnalyticData?
    ) {
        var additionalParams = [:] as [String: Any]
        if isSimulatorOrTest {
            additionalParams["is_development"] = true
        }
        
        additionalParams["address_data_blob"] = addressAnalyticData?.analyticsPayload
        
        let analytic = AddressAnalytic(event: event,
                                       productUsage: productUsage,
                                       params: additionalParams)
        
        log(analytic: analytic)
    }

    // MARK: - Address

    func logAddressShow(defaultCountryCode: String) {
        let analyticData = AddressAnalyticData(addressCountryCode: defaultCountryCode,
                                               autoCompleteResultedSelected: nil,
                                               editDistance: nil)
        
        self.logAddressControllerEvent(event: .adddressShow, addressAnalyticData: analyticData)
    }

    func logAddressCompleted(addressCountyCode: String, autoCompleteResultedSelected: Bool, editDistance: Int?) {
        let analyticData = AddressAnalyticData(addressCountryCode: addressCountyCode,
                                               autoCompleteResultedSelected: autoCompleteResultedSelected,
                                               editDistance: editDistance)
        
        self.logAddressControllerEvent(event: .addressCompleted, addressAnalyticData: analyticData)
    }
}

struct AddressAnalyticData {
    let addressCountryCode: String
    let autoCompleteResultedSelected: Bool?
    let editDistance: Int?
    
    var analyticsPayload: [String: Any?] {
        return ["address_country_code": addressCountryCode,
                "auto_complete_result_selected": autoCompleteResultedSelected,
                "edit_distance": editDistance]
    }
}

extension PaymentSheet.Address {
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
    let productUsage: Set<String>
    let params: [String : Any]
}
