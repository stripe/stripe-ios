//
//  PaymentContextFooterView.swift
//  Basic Integration
//
//  Created by Brian Dorfman on 10/13/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

import UIKit
import Stripe

class PaymentContextFooterView: UIView {

    var insetMargins: UIEdgeInsets = UIEdgeInsets.init(top: 10, left: 10, bottom: 10, right: 10)

    var text: String = "" {
        didSet {
            textLabel.text = text
        }
    }

    var theme: STPTheme = STPTheme.defaultTheme {
        didSet {
            textLabel.font = theme.smallFont
            textLabel.textColor = theme.secondaryForegroundColor
        }
    }

    fileprivate let textLabel = UILabel()

    convenience init(text: String) {
        self.init()
        textLabel.numberOfLines = 0
        textLabel.textAlignment = .left
        self.addSubview(textLabel)

        self.text = text
        textLabel.text = text

    }

    override func layoutSubviews() {
        textLabel.frame = self.bounds.inset(by: insetMargins)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        // Add 10 pt border on all sides
        var insetSize = size
        insetSize.width -= (insetMargins.left + insetMargins.right)
        insetSize.height -= (insetMargins.top + insetMargins.bottom)

        var newSize = textLabel.sizeThatFits(insetSize)

        newSize.width += (insetMargins.left + insetMargins.right)
        newSize.height += (insetMargins.top + insetMargins.bottom)

        return newSize
    }


}
