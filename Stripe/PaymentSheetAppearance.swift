//
//  PaymentDefaultSheetAppearance.swift
//  StripeiOS
//
//  Created by Nick Porter on 2/22/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeUICore

@_spi(STP) public extension PaymentSheet {

    struct Appearance {
         
        static let `default` = Appearance()
        
        public init() {}
        
        var font = Font()
        var shape = Shape()
        public var color = Color()
        
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
        
        public struct Color {
            public var primary = UIColor.systemBlue
            
            public var background = CompatibleColor.systemBackground
            
            public var componentBackground = UIColor.dynamic(light: CompatibleColor.systemBackground,
                                                      dark: CompatibleColor.secondarySystemBackground)
            
            public var componentBorder = CompatibleColor.systemGray3
            
            public var componentDivider = UIColor.red
            
            public var text = CompatibleColor.label
            
            public var textSecondary = CompatibleColor.secondaryLabel
            
            public var componentBackgroundText = CompatibleColor.label
            
            public var placeholderText = UIColor.red
            
            public var icon = CompatibleColor.secondaryLabel
            
            public var danger = UIColor.systemRed
        }
        
    }

}
