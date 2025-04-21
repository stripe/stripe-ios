//
//  FinancialConnectionsAppearance.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2025-01-24.
//

import UIKit

struct FinancialConnectionsAppearance: Equatable {
    static let stripe: Self = .init(from: .light)
    static let link: Self = .init(from: .linkLight)

    struct Colors: Equatable {
        // Some colors are static, and don't depend on the manifest's theme.
        static let background: UIColor = .dynamic(light: .neutral0, dark: .neutral0Dark)
        static let backgroundSecondary: UIColor = .dynamic(light: .neutral25, dark: .neutral25Dark)
        static let backgroundHighlighted: UIColor = .dynamic(light: .neutral50, dark: .neutral50Dark)
        static let textDefault: UIColor = .dynamic(light: .neutral800, dark: .neutral25)
        static let textSubdued: UIColor = .dynamic(light: .neutral600, dark: .neutral800Dark)
        static let textCritical: UIColor = .feedbackCritical600
        static let icon: UIColor = .dynamic(light: .neutral700, dark: .neutral25)
        static let borderNeutral: UIColor = .dynamic(light: .neutral100, dark: .neutral100Dark)
        static let spinnerNeutral: UIColor = .neutral200
        static let warningLight: UIColor = .dynamic(light: .attention50, dark: .attention100Dark)
        static let warning: UIColor = .attention300
        static let shadow: UIColor = .black

        // These colors change based on the manifest's theme.
        let primary: UIColor
        let primaryAccent: UIColor
        let textAction: UIColor
        let textFieldFocused: UIColor
        let logo: UIColor
        let iconTint: UIColor
        let iconBackground: UIColor
        let spinner: UIColor
        let border: UIColor
    }

    let colors: Colors
    let logo: Image

    init(from theme: FinancialConnectionsSessionManifest.Theme?) {
        switch theme {
        case .linkLight:
            self.colors = .link
            self.logo = .link_logo
        case .light, .dashboardLight, .unparsable, .none:
            self.colors = .stripe
            self.logo = .stripe_logo
        }
    }
}

extension FinancialConnectionsAppearance.Colors {
    static let stripe: FinancialConnectionsAppearance.Colors = .init(
        primary: .brand500,
        primaryAccent: .neutral0,
        textAction: .dynamic(light: .brand600, dark: .brand500),
        textFieldFocused: .brand600,
        logo: .dynamic(light: .brand600, dark: .neutral0),
        iconTint: .brand500,
        iconBackground: .dynamic(light: .brand25, dark: .brand25Dark),
        spinner: .brand500,
        border: .brand600
    )

    static let link: FinancialConnectionsAppearance.Colors = .init(
        primary: .linkGreen200,
        primaryAccent: .linkGreen900,
        textAction: .dynamic(light: .linkGreen500, dark: .linkGreen200),
        textFieldFocused: .linkGreen200,
        logo: .dynamic(light: .linkGreen900, dark: .neutral0),
        iconTint: .linkGreen500,
        iconBackground: .dynamic(light: .linkGreen50, dark: .linkGreen50Dark),
        spinner: .linkGreen200,
        border: .linkGreen200
    )
}

// MARK: - Raw colors
private extension UIColor {
    // MARK: Neutral
    static var neutral0: UIColor {
        return UIColor(red: 255 / 255.0, green: 255 / 255.0, blue: 255 / 255.0, alpha: 1) // #ffffff
    }

    static var neutral0Dark: UIColor {
        return UIColor(red: 20 / 255.0, green: 23 / 255.0, blue: 29 / 255.0, alpha: 1) // #14171d
    }

    static var neutral25: UIColor {
        return UIColor(red: 245 / 255.0, green: 246 / 255.0, blue: 248 / 255.0, alpha: 1)  // #f5f6f8
    }

    static var neutral25Dark: UIColor {
        return UIColor(red: 27 / 255.0, green: 30 / 255.0, blue: 37 / 255.0, alpha: 1)  // #1b1e25
    }

    static var neutral50: UIColor {
        return UIColor(red: 246 / 255.0, green: 248 / 255.0, blue: 250 / 255.0, alpha: 1)  // #f6f8fa
    }

    static var neutral50Dark: UIColor {
        return UIColor(red: 33 / 255.0, green: 37 / 255.0, blue: 44 / 255.0, alpha: 1)  // #21252c
    }

    static var neutral100: UIColor {
        return UIColor(red: 216 / 255.0, green: 222 / 255.0, blue: 228 / 255.0, alpha: 1)  // #d8dee4
    }

    static var neutral100Dark: UIColor {
        return UIColor(red: 43 / 255.0, green: 48 / 255.0, blue: 57 / 255.0, alpha: 1)  // #2b3039
    }

    static var neutral200: UIColor {
        return UIColor(red: 192 / 255.0, green: 200 / 255.0, blue: 210 / 255.0, alpha: 1)  // #c0c8d2
    }

    static var neutral600: UIColor {
        return UIColor(red: 89 / 255.0, green: 97 / 255.0, blue: 113 / 255.0, alpha: 1)  // #596171
    }

    static var neutral700: UIColor {
        return UIColor(red: 71 / 255.0, green: 78 / 255.0, blue: 90 / 255.0, alpha: 1)  // #474e5a
    }

    static var neutral800: UIColor {
        return UIColor(red: 53 / 255.0, green: 58 / 255.0, blue: 68 / 255.0, alpha: 1)  // #353a44
    }

    static var neutral800Dark: UIColor {
        return UIColor(red: 201 / 255.0, green: 206 / 255.0, blue: 216 / 255.0, alpha: 1) // #14171d
    }

    // MARK: Attention
    static var attention50: UIColor {
        return UIColor(red: 254 / 255.0, green: 249 / 255.0, blue: 218 / 255.0, alpha: 1)  // #fef9da
    }

    static var attention100Dark: UIColor {
        return UIColor(red: 48 / 255.0, green: 37 / 255.0, blue: 20 / 255.0, alpha: 1)  // #302514
    }

    static var attention300: UIColor {
        return UIColor(red: 247 / 255.0, green: 135 / 255.0, blue: 15 / 255.0, alpha: 1)  // #f7870f
    }

    // MARK: Feedback
    static var feedbackCritical600: UIColor {
        return UIColor(red: 192 / 255.0, green: 18 / 255.0, blue: 60 / 255.0, alpha: 1)  // #c0123c
    }

    // MARK: Brand
    static var brand25: UIColor {
        return UIColor(red: 247 / 255.0, green: 245 / 255.0, blue: 253 / 255.0, alpha: 1)  // #f7f5fd
    }

    static var brand25Dark: UIColor {
        return UIColor(red: 26 / 255.0, green: 27 / 255.0, blue: 46 / 255.0, alpha: 1)  // #1A1B2E
    }

    static var brand500: UIColor {
        return UIColor(red: 103 / 255.0, green: 93 / 255.0, blue: 255 / 255.0, alpha: 1)  // #675dff
    }

    static var brand600: UIColor {
        return UIColor(red: 83 / 255.0, green: 58 / 255.0, blue: 253 / 255.0, alpha: 1)  // #533afd
    }

    // MARK: Link
    static var linkGreen50: UIColor {
        return UIColor(red: 230 / 255.0, green: 255 / 255.0, blue: 237 / 255.0, alpha: 1)  // #e6ffed
    }

    static var linkGreen50Dark: UIColor {
        return UIColor(red: 22 / 255.0, green: 33 / 255.0, blue: 31 / 255.0, alpha: 1)  // #16211f
    }

    static var linkGreen200: UIColor {
        return UIColor(red: 0 / 255.0, green: 214 / 255.0, blue: 111 / 255.0, alpha: 1)  // #00D66F
    }

    static var linkGreen500: UIColor {
        return UIColor(red: 0 / 255.0, green: 133 / 255.0, blue: 69 / 255.0, alpha: 1)  // #008545
    }

    static var linkGreen900: UIColor {
        return UIColor(red: 1 / 255.0, green: 30 / 255.0, blue: 15 / 255.0, alpha: 1)  // #011E0F
    }

    // MARK: Helpers
    static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        return UIColor(dynamicProvider: {
            switch PresentationManager.shared.configuration.style {
            case .alwaysLight:
                return light
            case .alwaysDark:
                return dark
            case .automatic:
                switch $0.userInterfaceStyle {
                case .light, .unspecified:
                    return light
                case .dark:
                    return dark
                @unknown default:
                    return light
                }
            }
        })
    }
}
