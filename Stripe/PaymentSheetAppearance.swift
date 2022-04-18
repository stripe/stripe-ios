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
    
    /// Describes the appearance of PaymentSheet
    struct Appearance: Equatable {
         
        /// The default appearance for PaymentSheet
        public static let `default` = Appearance()
        
        /// Creates a `PaymentSheet.Appearance` with default values
        public init() {}
        
        /// Describes the appearance of fonts in PaymentSheet
        public var font: Font = Font()
        
        /// Describes the colors in PaymentSheet
        public var colors: Colors = Colors()
        
        /// The corner radius used for buttons, inputs, tabs in PaymentSheet
        /// - Note: The behavior of this property is consistent with the behavior of corner radius on `CALayer`
        public var cornerRadius: CGFloat = 6.0
        
        /// The border used for inputs and tabs in PaymentSheet
        /// - Note: The behavior of this property is consistent with the behavior of border width on `CALayer`
        public var borderWidth: CGFloat = 1.0
        
        /// The shadow used for inputs and tabs in PaymentSheet
        /// - Note: Set this to `nil` to disable shadows.
        public var shadow: Shadow? = Shadow()
        
        // MARK: Fonts
        
        /// Describes the appearance of fonts in PaymentSheet
        public struct Font: Equatable {
            
            /// Creates a `PaymentSheet.Appearance.Font` with default values
            public init() {}
            
            /// The scale factor for all font sizes in PaymentSheet. 
            /// Font sizes are multiplied by this value before being displayed. For example, setting this to 1.2 increases the size of all text by 20%. 
            /// - Note: This value must be greater than 0. The default value is 1.0.
            /// - Note: This is used in conjunction with the Dynamic Type accessibility text size.
            public var sizeScaleFactor: CGFloat = 1.0 {
                willSet {
                    if newValue <= 0.0 {
                        assertionFailure("sizeScaleFactor must be a value greater than zero")
                    }
                }
            }

            /// The font family of this font is used throughout PaymentSheet. PaymentSheet uses this font at multiple weights (e.g., regular, medium, semibold) if they exist.
            /// - Note: The size and weight of the font is ignored. To adjust font sizes, see `sizeScaleFactor`.
            public var base: UIFont = UIFont.systemFont(ofSize: UIFont.labelFontSize, weight: .regular)
        }
        
        // MARK: Colors
        
        /// Describes the colors in PaymentSheet
        public struct Colors: Equatable {
            typealias DefaultColor = CompatibleColor

            /// Creates a `PaymentSheet.Appearance.Colors` with default values
            public init() {}
            
            /// The primary color used throughout PaymentSheet
            public var primary: UIColor = UIColor.systemBlue
            
            /// The color used for the background of PaymentSheet
            public var background: UIColor = DefaultColor.systemBackground
            
            /// The color used for the background of inputs, tabs, and other components
            public var componentBackground: UIColor = UIColor.dynamic(light: DefaultColor.systemBackground,
                                                      dark: DefaultColor.secondarySystemBackground)
            
            /// The border color used for inputs, tabs, and other components
            public var componentBorder: UIColor = DefaultColor.systemGray3
            
            /// The color of the divider lines used inside inputs, tabs, and other components
            public var componentDivider: UIColor = DefaultColor.systemGray3
            
            /// The default text color used in PaymentSheet, appearing over the background color
            public var text: UIColor = DefaultColor.label
            
            /// The color used for text of secondary importance. For example, this color is used for the label above input fields
            public var textSecondary: UIColor = DefaultColor.secondaryLabel
            
            /// The color of text appearing over `componentBackground`
            public var componentText: UIColor = DefaultColor.label
            
            /// The color used for input placeholder text
            public var componentPlaceholderText: UIColor = DefaultColor.secondaryLabel
            
            /// The color used for icons in PaymentSheet, such as the close or back icons
            public var icon: UIColor = DefaultColor.secondaryLabel
            
            /// The color used to indicate errors or destructive actions in PaymentSheet
            public var danger: UIColor = UIColor.systemRed
        }
        
        // MARK: Shadow
        
        /// Represents a shadow in PaymentSheet
        public struct Shadow: Equatable {
            /// Color of the shadow
            /// - Note: The behavior of this property is consistent with `CALayer.shadowColor`
            public var color: UIColor = UIColor.black
            
            /// Opacity or alpha of the shadow
            /// - Note: The behavior of this property is consistent with `CALayer.shadowOpacity`
            public var opacity: CGFloat = CGFloat(0.05)
            
            /// Offset of the shadow
            /// - Note: The behavior of this property is consistent with `CALayer.shadowOffset`
            public var offset: CGSize = CGSize(width: 0, height: 2)
            
            /// Radius of the shadow
            /// - Note: The behavior of this property is consistent with `CALayer.shadowRadius`
            public var radius: CGFloat = 4
            
            /// Creates a `PaymentSheet.Appearance.Shadow` with default values
            public init() {}
            
            /// Creates a `Shadow` with the specfied parameters
            /// - Parameters:
            ///   - color: Color of the shadow
            ///   - opacity: Opacity or opacity of the shadow
            ///   - offset: Offset of the shadow
            ///   - radius: Radius of the shadow
            public init(color: UIColor, opacity: CGFloat, offset: CGSize, radius: CGFloat) {
                self.color = color
                self.opacity = opacity
                self.offset = offset
                self.radius = radius
            }
        }
        
    }

}
