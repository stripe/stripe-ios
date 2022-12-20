//
//  STPCard+BasicUI.swift
//  StripeiOS
//
//  Created by David Estes on 6/30/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

extension STPCard: STPPaymentOption {
    // MARK: - STPPaymentOption
    @objc public var image: UIImage {
        return STPImageLibrary.cardBrandImage(for: brand)
    }

    @objc public var templateImage: UIImage {
        return STPImageLibrary.templatedBrandImage(for: brand)
    }

    @objc public var label: String {
        let brand = STPCard.string(from: self.brand)
        return "\(brand) \(last4 )"
    }

    @objc public var isReusable: Bool {
        return true
    }
}
