//
//  String+StripeCore.swift
//  StripeCore
//
//  Created by Mel Ludowise on 9/16/21.
//

import Foundation

@_spi(STP) public extension String {
    func stp_stringByRemovingCharacters(from characterSet: CharacterSet) -> String {
        return String(unicodeScalars.filter { !characterSet.contains($0) })
    }

    var isSecretKey: Bool {
        return self.hasPrefix("sk_")
    }
}
