//
//  Error+extensions.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/4/24.
//

extension Error {
    var analyticsIdentifier: String {
        let nsError = self as NSError
        return "\(nsError.domain):\(nsError.code)"
    }
}
