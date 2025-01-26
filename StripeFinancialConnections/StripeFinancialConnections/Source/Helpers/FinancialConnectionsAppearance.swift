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
        // Background color is static, and doesn't depend on the manifest's theme.
        static let background: UIColor = .dynamic(light: .neutral0, dark: .neutral0Dark)
        static let backgroundHighlighted: UIColor = .dynamic(light: .neutral50, dark: .neutral50Dark)

        let primary: UIColor
        let primaryAccent: UIColor
        let textDefault: UIColor
        let textSubdued: UIColor
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
        primary: .dynamic(light: .brand500, dark: .brand500),
        primaryAccent: .dynamic(light: .neutral0, dark: .neutral0),
        textDefault: .dynamic(light: .neutral800, dark: .neutral800Dark),
        textSubdued: .dynamic(light: .neutral600, dark: .neutral600Dark),
        textAction: .dynamic(light: .brand600, dark: .brand600),
        textFieldFocused: .dynamic(light: .brand600, dark: .brand600),
        logo: .dynamic(light: .brand600, dark: .brand600),
        iconTint: .dynamic(light: .brand500, dark: .brand500),
        iconBackground: .dynamic(light: .brand25, dark: .brand25),
        spinner: .dynamic(light: .brand500, dark: .brand500),
        border: .dynamic(light: .brand600, dark: .brand600)
    )

    static let link: FinancialConnectionsAppearance.Colors = .init(
        primary: .dynamic(light: .linkGreen200, dark: .linkGreen200),
        primaryAccent: .dynamic(light: .linkGreen900, dark: .linkGreen900),
        textDefault: .dynamic(light: .neutral800, dark: .neutral800Dark),
        textSubdued: .dynamic(light: .neutral600, dark: .neutral600Dark),
        textAction: .dynamic(light: .linkGreen500, dark: .linkGreen500),
        textFieldFocused: .dynamic(light: .linkGreen200, dark: .linkGreen200),
        logo: .dynamic(light: .linkGreen900, dark: .neutral0),
        iconTint: .dynamic(light: .brand500, dark: .brand500),
        iconBackground: .dynamic(light: .linkGreen500, dark: .linkGreen500),
        spinner: .dynamic(light: .linkGreen200, dark: .linkGreen200),
        border: .dynamic(light: .linkGreen200, dark: .linkGreen200)
    )
}
