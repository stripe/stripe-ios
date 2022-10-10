//
//  String+StripePaymentSheet.swift
//  StripePaymentSheet
//
//  Created by David Estes on 6/30/22.
//

import Foundation


extension String {
    var sha256: String? {
        guard let stringData = self.data(using: .utf8) else {
            return nil
        }

        return stringData.sha256
    }
}
