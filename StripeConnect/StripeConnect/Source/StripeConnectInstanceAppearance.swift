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
    }
}
