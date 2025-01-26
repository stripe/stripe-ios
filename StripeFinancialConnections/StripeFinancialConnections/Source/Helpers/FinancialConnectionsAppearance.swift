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

        static let textDefault: UIColor = .dynamic(light: .neutral800, dark: .neutral800Dark)
        static let textSubdued: UIColor = .dynamic(light: .neutral600, dark: .neutral600Dark)
        static let textCritical: UIColor = .feedbackCritical600

        static let icon: UIColor = .dynamic(light: .neutral700, dark: .neutral700Dark)

        static let borderNeutral: UIColor = .dynamic(light: .neutral100, dark: .neutral100Dark)

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
        textAction: .brand600,
        textFieldFocused: .brand600,
        logo: .brand600,
        iconTint: .brand500,
        iconBackground: .brand25,
        spinner: .brand500,
        border: .brand600
    )

    static let link: FinancialConnectionsAppearance.Colors = .init(
        primary: .linkGreen200,
        primaryAccent: .linkGreen900,
        textAction: .linkGreen500,
        textFieldFocused: .linkGreen200,
        logo: .dynamic(light: .linkGreen900, dark: .neutral0),
        iconTint: .brand500,
        iconBackground: .linkGreen500,
        spinner: .linkGreen200,
        border: .linkGreen200
    )
}
