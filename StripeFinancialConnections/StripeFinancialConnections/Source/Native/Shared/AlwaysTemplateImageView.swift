//
//  AlwaysTemplateImageView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 11/1/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

// A simple `UIImageView` subclass that ensures that every image that
// is set is marked as `alwaysTemplate` so the `image` tint color could
// be adjusted.
//
// This is helpful when images are returned from backend and we want to tint them.
final class AlwaysTemplateImageView: UIImageView {

    init(tintColor: UIColor) {
        super.init(image: nil)
        self.tintColor = tintColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var image: UIImage? {
        get {
            return super.image
        }
        set {
            super.image = newValue?.withRenderingMode(.alwaysTemplate)
        }
    }
}
