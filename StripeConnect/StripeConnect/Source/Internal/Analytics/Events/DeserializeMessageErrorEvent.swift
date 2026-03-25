//
//  DeserializeMessageErrorEvent.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/4/24.
//

import Foundation

/// An error occurred deserializing the JSON payload from a web message.
struct DeserializeMessageErrorEvent: ConnectAnalyticEvent {
    struct Metadata: Encodable, Equatable {
        /// The name of the message
        let message: String

        /// The error identifier
        let error: String

        /// The error's description, if there is one.
        let errorDescription: String?

        /// The `pageViewID` from the web view
        /// - Note: May be null if not yet sent from web
        let pageViewId: String?

        init(message: String, error: Error, pageViewId: String?) {
            self.message = message
            self.error = error.analyticsIdentifier
            self.errorDescription = (error as NSError).userInfo[NSDebugDescriptionErrorKey] as? String
            self.pageViewId = pageViewId
        }
      }

    let name = "component.web.error.deserialize_message"
    let metadata: Metadata
}
