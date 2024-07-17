//
//  FinancialConnectionsTheme.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2024-07-17.
//

import UIKit

enum FinancialConnectionsTheme: String, SafeEnumCodable, Equatable {
    case light = "light"
    case dashboardLight = "dashboard_light"
    case linkLight = "link_light"
    case unparsable
}

extension FinancialConnectionsTheme? {
    var logo: Image {
        switch self {
        case .linkLight:
            return .link_logo
        case .light, .dashboardLight, .unparsable, .none:
            return .stripe_logo
        }
    }

    var primaryColor: UIColor {
        switch self {
        case .linkLight:
            return .linkGreen200
        case .light, .dashboardLight, .unparsable, .none:
            return .brand500
        }
    }

    var primaryButtonTextColor: UIColor {
        switch self {
        case .linkLight:
            return .linkGreen900
        case .light, .dashboardLight, .unparsable, .none:
            return .white
        }
    }

    var logoColor: UIColor {
        switch self {
        case .linkLight:
            return .linkGreen900
        case .light, .dashboardLight, .unparsable, .none:
            return .textActionPrimary
        }
    }
}
