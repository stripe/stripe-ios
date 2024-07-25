//
//  FinancialConnectionsTheme.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2024-07-17.
//

import UIKit

enum FinancialConnectionsTheme: String, Equatable {
    case light
    case linkLight

    init(from theme: FinancialConnectionsSessionManifest.Theme?) {
        switch theme {
        case .linkLight:
            self = .linkLight
        case .light, .dashboardLight, .unparsable, .none:
            self = .light
        }
    }
}

extension FinancialConnectionsTheme {
    var logo: Image {
        switch self {
        case .linkLight:
            return .link_logo
        case .light:
            return .stripe_logo
        }
    }

    var primaryColor: UIColor {
        switch self {
        case .linkLight:
            return .linkGreen200
        case .light:
            return .brand500
        }
    }

    var primaryAccentColor: UIColor {
        switch self {
        case .linkLight:
            return .linkGreen900
        case .light:
            return .white
        }
    }

    var textFieldFocusedColor: UIColor {
        switch self {
        case .linkLight:
            return .linkGreen200
        case .light:
            return .brand600
        }
    }

    var logoColor: UIColor {
        switch self {
        case .linkLight:
            return .linkGreen900
        case .light:
            return .textActionPrimary
        }
    }

    var iconTintColor: UIColor {
        switch self {
        case .linkLight:
            return .linkGreen500
        case .light:
            return .iconActionPrimary
        }
    }

    var iconBackgroundColor: UIColor {
        switch self {
        case .linkLight:
            return .linkGreen50
        case .light:
            return .brand25
        }
    }

    var textActionColor: UIColor {
        switch self {
        case .linkLight:
            return .linkGreen500
        case .light:
            return .brand600
        }
    }

    var spinnerColor: UIColor {
        switch self {
        case .linkLight:
            return .linkGreen200
        case .light:
            return .brand500
        }
    }

    var borderColor: UIColor {
        switch self {
        case .linkLight:
            return .linkGreen200
        case .light:
            return .brand600
        }
    }
}

extension FinancialConnectionsTheme? {
    var spinnerColor: UIColor {
        switch self {
        case .some(let theme):
            return theme.spinnerColor
        case .none:
            return .neutral200
        }
    }
}
