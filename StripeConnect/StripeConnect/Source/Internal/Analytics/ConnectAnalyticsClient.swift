//
//  ConnectAnalyticsClient.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/1/24.
//

@_spi(STP) import StripeCore

/// Wraps `AnalyticsClientV2` with some Connect-specific helpers
@dynamicMemberLookup
class ConnectAnalyticsClient {
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

        /// The `pageViewID` returned from the `PageDidLoadMessageHandler`
        var pageViewId: String?
    }

    let client: AnalyticsClientV2Protocol

    private(set) var commonFields: CommonFields

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
            dict["event_metadata"] = try event.eventMetadata.jsonDictionary(with: .analyticsEncoder)
            client.log(eventName: event.eventName, parameters: dict)
        } catch {
            // We were unable to encode the analytic parameters
            log(error: error)
        }
    }

    /// Logs
    func log(error: Error,
             file: StaticString = #file,
             line: UInt = #line) {
        // TODO: Is this the best name?
        client.log(eventName: "generic_error", parameters: AnalyticsClientV2.serialize(error: error, filePath: file, line: line))
    }
}

extension ConnectAnalyticsClient.CommonFields {
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
