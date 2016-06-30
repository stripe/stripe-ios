//
//  Buttons.swift
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 4/25/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

import UIKit
import Stripe

class HighlightingButton: UIButton {
    var highlightColor = UIColor(white: 0, alpha: 0.05)

    convenience init(highlightColor: UIColor) {
        self.init()
        self.highlightColor = highlightColor
    }

    override var highlighted: Bool {
        didSet {
            if highlighted {
                self.backgroundColor = self.highlightColor
            } else {
                self.backgroundColor = UIColor.clearColor()
            }
        }
    }
}

class BuyButton: HighlightingButton {
    var disabledColor = UIColor.lightGrayColor()
    var enabledColor = UIColor(red:0.22, green:0.65, blue:0.91, alpha:1.00)

    override var enabled: Bool {
        didSet {
            let color = enabled ? enabledColor : disabledColor
            self.setTitleColor(color, forState: .Normal)
            self.layer.borderColor = color.CGColor
            self.highlightColor = color.colorWithAlphaComponent(0.5)
        }
    }

    convenience init(enabled: Bool, theme: STPTheme) {
        self.init()
        self.layer.borderWidth = 2
        self.layer.cornerRadius = 10
        self.setTitle("Buy", forState: .Normal)
        self.disabledColor = theme.secondaryForegroundColor
        self.enabledColor = theme.accentColor
        self.enabled = enabled
    }
}
