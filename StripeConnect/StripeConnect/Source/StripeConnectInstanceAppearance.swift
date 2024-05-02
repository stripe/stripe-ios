//
//  StripeConnectInstanceAppearance.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 4/30/24.
//

@_spi(STP) import StripeCore
import UIKit

extension StripeConnectInstance {
    /// Describes the appearance of connect components.
    /// - seealso: https://docs.stripe.com/connect/embedded-appearance-options
    public struct Appearance {
        public enum TextTransform: String {
            /// The text doesn’t have a transform.
            case none
            /// Displays the text in all uppercase characters.
            case uppercase
            /// Displays the text in all lowercase characters.
            case lowercase
            /// Displays the text with the first character capitalized.
            case capitalize
        }

        public static let `default` = Appearance()

        /// The font family value used throughout embedded components.
        public var fontFamily: String?
        /// The baseline font size set on the embedded component root. This scales the value of other font size variables.
        public var fontSizeBase: CGFloat?
        /// The base spacing unit that derives all spacing values. Increase or decrease this value to make your layout more or less spacious.
        public var spacingUnit: CGFloat?
        /// The general border radius used in embedded components. This sets the default border radius for all components.
        public var borderRadius: CGFloat?
        /// The primary color used throughout embedded components. Set this to your primary brand color.  The alpha component is ignored.
        public var colorPrimary: UIColor?
        /// The background color for embedded components, including overlays, tooltips, and popovers. The alpha component is ignored.
        public var colorBackground: UIColor?
        /// The color used for regular text.
        public var colorText: UIColor?
        /// The color used to indicate errors or destructive actions. The alpha component is ignored.
        public var colorDanger: UIColor?

        /// The color used as a background for primary buttons. The alpha component is ignored.
        public var buttonPrimaryColorBackground: UIColor?
        /// The border color used for primary buttons. The alpha component is ignored.
        public var buttonPrimaryColorBorder: UIColor?
        /// The text color used for primary buttons. The alpha component is ignored.
        public var buttonPrimaryColorText: UIColor?
        /// The color used as a background for secondary buttons. The alpha component is ignored.
        public var buttonSecondaryColorBackground: UIColor?
        /// The color used as a border for secondary buttons. The alpha component is ignored.
        public var buttonSecondaryColorBorder: UIColor?
        /// The text color used for secondary buttons. The alpha component is ignored.
        public var buttonSecondaryColorText: UIColor?
        /// The color used for secondary text.
        public var colorSecondaryText: UIColor?
        /// The color used for primary actions and links. The alpha component is ignored.
        public var actionPrimaryColorText: UIColor?
        /// The color used for secondary actions and links. The alpha component is ignored.
        public var actionSecondaryColorText: UIColor?
        /// The background color used to represent neutral state or lack of state in status badges. The alpha component is ignored.
        public var badgeNeutralColorBackground: UIColor?
        /// The text color used to represent neutral state or lack of state in status badges. The alpha component is ignored.
        public var badgeNeutralColorText: UIColor?
        /// The border color used to represent neutral state or lack of state in status badges.
        public var badgeNeutralColorBorder: UIColor?
        /// The background color used to reinforce a successful outcome in status badges. The alpha component is ignored.
        public var badgeSuccessColorBackground: UIColor?
        /// The text color used to reinforce a successful outcome in status badges. The alpha component is ignored.
        public var badgeSuccessColorText: UIColor?
        /// The border color used to reinforce a successful outcome in status badges.
        public var badgeSuccessColorBorder: UIColor?
        /// The background color used in status badges to highlight things that might require action, but are optional to resolve. The alpha component is ignored.
        public var badgeWarningColorBackground: UIColor?
        /// The text color used in status badges to highlight things that might require action, but are optional to resolve. The alpha component is ignored.
        public var badgeWarningColorText: UIColor?
        /// The border color used in status badges to highlight things that might require action, but are optional to resolve.
        public var badgeWarningColorBorder: UIColor?
        /// The background color used in status badges for high-priority, critical situations that the user must address immediately, and to indicate failed or unsuccessful outcomes. The alpha component is ignored.
        public var badgeDangerColorBackground: UIColor?
        /// The text color used in status badges for high-priority, critical situations that the user must address immediately, and to indicate failed or unsuccessful outcomes. The alpha component is ignored.
        public var badgeDangerColorText: UIColor?
        /// The border color used in status badges for high-priority, critical situations that the user must address immediately, and to indicate failed or unsuccessful outcomes.
        public var badgeDangerColorBorder: UIColor?
        /// The background color used when highlighting information, like the selected row on a table or particular piece of UI. The alpha component is ignored.
        public var offsetBackgroundColor: UIColor?
        /// The background color used for form items. The alpha component is ignored.
        public var formBackgroundColor: UIColor?
        /// The color used for borders throughout the component.
        public var colorBorder: UIColor?
        /// The color used to highlight form items when focused.
        public var formHighlightColorBorder: UIColor?
        /// The color used for to fill in form items like checkboxes, radio buttons and switches. The alpha component is ignored.
        public var formAccentColor: UIColor?
        /// The border radius used for buttons.
        public var buttonBorderRadius: CGFloat?
        /// The border radius used for form elements.
        public var formBorderRadius: CGFloat?
        /// The border radius used for badges.
        public var badgeBorderRadius: CGFloat?
        /// The border radius used for overlays.
        public var overlayBorderRadius: CGFloat?
        /// The font size for the medium body typography.
        public var bodyMdFontSize: CGFloat?
        /// The font weight for the medium body typography.
        public var bodyMdFontWeight: UIFont.Weight?
        /// The font size for the small body typography.
        public var bodySmFontSize: CGFloat?
        /// The font weight for the small body typography.
        public var bodySmFontWeight: UIFont.Weight?
        /// The font size for the extra large heading typography.
        public var headingXlFontSize: CGFloat?
        /// The font weight for the extra large heading typography.
        public var headingXlFontWeight: UIFont.Weight?
        /// The text transform for the extra large heading typography.
        public var headingXlTextTransform: TextTransform?
        /// The font size for the large heading typography.
        public var headingLgFontSize: CGFloat?
        /// The font weight for the large heading typography.
        public var headingLgFontWeight: UIFont.Weight?
        /// The text transform for the large heading typography.
        public var headingLgTextTransform: TextTransform?
        /// The font size for the medium heading typography.
        public var headingMdFontSize: CGFloat?
        /// The font weight for the medium heading typography.
        public var headingMdFontWeight: UIFont.Weight?
        /// The text transform for the medium heading typography.
        public var headingMdTextTransform: TextTransform?
        /// The font size for the small heading typography.
        public var headingSmFontSize: CGFloat?
        /// The font weight for the small heading typography.
        public var headingSmFontWeight: UIFont.Weight?
        /// The text transform for the small heading typography.
        public var headingSmTextTransform: TextTransform?
        /// The font size for the extra small heading typography.
        public var headingXsFontSize: CGFloat?
        /// The font weight for the extra small heading typography.
        public var headingXsFontWeight: UIFont.Weight?
        /// The text transform for the extra small heading typography.
        public var headingXsTextTransform: TextTransform?
        /// The font size for the medium label typography.
        public var labelMdFontSize: CGFloat?
        /// The font weight for the medium label typography.
        public var labelMdFontWeight: UIFont.Weight?
        /// The text transform for the medium label typography.
        public var labelMdTextTransform: TextTransform?
        /// The font size for the small label typography.
        public var labelSmFontSize: CGFloat?
        /// The font weight for the small label typography.
        public var labelSmFontWeight: UIFont.Weight?
        /// The text transform for the small label typography.
        public var labelSmTextTransform: TextTransform?

        public init() { }

        // MARK: - Internal

        private var variablesDictionary: [String: String] {
            var dict: [String: String] = [:]

            // Default font to "-apple-system" to use the system default,
            // otherwise the webView will use Times
            dict["fontFamily"] = fontFamily ?? "-apple-system"

            dict["fontSizeBase"] = fontSizeBase?.pxString
            dict["spacingUnit"] = spacingUnit?.pxString
            dict["borderRadius"] = borderRadius?.pxString
            dict["colorPrimary"] = colorPrimary?.cssRgbValue
            dict["colorBackground"] = colorBackground?.cssRgbValue
            dict["colorText"] = colorText?.cssRgbValue
            dict["colorDanger"] = colorDanger?.cssRgbValue

            // TODO: Change commented back to `cssRgbaValue` for colors that allow alpha
            // There's a bug in Connect-JS where it won't accept RGBA colors with decimal alpha components
            dict["buttonPrimaryColorBackground"] = buttonPrimaryColorBackground?.cssRgbValue
            dict["buttonPrimaryColorBorder"] = buttonPrimaryColorBorder?.cssRgbValue
            dict["buttonPrimaryColorText"] = buttonPrimaryColorText?.cssRgbValue
            dict["buttonSecondaryColorBackground"] = buttonSecondaryColorBackground?.cssRgbValue
            dict["buttonSecondaryColorBorder"] = buttonSecondaryColorBorder?.cssRgbValue
            dict["buttonSecondaryColorText"] = buttonSecondaryColorText?.cssRgbValue
            dict["colorSecondaryText"] = colorSecondaryText?.cssRgbValue // cssRgbaValue
            dict["actionPrimaryColorText"] = actionPrimaryColorText?.cssRgbValue
            dict["actionSecondaryColorText"] = actionSecondaryColorText?.cssRgbValue
            dict["badgeNeutralColorBackground"] = badgeNeutralColorBackground?.cssRgbValue
            dict["badgeNeutralColorText"] = badgeNeutralColorText?.cssRgbValue
            dict["badgeNeutralColorBorder"] = badgeNeutralColorBorder?.cssRgbValue // cssRgbaValue
            dict["badgeSuccessColorBackground"] = badgeSuccessColorBackground?.cssRgbValue
            dict["badgeSuccessColorText"] = badgeSuccessColorText?.cssRgbValue
            dict["badgeSuccessColorBorder"] = badgeSuccessColorBorder?.cssRgbValue // cssRgbaValue
            dict["badgeWarningColorBackground"] = badgeWarningColorBackground?.cssRgbValue
            dict["badgeWarningColorText"] = badgeWarningColorText?.cssRgbValue
            dict["badgeWarningColorBorder"] = badgeWarningColorBorder?.cssRgbValue // cssRgbaValue
            dict["badgeDangerColorBackground"] = badgeDangerColorBackground?.cssRgbValue
            dict["badgeDangerColorText"] = badgeDangerColorText?.cssRgbValue
            dict["badgeDangerColorBorder"] = badgeDangerColorBorder?.cssRgbValue // cssRgbaValue
            dict["offsetBackgroundColor"] = offsetBackgroundColor?.cssRgbValue
            dict["formBackgroundColor"] = formBackgroundColor?.cssRgbValue
            dict["colorBorder"] = colorBorder?.cssRgbValue // cssRgbaValue
            dict["formHighlightColorBorder"] = formHighlightColorBorder?.cssRgbValue // cssRgbaValue
            dict["formAccentColor"] = formAccentColor?.cssRgbValue
            dict["buttonBorderRadius"] = buttonBorderRadius?.pxString
            dict["formBorderRadius"] = formBorderRadius?.pxString
            dict["badgeBorderRadius"] = badgeBorderRadius?.pxString
            dict["overlayBorderRadius"] = overlayBorderRadius?.pxString
            dict["bodyMdFontSize"] = bodyMdFontSize?.pxString
            dict["bodyMdFontWeight"] = bodyMdFontWeight?.cssValue
            dict["bodySmFontSize"] = bodySmFontSize?.pxString
            dict["bodySmFontWeight"] = bodySmFontWeight?.cssValue
            dict["headingXlFontSize"] = headingXlFontSize?.pxString
            dict["headingXlFontWeight"] = headingXlFontWeight?.cssValue
            dict["headingXlTextTransform"] = headingXlTextTransform?.rawValue
            dict["headingLgFontSize"] = headingLgFontSize?.pxString
            dict["headingLgFontWeight"] = headingLgFontWeight?.cssValue
            dict["headingLgTextTransform"] = headingLgTextTransform?.rawValue
            dict["headingMdFontSize"] = headingMdFontSize?.pxString
            dict["headingMdFontWeight"] = headingMdFontWeight?.cssValue
            dict["headingMdTextTransform"] = headingMdTextTransform?.rawValue
            dict["headingSmFontSize"] = headingSmFontSize?.pxString
            dict["headingSmFontWeight"] = headingSmFontWeight?.cssValue
            dict["headingSmTextTransform"] = headingSmTextTransform?.rawValue
            dict["headingXsFontSize"] = headingXsFontSize?.pxString
            dict["headingXsFontWeight"] = headingXsFontWeight?.cssValue
            dict["headingXsTextTransform"] = headingXsTextTransform?.rawValue
            dict["labelMdFontSize"] = labelMdFontSize?.pxString
            dict["labelMdFontWeight"] = labelMdFontWeight?.cssValue
            dict["labelMdTextTransform"] = labelMdTextTransform?.rawValue
            dict["labelSmFontSize"] = labelSmFontSize?.pxString
            dict["labelSmFontWeight"] = labelSmFontWeight?.cssValue
            dict["labelSmTextTransform"] = labelSmTextTransform?.rawValue

            return dict
        }

        var asJsonString: String {
            guard let data = try? JSONSerialization.data(withJSONObject: variablesDictionary),
                  let stringValue = String(data: data, encoding: .utf8) else {
                debugPrint("Couldn't encode appearance")
                return "{}"
            }

            return "{ variables: \(stringValue) }"
        }
    }
}

private extension CGFloat {
    var pxString: String {
        "\(Int(self))px"
    }
}

private extension UIFont.Weight {
    var cssValue: String? {
        switch self {
        case .black: return "black"
        case .bold: return "bold"
        case .heavy: return "heavy"
        case .light: return "light"
        case .medium: return "medium"
        case .regular: return "regular"
        case .semibold: return "semi-bold"
        case .thin: return "thin"
        case .ultraLight: return "ultra-light"
        default: return nil
        }
    }
}
