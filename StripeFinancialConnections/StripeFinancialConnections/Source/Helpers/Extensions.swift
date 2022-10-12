//
//  Extensions.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 11/26/21.
//

import UIKit

extension UIColor {
    static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor(dynamicProvider: {
                switch $0.userInterfaceStyle {
                case .light, .unspecified:
                    return light
                case .dark:
                    return dark
                @unknown default:
                    return light
                }
            })
        }
        return light
    }
}

extension String {
    func dropPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}
