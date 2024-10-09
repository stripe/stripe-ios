//
//  URL+Valid.swift
//  StripeConnect Example
//
//  Created by Chris Mays on 9/20/24.
//

import UIKit

extension URL {
    var isValid: Bool {
        UIApplication.shared.canOpenURL(self)
    }
}
