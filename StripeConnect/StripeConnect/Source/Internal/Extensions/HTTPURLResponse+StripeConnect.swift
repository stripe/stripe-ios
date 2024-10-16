//
//  HTTPURLResponse+StripeConnect.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/14/24.
//

import Foundation

extension HTTPURLResponse {
    /// Returns true when the status code of the response is considered an error for a web view
    var hasErrorStatus: Bool {
        /*
         100–399 status codes are not considered errors as the web view
         will gracefully handle these. Only 400+ are cases where the component
         cannot be loaded.
         */
        statusCode >= 400
    }
}
