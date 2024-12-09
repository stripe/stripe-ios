//
//  ComponentAnalyticsClient.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/1/24.
//

import Foundation
@_spi(STP) import StripeCore

typealias ComponentAnalyticsClientFactory = (ComponentAnalyticsClient.CommonFields) -> ComponentAnalyticsClient

/// Wraps `AnalyticsClientV2` with Connect-specific analytic properties.
/// An analytics client instance should only be used in one component instance
/// as it tracks component-specific loading metrics.
@dynamicMemberLookup
class ComponentAnalyticsClient {
    /// Fields common to all Connect analytic events
    struct CommonFields: Encodable {
        /// The platform's publishable key
        /// - Note: This will be null when the account is a dashboard account as user keys should never be logged to analytics
        private(set) var publishableKey: String?

        /// ID of the platform account
        /// - Note: This is expected to be null unless originating from a dashboard account,
        ///   otherwise the backend derives this value from the `publishableKey`
        let platformId: String?

        /// ID of the connected account returned by the `AccountSessionClaimedMessageHandler`
        var merchantId: String?

        /// Represents if the account is in live mode
        /// - Note: This is expected to be null unless originating from a dashboard account,
        ///   otherwise the backend derives this value from the `publishableKey`
        let livemode: Bool?

        /// The type of component this analytic is originating from
        let component: ComponentType

        /// A UUID representing a specific component instance.
        /// All events related to this instance will have the same UUID
        let componentInstance: UUID
    }

    let client: AnalyticsClientV2Protocol

    private(set) var commonFields: CommonFields

    /// The `pageViewID` returned from the `PageDidLoadMessageHandler`
    var pageViewId: String?

    /// Time the page began to load
    var loadStart: Date?

    /// Time the component was first viewed
    var componentFirstViewedTime: Date?

    /// If `ComponentWebPageLoadedEvent` was already logged
    private(set) var loggedPageLoaded = false

    /// If `ComponentLoadedEvent` was already logged
    private(set) var loggedComponentLoaded = false

    init(client: AnalyticsClientV2Protocol,
         commonFields: CommonFields) {
        self.client = client
        self.commonFields = commonFields
    }

    // Makes for easy access to common fields
    subscript<T>(dynamicMember keyPath: WritableKeyPath<CommonFields, T>) -> T {
        get { commonFields[keyPath: keyPath] }
        set { commonFields[keyPath: keyPath] = newValue }
    }

    func log<Event: ConnectAnalyticEvent>(event: Event) {
        do {
            var dict = try commonFields.jsonDictionary(with: .analyticsEncoder)
            let metadataDict = try event.metadata.jsonDictionary(with: .analyticsEncoder)
            dict["event_metadata"] = metadataDict

            // Also log metadata fields as first-level fields to make it easier
            // to configure alerting
            dict.mergeAssertingOnOverwrites(metadataDict)

            client.log(eventName: event.name, parameters: dict)
        } catch {
            // We were unable to encode the analytic parameters
            logClientError(error)
        }
    }

    /// The component is viewed on screen (`viewDidAppear` lifecycle event)
    /// - Parameter viewedAt: Time the user viewed the component
    func logComponentViewed(viewedAt: Date) {
        componentFirstViewedTime = viewedAt
        log(event: ComponentViewedEvent())
    }

    /// The web page finished loading (`didFinish navigation` event)
    /// - Parameter loadEnd: Time the web page finished loading
    func logComponentWebPageLoaded(loadEnd: Date) {
        guard !loggedPageLoaded, let loadStart else {
            return
        }

        log(event: ComponentWebPageLoadedEvent(metadata: .init(
            timeToLoad: loadEnd.timeIntervalSince(loadStart)
        )))

        // Prevent the analytic from being logged again in the even the page is reloaded.
        // This can happen if the app is backgrounded for a long period then foregrounded.
        loggedPageLoaded = true
    }

    /// The component is successfully loaded within the web view.
    /// Triggered from `componentDidLoad` message handler from the web view.
    /// - Parameter loadEnd: Time the component finished loading
    func logComponentLoaded(loadEnd: Date) {
        guard !loggedComponentLoaded, let loadStart else {
            return
        }

        log(event: ComponentLoadedEvent(metadata: .init(
            pageViewId: pageViewId,
            timeToLoad: loadEnd.timeIntervalSince(loadStart),
            perceivedTimeToLoad: componentFirstViewedTime.map(loadEnd.timeIntervalSince) ?? 0
        )))

        // Prevent the analytic from being logged again in the even the page is reloaded.
        // This can happen if the app is backgrounded for a long period then foregrounded.
        loggedComponentLoaded = true
    }

    /// The web view sends an onLoadError that can’t be deserialized by the SDK.
    /// - Parameter type: The error `type` property from web
    func logUnexpectedLoadErrorType(type: String) {
        log(event: UnexpectedLoadErrorTypeEvent(metadata: .init(
            errorType: type,
            pageViewId: pageViewId
        )))
    }

    /// If the web view calls `onSetterFunctionCalled` with a `setter` argument the SDK doesn’t know how to handle.
    /// - Parameter setter: The `setter` property sent from web
    func logUnexpectedSetterEvent(setter: String) {
        log(event: UnrecognizedSetterEvent(metadata: .init(
            setter: setter,
            pageViewId: pageViewId
        )))
    }

    /// An error occurred deserializing the JSON payload from a web message.
    /// - Parameters:
    ///   - message: The name of the message
    ///   - error: The error thrown deserializing the message
    func logDeserializeMessageErrorEvent(message: String, error: Error) {
        log(event: DeserializeMessageErrorEvent(metadata: .init(
            message: message,
            error: error,
            pageViewId: pageViewId
        )))
    }

    /// An authenticated web view was opened
    /// - Parameter id: ID for the authenticated web view session (sent in `openAuthenticatedWebView` message
    func logAuthenticatedWebViewOpenedEvent(id: String) {
        log(event: AuthenticatedWebViewOpenedEvent(metadata: .init(
            authenticatedWebViewId: id,
            pageViewId: pageViewId
        )))
    }

    /// The authenticated web view either successfully redirected or was canceled by the user
    /// - Parameters:
    ///   - id: ID for the authenticated web view session (sent in
    ///         `openAuthenticatedWebView` message
    ///   - redirected: True when the authenticated web view successfully redirected back to the app.
    ///                 False if the user closed the view before getting directed back to the app.
    func logAuthenticatedWebViewEventComplete(id: String, redirected: Bool) {
        if redirected {
            log(event: AuthenticatedWebViewRedirectedEvent(metadata: .init(
                authenticatedWebViewId: id,
                pageViewId: pageViewId
            )))
        } else {
            log(event: AuthenticatedWebViewCanceledEvent(metadata: .init(
                authenticatedWebViewId: id,
                pageViewId: pageViewId
            )))
        }
    }

    /// The authenticated web view threw an error and was not successfully redirected back to the app.
    /// - Parameters:
    ///   - id: ID for the authenticated web view session (sent in
    ///         `openAuthenticatedWebView` message
    ///   - error: The error thrown by the authenticated web view
    func logAuthenticatedWebViewEventComplete(id: String, error: Error) {
        log(event: AuthenticatedWebViewErrorEvent(metadata: .init(
            authenticatedWebViewId: id,
            error: error,
            pageViewId: pageViewId
        )))
    }

    /**
     Catch-all for mobile client-side errors
     - Parameters:
       - error: Error to log.
       - file: File name the error was caught on.
       - line: File line number the error was caught on.

     - Note: If the error type conforms to `AnalyticLoggableErrorV2` then all
     properties returned by `analyticLoggableSerializeForLogging()` will be encoded
     into the event payload. Otherwise only domain and code will be encoded.

     File and line number should be explicitly passed if this method is called
     from a helper function, otherwise it's difficult to determine where the
     original error was caught.
     */
    func logClientError(_ error: Error,
                        file: StaticString = #file,
                        line: UInt = #line) {
        var params: [String: Any] = [
            "error": error.analyticsIdentifier,
            "file": ("\(file)" as NSString).lastPathComponent,
            "line": line,
        ]
        if let loggableError = error as? AnalyticLoggableErrorV2 {
            params.mergeAssertingOnOverwrites(loggableError.serializeForV2Logging())
        }

        client.log(
            eventName: "client_error",
            parameters: params
        )
    }
}

extension ComponentAnalyticsClient.CommonFields {
    init(params: ConnectJSURLParams,
         componentInstance: UUID = .init()
    ) {
        self.init(
            publishableKey: params.publicKey?.sanitizedKey,
            platformId: params.platformIdOverride,
            merchantId: params.merchantIdOverride,
            livemode: params.livemodeOverride,
            component: params.component,
            componentInstance: componentInstance
        )
    }
}
