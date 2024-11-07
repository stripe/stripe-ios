//
//  ConnectAnalyticsClient.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/1/24.
//

@_spi(STP) import StripeCore

/// Wraps `AnalyticsClientV2` with some Connect-specific helpers
@dynamicMemberLookup
class ComponentAnalyticsClient {
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

    func logComponentViewed(viewedAt: Date) {
        componentFirstViewedTime = viewedAt
        log(event: ComponentViewedEvent())
    }

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

    func logUnexpectedLoadErrorType(type: String) {
        log(event: UnexpectedLoadErrorTypeEvent(metadata: .init(
            errorType: type,
            pageViewId: pageViewId
        )))
    }

    func logUnexpectedSetterEvent(setter: String) {
        log(event: UnrecognizedSetterEvent(metadata: .init(
            setter: setter,
            pageViewId: pageViewId
        )))
    }

    func logDeserializeMessageErrorEvent(message: String, error: Error) {
        log(event: DeserializeMessageErrorEvent(metadata: .init(
            message: message,
            error: error,
            pageViewId: pageViewId
        )))
    }

    func logAuthenticatedWebViewOpenedEvent(id: String) {
        log(event: AuthenticatedWebViewOpenedEvent(metadata: .init(
            authenticatedWebViewId: id,
            pageViewId: pageViewId
        )))
    }

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

    func logAuthenticatedWebViewEventComplete(id: String, error: Error) {
        log(event: AuthenticatedWebViewErrorEvent(metadata: .init(
            authenticatedWebViewId: id,
            error: error,
            pageViewId: pageViewId
        )))
    }

    /// Catch-all for mobile client-side errors
    func logClientError(_ error: Error,
                        file: StaticString = #file,
                        line: UInt = #line) {
        client.log(
            eventName: "client_error",
            parameters: AnalyticsClientV2.serialize(
                error: error,
                filePath: file,
                line: line
            )
        )
    }
}

extension ComponentAnalyticsClient.CommonFields {
    init(apiClient: STPAPIClient,
         component: ComponentType,
         componentInstance: UUID = .init()
    ) {
        // Reuse logic in ConnectJSURLParams to determine when to use publicKey
        // platformId + livemode
        let params = ConnectJSURLParams(component: component, apiClient: apiClient)

        // Ensures a secret key is never logged to analytics in the event
        // the platform uses a secret key in their app
        var publicKey = params.publicKey
        if publicKey != nil {
            publicKey = apiClient.sanitizedPublishableKey
        }

        self.init(
            publishableKey: publicKey,
            platformId: params.platformIdOverride,
            merchantId: params.merchantIdOverride,
            livemode: params.livemodeOverride,
            component: params.component,
            componentInstance: componentInstance
        )
    }
}
