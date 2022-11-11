//
//  UIView+Icon.swift
//  StripeUICore
//
//  Created by Eduardo Urias on 11/10/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) extension UIImageView {
    public convenience init(icon: UIImage) {
        self.init(image: icon)
        contentMode = .scaleAspectFit
        setContentHuggingPriority(.required, for: .horizontal)
    }
}
