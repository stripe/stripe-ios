//
//  Images.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 5/19/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

// TODO(yuki|https://jira.corp.stripe.com/browse/MOBILESDK-309): Refactor STPImageLibrary's images to live here as well

/// The canonical set of all image files in the SDK.
/// This helps us avoid duplicates and automatically test that all images load properly
/// Raw value is the image file name. We use snake case to make long names easier to read.
enum Image: String, CaseIterable {
    /// https://developer.apple.com/apple-pay/marketing/
    case apple_pay_mark = "apple_pay_mark"

    // Payment Method Type images
    case pm_type_card = "icon-pm-card"
    case pm_type_ideal = "icon-pm-ideal"
    case pm_type_bancontact = "icon-pm-bancontact"
    case pm_type_sofort = "icon-pm-sofort"
    case pm_type_sepa = "icon-pm-sepa"

    // Icons/symbols
    case icon_checkmark = "icon_checkmark"
    case icon_chevron_left = "icon_chevron_left"
    case icon_chevron_down = "icon_chevron_down"
    case icon_lock = "icon_lock"
    case icon_plus = "icon_plus"
    case icon_x = "icon_x"

    func makeImage(template: Bool = false) -> UIImage {
        return STPImageLibrary.safeImageNamed(
            self.rawValue,
            templateIfAvailable: template
        )
    }
}
