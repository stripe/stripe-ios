//
//  EmbeddedComponentManager+Appearance.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/28/24.
//

@_spi(STP) import StripeCore
import UIKit

@_spi(PrivateBetaConnect)
extension EmbeddedComponentManager {
    /// Describes the appearance of embedded components.
    /// - seealso: https://docs.stripe.com/connect/embedded-appearance-options
    public struct Appearance {
        public enum TextTransform {
            /// The text doesn’t have a transform.
            case none
            /// Displays the text in all uppercase characters.
            case uppercase
            /// Displays the text in all lowercase characters.
            case lowercase
            /// Displays the text with the first character capitalized.
            case capitalize
            
            // Since the public API does not call for TextTransform to be a string
            // we manually create a raw value here.
            var rawValue: String {
                switch self {
                case .none:
                    return "none"
                case .uppercase:
                    return "uppercase"
                case .lowercase:
                    return "lowercase"
                case .capitalize:
                    return "capitalize"
                }
            }
            
            init?(rawValue: String) {
                switch rawValue {
                case "none":
                    self = .none
                case "uppercase":
                    self = .uppercase
                case "lowercase":
                    self = .lowercase
                case "capitalize":
                    self = .capitalize
                default:
                    return nil
                }
            }
        }
        
        /// Describes the typography attributes used in embedded components
        public struct Typography {
            /// Describes the font attributes used for a
            /// typography style in embedded components.
            public struct Style {
                /// The font size for this typography style.
                public var fontSize: CGFloat?
                /// The font weight for this typography style.
                public var weight: UIFont.Weight?
                /// The text transform for this typography style.
                public var textTransform: TextTransform?

                /// Creates a `EmbeddedComponentManager.Appearance.Typography.Stylye` with default values
                public init() {}
                
            }
            
            /// Determines the font family value used throughout embedded components.
            /// Only the family is used from the specified font. The size and weight can be
            /// configured from `fontSizeBase` or `fontSize` and `fontWeight`
            /// properties for individual typography styles.
            ///
            /// - Note: Custom fonts included in your app's binary must be specified using a
            ///   `CustomFontSource` when initializing the `EmbeddedComponentManager` before
            ///   referencing them in the appearance's `typography.font` property.
            public var font: UIFont?
            /// The baseline font size set on the embedded component root.
            /// This scales the value of other font size variables.
            public var fontSizeBase: CGFloat?
            /// Describes the font size and weight for the medium body typography.
            /// The `textTransform` property is ignored.
            public var bodyMd: Style = .init()
            /// Describes the font size and weight for the small body typography.
            /// The `textTransform` property is ignored.
            public var bodySm: Style = .init()
            /// Describes the font size and weight for the extra large heading typography.
            public var headingXl: Style = .init()
            /// Describes the font size and weight for the large heading typography.
            public var headingLg: Style = .init()
            /// Describes the font size and weight for the medium heading typography.
            public var headingMd: Style = .init()
            /// Describes the font size and weight for the small heading typography.
            public var headingSm: Style = .init()
            /// Describes the font size and weight for the extra small heading typography.
            public var headingXs: Style = .init()
            /// Describes the font size and weight for the medium label typography.
            public var labelMd: Style = .init()
            /// Describes the font size and weight for the small label typography.
            public var labelSm: Style = .init()
            
            /// Creates a `EmbeddedComponentManager.Appearance.Typography` with default values
            public init() { }
        }
        
        /// Describes the colors used in embedded components.
        /// - Note: If UIColors using dynamicProviders are specified, the appearance will automatically
        ///   update when the component's UITraitCollection is updated (e.g. dark mode)
        /// - Seealso: https://developer.apple.com/documentation/uikit/appearance_customization/supporting_dark_mode_in_your_interface
        public struct Colors {
            /// The primary color used throughout embedded components.
            /// Set this to your primary brand color.
            /// The alpha component is ignored.
            public var primary: UIColor?
            /// The color used for regular text.
            public var text: UIColor?
            /// The color used to indicate errors or destructive actions.
            /// The alpha component is ignored.
            public var danger: UIColor?
            /// The background color for embedded components, including overlays,
            /// tooltips, and popovers. The alpha component is ignored.
            public var background: UIColor?
            /// The color used for secondary text.
            public var secondaryText: UIColor?
            /// The color used for borders throughout the component.
            public var border: UIColor?
            /// The color used for primary actions and links.
            /// The alpha component is ignored.
            public var actionPrimaryText: UIColor?
            /// The color used for secondary actions and links.
            /// The alpha component is ignored.
            public var actionSecondaryText: UIColor?
            /// The background color used when highlighting information,
            /// like the selected row on a table or particular piece of UI.
            /// The alpha component is ignored.
            public var offsetBackground: UIColor?
            /// The background color used for form items.
            /// The alpha component is ignored.
            public var formBackground: UIColor?
            /// The color used to highlight form items when focused.
            public var formHighlightBorder: UIColor?
            /// The color used for to fill in form items like checkboxes,
            /// radio buttons and switches. The alpha component is ignored.
            public var formAccent: UIColor?
            
            /// Creates a `EmbeddedComponentManager.Appearance.Colors` with default values
            public init() {}
        }
        
        /// Describes the appearance of a button type used in embedded components
        public struct Button {
            /// The color used as a background for this button type.
            /// The alpha component is ignored.
            public var colorBackground: UIColor?
            /// The border color used for this button type.
            /// The alpha component is ignored.
            public var colorBorder: UIColor?
            /// The text color used for this button type.
            /// The alpha component is ignored.
            public var colorText: UIColor?
            
            /// Creates a `EmbeddedComponentManager.Appearance.Button` with default values
            public init() { }
        }
        
        /// Describes the appearance of a badge type usied in embedded components.
        public struct Badge {
            /// The background color for this badge type.
            /// The alpha component is ignored.
            public var colorBackground: UIColor?
            /// The border color for this badge type.
            public var colorBorder: UIColor?
            /// The text color for this badge type. The alpha component is ignored.
            public var colorText: UIColor?
            
            /// Creates a `EmbeddedComponentManager.Appearance.Badge` with default values
            public init() {}
        }
        
        /// Describes the corner radius used in embedded components.
        public struct CornerRadius {
            /// The general border radius used in embedded components.
            /// This sets the default corner radius for all components.
            public var base: CGFloat?
            /// The corner radius used for form elements.
            public var form: CGFloat?
            /// The corner radius used for buttons.
            public var button: CGFloat?
            /// The corner radius used for badges.
            public var badge: CGFloat?
            /// The corner radius used for overlays.
            public var overlay: CGFloat?
            
            /// Creates a `EmbeddedComponentManager.Appearance.CornerRadius` with default values
            public init() {}
        }
        
        /// The default appearance
        public static let `default`: Appearance = .init()
        
        /// Describes the appearance of typography used in embedded components.
        public var typography: Typography = .init()
        /// Describes the colors used in embedded components.
        public var colors: Colors = .init()
        /// The base spacing unit that derives all spacing values.
        /// Increase or decrease this value to make your layout more or less spacious.
        public var spacingUnit: CGFloat?
        /// Describes the appearance of the primary button
        public var buttonPrimary: Button  = .init()
        /// Describes the appearance of the secondary button
        public var buttonSecondary: Button  = .init()
        /// Describes the appearance used to represent neutral
        /// state or lack of state in status badges.
        public var badgeNeutral: Badge  = .init()
        /// Describes the appearance used to reinforce a successful
        /// outcome in status badges.
        public var badgeSuccess: Badge  = .init()
        /// Describes the appearance used in status badges to highlight
        /// things that might require action, but are optional to resolve.
        public var badgeWarning: Badge  = .init()
        /// Describes the appearance used in status badges for high-priority,
        /// critical situations that the user must address immediately, and to
        /// indicate failed or unsuccessful outcomes.
        public var badgeDanger: Badge  = .init()
        /// Describes the corner radius used in embedded components.
        public var cornerRadius: CornerRadius = .init()
        
        /// Creates a `EmbeddedComponentManager.Appearance` with default values
        public init() {}
    }
}

