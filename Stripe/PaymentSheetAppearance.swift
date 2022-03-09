//
//  PaymentDefaultSheetAppearance.swift
//  StripeiOS
//
//  Created by Nick Porter on 2/22/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeUICore

extension PaymentSheet {

    struct Appearance {
        
        var font = Font()
        var shape = Shape()
        var color = Color()
        
        // MARK: Text
        struct Font {
            var family = UIFont.systemFont(ofSize: 12)
            
            var sizeBase: CGFloat = 5.0
            
            var weightRegular = UIFont.Weight.regular

            var weightMedium  = UIFont.Weight.medium
            
            var weightBold = UIFont.Weight.bold
        }
        
        // MARK: Shape
        struct Shape {
            var cornerRadius: CGFloat = 6.0
            
            var componentBorderWidth: CGFloat = 1.0
            
            var componentShadow = Shadow()
            
            struct Shadow {
                var color = UIColor.black
                var alpha = Float(0.05)
                var offset = CGSize(width: 0, height: 2)
                var radius = Float(4)
                var spread = Float(0.0)
            }
        }
        
        // MARK: Colors
        
        struct Color {
            var primary = UIColor.systemBlue
            
            var background = CompatibleColor.systemBackground
            
            var componentBackground = UIColor.dynamic(light: CompatibleColor.systemBackground,
                                                      dark: CompatibleColor.secondarySystemBackground)
            
            var componentBorder = CompatibleColor.systemGray3
            
            var componentDivider = UIColor.red
            
            var text = CompatibleColor.label
            
            var textSecondary = CompatibleColor.secondaryLabel
            
            var componentBackgroundText = CompatibleColor.label
            
            var placeholderText = UIColor.red
            
            var icon = CompatibleColor.secondaryLabel
            
            var danger = UIColor.systemRed
        }
        
    }

}
