//
//  FinancialConnectionsErrorEvent.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 12/15/24.
//

/// The FinancialConnectionsSheet returned an error
struct FinancialConnectionsErrorEvent: ConnectAnalyticEvent {
    struct Metadata: Encodable, Equatable {
        /// ID of the FinancialConnectionsSession
        let sessionId: String

        /// The error identifier
        let error: String

        /// The error's description, if there is one.
        let errorDescription: String?

        /// The `pageViewID` from the web view
        /// - Note: May be null if not yet sent from web
        let pageViewId: String?

        init(sessionId: String, error: Error, pageViewId: String?) {
            self.sessionId = sessionId
            self.error = error.analyticsIdentifier
            self.errorDescription = (error as NSError).userInfo[NSDebugDescriptionErrorKey] as? String
            self.pageViewId = pageViewId
        }
      }

    let name = "component.web.error.deserialize_message"
    let metadata: Metadata
}
