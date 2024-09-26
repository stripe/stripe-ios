//
//  AuthenticatedWebViewError.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/15/24.
//

import Foundation

enum AuthenticatedWebViewError: Int, Error {

    // NOTE: These integer values should remain stable as they are used as
    // error codes in error logging

    /// ASWebAuthenticationSession could not be started
    /// - Note: This can occur if the app is backgrounded when attempting to present the web view
    case cannotStartSession = 0

    /// There's no window on which to present
    case notInViewHierarchy = 1

    /// An ASWebAuthenticationSession is currently already being presented
    case alreadyPresenting = 2
}
