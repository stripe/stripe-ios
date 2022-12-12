//
//  String+Sha256.swift
//  StripeCardScanTests
//
//  Created by Scott Grant on 9/21/22.
//

import Foundation

extension String {
    /// A String containing the Sha256 hash of this String's contents.
    var sha256: String? {
        guard let stringData = self.data(using: .utf8) else {
            return nil
        }

        return stringData.sha256
    }
}
