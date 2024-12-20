//
//  EmbeddedComponentManager+Appearance.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/28/24.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

@_spi(PrivateBetaConnect)
@_documentation(visibility: public)
@available(iOS 15, *)
extension EmbeddedComponentManager {
    /// Describes the appearance of embedded components.
    /// - seealso: [Appearance option documentation](https://docs.stripe.com/connect/embedded-appearance-options)
    @_documentation(visibility: public)
    public struct Appearance {
        @_documentation(visibility: public)
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
        @_documentation(visibility: public)
        public struct Typography {
            /// Describes the font attributes used for a
            /// typography style in embedded components.
            @_documentation(visibility: public)
            public struct Style {
                /// The unscaled font size for this typography style.
                /// The displayed fonts are automatically scaled when the component's size category is updated.
                @_documentation(visibility: public)
                public var fontSize: CGFloat?
                /// The font weight for this typography style.
                @_documentation(visibility: public)
                public var weight: UIFont.Weight?
                /// The text transform for this typography style.
                @_documentation(visibility: public)
                public var textTransform: TextTransform?

                /// Creates a `EmbeddedComponentManager.Appearance.Typography.Stylye` with default values
                @_documentation(visibility: public)
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
            @_documentation(visibility: public)
            public var font: UIFont?
            /// The unscaled baseline font size set on the embedded component root.
            /// This scales the value of other font size variables and is automatically scaled
            /// when the component's size category is updated.
            @_documentation(visibility: public)
            public var fontSizeBase: CGFloat? = 16
            /// Describes the font size and weight for the medium body typography.
            /// The `textTransform` property is ignored.
            @_documentation(visibility: public)
            public var bodyMd: Style = .init()
            /// Describes the font size and weight for the small body typography.
            /// The `textTransform` property is ignored.
            @_documentation(visibility: public)
            public var bodySm: Style = .init()
            /// Describes the font size and weight for the extra large heading typography.
            @_documentation(visibility: public)
            public var headingXl: Style = .init()
            /// Describes the font size and weight for the large heading typography.
            @_documentation(visibility: public)
            public var headingLg: Style = .init()
            /// Describes the font size and weight for the medium heading typography.
            @_documentation(visibility: public)
            public var headingMd: Style = .init()
            /// Describes the font size and weight for the small heading typography.
            @_documentation(visibility: public)
            public var headingSm: Style = .init()
            /// Describes the font size and weight for the extra small heading typography.
            @_documentation(visibility: public)
            public var headingXs: Style = .init()
            /// Describes the font size and weight for the medium label typography.
            @_documentation(visibility: public)
            public var labelMd: Style = .init()
            /// Describes the font size and weight for the small label typography.
            @_documentation(visibility: public)
            public var labelSm: Style = .init()

            /// Creates a `EmbeddedComponentManager.Appearance.Typography` with default values
            @_documentation(visibility: public)
            public init() { }
        }

        /// Describes the colors used in embedded components.
        /// - Note: If UIColors using dynamicProviders are specified, the appearance will automatically
        ///   update when the component's UITraitCollection is updated (e.g. dark mode)
        /// - Seealso: [Supporting Dark Mode in your app](https://developer.apple.com/documentation/uikit/appearance_customization/supporting_dark_mode_in_your_interface)
        @_documentation(visibility: public)
        public struct Colors {
            /// The primary color used throughout embedded components.
            /// Set this to your primary brand color.
            /// The alpha component is ignored.
            @_documentation(visibility: public)
            public var primary: UIColor?
            /// The color used for regular text.
            @_documentation(visibility: public)
            public var text: UIColor?
            /// The color used to indicate errors or destructive actions.
            /// The alpha component is ignored.
            @_documentation(visibility: public)
            public var danger: UIColor?
            /// The background color for embedded components, including overlays,
            /// tooltips, and popovers. The alpha component is ignored.
            @_documentation(visibility: public)
            public var background: UIColor?
            /// The color used for secondary text.
            @_documentation(visibility: public)
            public var secondaryText: UIColor?
            /// The color used for borders throughout the component.
            @_documentation(visibility: public)
            public var border: UIColor?
            /// The color used for primary actions and links.
            /// The alpha component is ignored.
            @_documentation(visibility: public)
            public var actionPrimaryText: UIColor?
            /// The color used for secondary actions and links.
            /// The alpha component is ignored.
            @_documentation(visibility: public)
            public var actionSecondaryText: UIColor?
            /// The background color used when highlighting information,
            /// like the selected row on a table or particular piece of UI.
            /// The alpha component is ignored.
            @_documentation(visibility: public)
            public var offsetBackground: UIColor?
            /// The background color used for form items.
            /// The alpha component is ignored.
            @_documentation(visibility: public)
            public var formBackground: UIColor?
            /// The color used to highlight form items when focused.
            @_documentation(visibility: public)
            public var formHighlightBorder: UIColor?
            /// The color used for to fill in form items like checkboxes,
            /// radio buttons and switches. The alpha component is ignored.
            @_documentation(visibility: public)
            public var formAccent: UIColor?

            /// Creates a `EmbeddedComponentManager.Appearance.Colors` with default values
            @_documentation(visibility: public)
            public init() {}

            /// The computed background color
            var resolvedBackground: UIColor {
                // Defaults to white if none is set
                background ?? .white
            }

            /// The computed loading indicator color
            var loadingIndicatorColor: UIColor {
                .init { traitCollection in
                    let background = resolvedBackground.resolvedColor(with: traitCollection)

                    // Use the secondary text color if it was set
                    if let secondaryText {
                        return secondaryText
                            .resolvedColor(with: traitCollection)
                            .adjustedForContrast(with: background)
                    }

                    // Lighten or darken the background to get enough contrast
                    return background.adjustedForContrast(with: background)
                }
            }
        }

        /// Describes the appearance of a button type used in embedded components
        @_documentation(visibility: public)
        public struct Button {
            /// The color used as a background for this button type.
            /// The alpha component is ignored.
            @_documentation(visibility: public)
            public var colorBackground: UIColor?
            /// The border color used for this button type.
            /// The alpha component is ignored.
            @_documentation(visibility: public)
            public var colorBorder: UIColor?
            /// The text color used for this button type.
            /// The alpha component is ignored.
            @_documentation(visibility: public)
            public var colorText: UIColor?

            /// Creates a `EmbeddedComponentManager.Appearance.Button` with default values
            @_documentation(visibility: public)
            public init() { }
        }

        /// Describes the appearance of a badge type usied in embedded components.
        @_documentation(visibility: public)
        public struct Badge {
            /// The background color for this badge type.
            /// The alpha component is ignored.
            @_documentation(visibility: public)
            public var colorBackground: UIColor?
            /// The border color for this badge type.
            @_documentation(visibility: public)
            public var colorBorder: UIColor?
            /// The text color for this badge type. The alpha component is ignored.
            @_documentation(visibility: public)
            public var colorText: UIColor?

            /// Creates a `EmbeddedComponentManager.Appearance.Badge` with default values
            @_documentation(visibility: public)
            public init() {}
        }

        /// Describes the corner radius used in embedded components.
        @_documentation(visibility: public)
        public struct CornerRadius {
            /// The general border radius used in embedded components.
            /// This sets the default corner radius for all components.
            @_documentation(visibility: public)
            public var base: CGFloat?
            /// The corner radius used for form elements.
            @_documentation(visibility: public)
            public var form: CGFloat?
            /// The corner radius used for buttons.
            @_documentation(visibility: public)
            public var button: CGFloat?
            /// The corner radius used for badges.
            @_documentation(visibility: public)
            public var badge: CGFloat?
            /// The corner radius used for overlays.
            @_documentation(visibility: public)
            public var overlay: CGFloat?

            /// Creates a `EmbeddedComponentManager.Appearance.CornerRadius` with default values
            @_documentation(visibility: public)
            public init() {}
        }

        /// The default appearance
        @_documentation(visibility: public)
        public static let `default`: Appearance = .init()

        /// Describes the appearance of typography used in embedded components.
        @_documentation(visibility: public)
        public var typography: Typography = .init()
        /// Describes the colors used in embedded components.
        @_documentation(visibility: public)
        public var colors: Colors = .init()
        /// The base spacing unit that derives all spacing values.
        /// Increase or decrease this value to make your layout more or less spacious.
        @_documentation(visibility: public)
        public var spacingUnit: CGFloat?
        /// Describes the appearance of the primary button
        @_documentation(visibility: public)
        public var buttonPrimary: Button  = .init()
        /// Describes the appearance of the secondary button
        @_documentation(visibility: public)
        public var buttonSecondary: Button  = .init()
        /// Describes the appearance used to represent neutral
        /// state or lack of state in status badges.
        @_documentation(visibility: public)
        public var badgeNeutral: Badge  = .init()
        /// Describes the appearance used to reinforce a successful
        /// outcome in status badges.
        @_documentation(visibility: public)
        public var badgeSuccess: Badge  = .init()
        /// Describes the appearance used in status badges to highlight
        /// things that might require action, but are optional to resolve.
        @_documentation(visibility: public)
        public var badgeWarning: Badge  = .init()
        /// Describes the appearance used in status badges for high-priority,
        /// critical situations that the user must address immediately, and to
        /// indicate failed or unsuccessful outcomes.
        @_documentation(visibility: public)
        public var badgeDanger: Badge  = .init()
        /// Describes the corner radius used in embedded components.
        @_documentation(visibility: public)
        public var cornerRadius: CornerRadius = .init()

        /// Creates a `EmbeddedComponentManager.Appearance` with default values
        @_documentation(visibility: public)
        public init() {}
    }
}
