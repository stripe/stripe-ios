//
//  PaymentMethodMessagingPromotionsExperiment.swift
//  StripePaymentSheet
//
//  Created by George Birch on 5/4/26.
//

@_spi(STP) import StripePayments

struct PaymentMethodMessagingPromotionsExperiment {
    static let experimentName = "ocs_mobile_payment_method_messaging_promotions"

    let group: ExperimentGroup

    let selectedPaymentMethodType: String?
    let promotionDisplayedSuccessfully: Bool?
    let layout: String?

    var dimensionsDictionary: [String: String] {
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
        self.group = assignment ?? .control
        self.selectedPaymentMethodType = selectedPaymentMethodType
        self.promotionDisplayedSuccessfully = promotionDisplayedSuccessfully
        self.layout = layout
    }

    init(
        group: ExperimentGroup,
        selectedPaymentMethodType: String? = nil,
        promotionDisplayedSuccessfully: Bool? = nil,
        layout: String? = nil
    ) {
        self.group = group
        self.selectedPaymentMethodType = selectedPaymentMethodType
        self.promotionDisplayedSuccessfully = promotionDisplayedSuccessfully
        self.layout = layout
    }

    var isInTreatment: Bool {
        group == .treatment
    }
}
