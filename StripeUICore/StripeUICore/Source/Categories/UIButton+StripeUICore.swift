//
//  UIButton+StripeUICore.swift
//  StripeUICore
//
//  Created by Cameron Sabol on 2/17/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

// swift-format-ignore: DontRepeatTypeInStaticProperties
@_spi(STP) extension UIButton {
    public class var doneButtonTitle: String {
        return STPLocalizedString("Done", "Done button title")
    }

    public class var editButtonTitle: String {
        return STPLocalizedString("Edit", "Button title to enter editing mode")
    }

}
