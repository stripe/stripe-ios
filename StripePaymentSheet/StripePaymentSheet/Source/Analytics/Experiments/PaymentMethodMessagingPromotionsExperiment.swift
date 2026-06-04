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

    let layout: String

    var dimensions: [String: String] {
        ["in_app_elements_layout": layout]
    }

    init(
        elementsSession: STPElementsSession,
        layout: String
    ) {
        let assignment = elementsSession.experimentsData?.experimentAssignments[Self.experimentName]
        self.arbId = elementsSession.experimentsData?.arbId ?? ""
        self.group = assignment ?? .control
        self.layout = layout
    }
}
