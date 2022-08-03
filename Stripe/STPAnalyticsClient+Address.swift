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

    // MARK: - Address

    func logAddressShow(defaultCountryCode: String) {
        self.logPaymentSheetEvent(event: .adddressShow, addressAnalyticData: AddressAnalyticData(addressCountryCode: defaultCountryCode, autoCompleteResultedSelected: nil, editDistance: nil))
    }

    func logAddressCompleted(addressCountyCode: String, autoCompleteResultedSelected: Bool, editDistance: Int?) {
        self.logPaymentSheetEvent(event: .addressCompleted,
                                  addressAnalyticData: AddressAnalyticData(addressCountryCode: addressCountyCode,
                                                                           autoCompleteResultedSelected: autoCompleteResultedSelected,
                                                                           editDistance: editDistance))
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
