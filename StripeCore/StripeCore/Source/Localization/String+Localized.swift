//
//  String+Localized.swift
//  StripeCore
//
//  Created by Mel Ludowise on 8/4/21.
//

import Foundation

@_spi(STP) public extension String {
    enum Localized {
        public static var close: String {
            return STPLocalizedString("Close", "Text for close button")
        }
    }
}
