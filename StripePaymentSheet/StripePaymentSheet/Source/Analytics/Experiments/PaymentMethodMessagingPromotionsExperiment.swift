//
//  PaymentMethodMessagingPromotionsExperiment.swift
//  StripePaymentSheet
//
//  Created by George Birch on 5/4/26.
//

@_spi(STP) import StripePayments

struct PaymentMethodMessagingPromotionsExperiment: LoggableExperiment {
    static let experimentName = "ocs_mobile_payment_method_messaging_promotions"

    let name: String = experimentName
    let arbId: String
    let group: ExperimentGroup

    let selectedPaymentMethodType: String?
    let promotionDisplayedSuccessfully: Bool?
    let layout: String?

    var dimensions: [String: String] {
        var dimensions: [String: String] = [:]
        if let selectedPaymentMethodType {
            dimensions["selected_payment_method_type"] = selectedPaymentMethodType
        }
        if let promotionDisplayedSuccessfully {
            dimensions["promotion_displayed_successfully"] = promotionDisplayedSuccessfully.description
        }
        if let layout {
            dimensions["in_app_elements_layout"] = layout
        }
        return dimensions
    }

    init(
        elementsSession: STPElementsSession,
        selectedPaymentMethodType: String? = nil,
        promotionDisplayedSuccessfully: Bool? = nil,
        layout: String? = nil
    ) {
        let assignment = elementsSession.experimentsData?.experimentAssignments[Self.experimentName]
        self.arbId = elementsSession.experimentsData?.arbId ?? ""
        self.group = assignment ?? .control
        self.selectedPaymentMethodType = selectedPaymentMethodType
        self.promotionDisplayedSuccessfully = promotionDisplayedSuccessfully
        self.layout = layout
    }

    init(
        arbId: String,
        group: ExperimentGroup,
        selectedPaymentMethodType: String? = nil,
        promotionDisplayedSuccessfully: Bool? = nil,
        layout: String? = nil
    ) {
        self.arbId = arbId
        self.group = group
        self.selectedPaymentMethodType = selectedPaymentMethodType
        self.promotionDisplayedSuccessfully = promotionDisplayedSuccessfully
        self.layout = layout
    }
}
