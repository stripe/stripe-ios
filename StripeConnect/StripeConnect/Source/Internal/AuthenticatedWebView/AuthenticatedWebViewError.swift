//
//  AuthenticatedWebViewError.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/15/24.
//

enum AuthenticatedWebViewError: Int, Error {

    // NOTE: These integer values should remain stable as they are used as
    // error codes in error logging

    /// ASWebAuthenticationSession could not be started
    case cannotStartSession = 0
    /// There's no window on which to present
    case noWindow = 1
    /// An ASWebAuthenticationSession is currently already being presented
    case alreadyPresenting = 2
}

extension AuthenticatedWebViewError: CustomDebugStringConvertible {
    /// Error message returned to the web layer, used for internal logging only
    var debugDescription: String {
        "\((self as NSError).domain):\((self as NSError).code) \(message)"
    }

    private var message: String {
        switch self {
        case .cannotStartSession:
            "Could not start the authenticated session"
        case .noWindow:
            "Embedded component is not in the view hierarchy"
        case .alreadyPresenting:
            "Already presenting an authenticated web view"
        }
    }
}
