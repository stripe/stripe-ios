//
//  UIButton+StripeUICore.swift
//  StripeUICore
//
//  Created by Cameron Sabol on 2/17/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) public extension UIButton {

    class var doneButtonTitle: String {
        return STPLocalizedString("Done", "Done button title")
    }

}
