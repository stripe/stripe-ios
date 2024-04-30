//
//  StripeConnectInstanceAppearance.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 4/30/24.
//

import UIKit

extension StripeConnectInstance {
    /// Describes the appearance of connect components.
    /// - seealso: https://docs.stripe.com/connect/embedded-appearance-options
    public struct Appearance {
        public static let `default` = Appearance()

        /// The font family value used throughout embedded components.
        public var fontFamily: String?
        /// The baseline font size set on the embedded component root. This scales the value of other font size variables.
        public var fontSizeBase: CGFloat?
        /// The base spacing unit that derives all spacing values. Increase or decrease this value to make your layout more or less spacious.
        public var spacingUnit: CGFloat?
        /// The general border radius used in embedded components. This sets the default border radius for all components.
        public var borderRadius: CGFloat?
        /// The primary color used throughout embedded components. Set this to your primary brand color.
        public var colorPrimary: UIColor?
        /// The background color for embedded components, including overlays, tooltips, and popovers.
        public var colorBackground: UIColor?
        /// The color used for regular text.
        public var colorText: UIColor?
        /// The color used to indicate errors or destructive actions.
        public var colorDanger: UIColor?

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
            dict["colorPrimary"] = colorPrimary?.cssValue
            dict["colorBackground"] = colorBackground?.cssValue
            dict["colorText"] = colorText?.cssValue
            dict["colorDanger"] = colorDanger?.cssValue
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

private extension UIColor {
    var cssValue: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0

        getRed(&red, green: &green, blue: &blue, alpha: nil)

        return String(
            format: "rgb(%.0f, %.0f, %.0f)",
            red * 255,
            green * 255,
            blue * 255
        )
    }
}
