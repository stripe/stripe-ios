//
//  ConsentBottomSheetModel.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 11/17/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

struct ConsentBottomSheetModel {
    let title: String
    let subtitle: String?
    let body: Body
    let extraNotice: String?
    let learnMore: String
    let cta: String

    struct Body: Decodable {
        let bullets: [FinancialConnectionsBulletPoint]
    }
}
