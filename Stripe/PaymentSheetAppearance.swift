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
         
        public static let `default` = Appearance()
        
        public init() {}
        
        public var font = Font()
        public var shape = Shape()
        public var color = Color()
        
        // MARK: Text
        public struct Font {
            public init() {}
            
            public var sizeScaleFactor: CGFloat = 1.0

            public var regular = UIFont.systemFont(ofSize: UIFont.labelFontSize, weight: .regular)
        }
        
        // MARK: Shape
        public struct Shape {
            public init() {}
            
            public var cornerRadius: CGFloat = 6.0
            
            public var componentBorderWidth: CGFloat = 1.0
            
            public var componentShadow = Shadow()
            
            public struct Shadow {
                public init() {}
                
                public init(color: UIColor, alpha: Float, offset: CGSize, radius: Float) {
                    self.color = color
                    self.alpha = alpha
                    self.offset = offset
                    self.radius = radius
                }
                
                public var color = UIColor.black
                public var alpha = Float(0.05)
                public var offset = CGSize(width: 0, height: 2)
                public var radius = Float(4)
            }
        }
        
        // MARK: Colors
        
        public struct Color {
            public init() {}
            
            public var primary = UIColor.systemBlue
            
            public var background = CompatibleColor.systemBackground
            
            public var componentBackground = UIColor.dynamic(light: CompatibleColor.systemBackground,
                                                      dark: CompatibleColor.secondarySystemBackground)
            
            public var componentBorder = CompatibleColor.systemGray3
            
            public var componentDivider = CompatibleColor.systemGray3
            
            public var text = CompatibleColor.label
            
            public var textSecondary = CompatibleColor.secondaryLabel
            
            public var componentBackgroundText = CompatibleColor.label
            
            public var placeholderText = CompatibleColor.secondaryLabel
            
            public var icon = CompatibleColor.secondaryLabel
            
            public var danger = UIColor.systemRed
        }
        
    }

}
