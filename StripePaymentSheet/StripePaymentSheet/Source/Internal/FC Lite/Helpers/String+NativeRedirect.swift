//
//  String+NativeRedirect.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-11-20.
//

import Foundation

private let nativeRedirectPrefix = "stripe://financial-connections-lite/auth_redirect/"

extension String {
    func droppingNativeRedirectPrefix() -> String {
        guard self.hasPrefix(nativeRedirectPrefix) else {
            return self
        }
        return String(self.dropFirst(nativeRedirectPrefix.count))
    }

    var hasNativeRedirectPrefix: Bool {
        return self.hasPrefix(nativeRedirectPrefix)
    }
}
