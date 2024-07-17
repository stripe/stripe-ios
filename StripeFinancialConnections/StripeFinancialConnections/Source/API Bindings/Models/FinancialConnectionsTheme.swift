//
//  FinancialConnectionsTheme.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2024-07-17.
//

import UIKit

class FinancialConnectionsTheme {
    static let current = FinancialConnectionsTheme()
    private var theme: FinancialConnectionsSessionManifest.Theme?

    // Ensures the shared instance `.current` is used.
    private init() {}

    func setTheme(_ theme: FinancialConnectionsSessionManifest.Theme?) {
        self.theme = theme
    }

    // MARK: Theme values

    var logo: Image {
        switch theme {
        case .linkLight:
            return .link_logo
        case .light, .dashboardLight, .unparsable, .none:
            return .stripe_logo
        }
    }

    var primaryColor: UIColor {
        switch theme {
        case .linkLight:
            return .linkGreen200
        case .light, .dashboardLight, .unparsable, .none:
            return .brand500
        }
    }

    var primaryButtonTextColor: UIColor {
        switch theme {
        case .linkLight:
            return .linkGreen900
        case .light, .dashboardLight, .unparsable, .none:
            return .white
        }
    }

    var logoColor: UIColor {
        switch theme {
        case .linkLight:
            return .linkGreen900
        case .light, .dashboardLight, .unparsable, .none:
            return .textActionPrimary
        }
    }
}
