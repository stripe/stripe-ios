//
//  PageLoadErrorEvent.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/4/24.
//

/// The SDK receives a non-200 status code or error loading the web view, other than “Internet connectivity” errors.
struct PageLoadErrorEvent: ConnectAnalyticEvent {
    struct Metadata: Encodable {
        /// http status code if the error was a non-200 response
        let status: Int?

        /// Error identifier for non http status type errors
        let error: String?

        /// The URL of the page, excluding hashtag params
        let url: String?

        init(status: Int, url: URL?) {
            self.status = status
            self.error = nil
            self.url = url?.sanitizedForLogging
        }

        init(error: Error, url: URL?) {
            self.status = nil
            self.error = error.analyticsIdentifier
            self.url = url?.sanitizedForLogging
        }
    }

    let name = "component.web.error.page_load"
    let metadata: Metadata
}
