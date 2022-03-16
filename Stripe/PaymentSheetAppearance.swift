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
         
        static let `default` = Appearance()
        
        var font = Font()
        var shape = Shape()
        var color = Color()
        
        // MARK: Text
        struct Font {
            var sizeScaleFactor: CGFloat = 1.0

            var regular = UIFont.systemFont(ofSize: 12.0, weight: .regular)

            var medium  = UIFont.systemFont(ofSize: 12.0, weight: .medium)
            
            var semiBold = UIFont.systemFont(ofSize: 12.0, weight: .semibold)

            var bold = UIFont.systemFont(ofSize: 12.0, weight: .bold)
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
