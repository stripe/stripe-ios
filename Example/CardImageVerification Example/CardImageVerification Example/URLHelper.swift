//
//  URLHelper.swift
//  CardImageVerification Example
//
//  Created by Jaime Park on 11/18/21.
//

import Foundation

enum URLHelper: String {
    case cardSet = "card-set/checkout"
    case cardAdd = "card-add/checkout"
    case verify = "verify"

        // If you want to edit our backend, visit https://codesandbox.io/p/devbox/d7sjq9, login, and fork.
    private static let baseURL: URL = URL(string: "https://stripe-card-scan-civ-example-app.stripedemos.com")!
    var verifyURL: URL { return URLHelper.baseURL.appendingPathComponent(self.rawValue) }
}
