//
//  CheckoutControllerLoader.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

@MainActor
enum CheckoutControllerLoader {
    struct PaymentElementInitializationParameters {
        let flowController: FlowControllerInitializationParameters
        let embedded: EmbeddedPaymentElementInitializationParameters
    }

    struct FlowControllerInitializationParameters {
        let configuration: PaymentSheet.Configuration
        let loadResult: PaymentSheetLoader.LoadResult
        let analyticsHelper: PaymentSheetAnalyticsHelper
    }

    struct EmbeddedPaymentElementInitializationParameters {
        let configuration: EmbeddedPaymentElement.Configuration
        let loadResult: PaymentSheetLoader.LoadResult
        let analyticsHelper: PaymentSheetAnalyticsHelper
    }

    /// Loads everything needed to initialize CheckoutController
    static func load(configuration: CheckoutController.Configuration) async throws -> CheckoutController.Session {
        // 1a. Load misc. singletons
        let resources = Task { // Use a Task instead of async let; see PaymentSheetLoader.load.
            await PaymentSheetLoader.loadMiscellaneousSingletons()
        }
        // 1b. Call the /init endpoint
        let response = try await configuration.apiClient.initCheckoutSession(
            checkoutSessionId: CheckoutController.extractSessionId(from: configuration.clientSecret),
            adaptivePricingAllowed: configuration.currencySelectorElement != nil
        )
        let session = CheckoutController.Session(apiResponse: response, localState: .empty, configuration: configuration)
        await resources.value

        // 2. Load Link
        if let paymentElementConfiguration = configuration.paymentElement {
            // TODO: Refactor - loadLink needs a configuration for apiClient, link settings etc. but it should just take them directly rather than us having to create a dummy FC configuration
            let flowControllerConfiguration = makeFlowControllerConfiguration(
                paymentElementConfiguration: paymentElementConfiguration,
                configuration: configuration,
                session: session
            )
            _ = await PaymentSheetLoader.loadLink(
                elementsSession: session.elementsSession,
                configuration: flowControllerConfiguration,
                email: session.email ?? configuration.defaults.email,
                analyticsHelper: ExperimentAnalyticsHelper(integrationShape: .checkoutElements),
                prefetchedEmailAndSourceTask: Task { nil },
                loadTimings: .init(loadingStartDate: Date()),
                isUpdate: false
            )
        }
        STPTelemetryClient.shared.sendTelemetryData() // see https://docs.google.com/document/d/18Aamx_KxPZLHOc1x-9MJriEoTiX7l0N-x0cj8Nk_IYM
        return session
    }

    /// This method contains all the stuff we have to do after (1) init and (2) updates i.e. when the session+elements session changes:
    ///
    /// - Apply Financial Connections settings
    /// - Set analytics to R
    /// - Create a confirmation challenge from the current session settings.
    /// - If PaymentElement is configured, also derive FC/Embedded configurations and layouts, filter
    ///   available and saved payment methods, update analytics context, and start a shared promotions
    ///   fetch in the background.
    ///
    /// - Returns: the challenge and FC/Embedded initialization parameters so the caller can create or update PaymentElement.
    static func handleSessionChange(checkout: CheckoutController) -> (
        confirmationChallenge: ConfirmationChallenge,
        paymentElement: PaymentElementInitializationParameters?
    ) {
        let session = checkout.session
        let elementsSession = session.elementsSession
        PaymentSheetLoader.applyFinancialConnectionsSettings(elementsSession: elementsSession)
        STPAnalyticsClient.sendAnalyticsToRStripe = elementsSession.isAnalyticsToRStripeEnabled
        let confirmationChallenge = ConfirmationChallenge(
            elementsSession: elementsSession,
            stripeAttest: checkout.apiClient.stripeAttest
        )
        guard let paymentElementConfiguration = checkout.configuration.paymentElement else {
            return (confirmationChallenge: confirmationChallenge, paymentElement: nil)
        }
        let fcConfiguration = makeFlowControllerConfiguration(
            paymentElementConfiguration: paymentElementConfiguration,
            configuration: checkout.configuration,
            session: session
        )
        let embeddedConfiguration = makeEmbeddedConfiguration(
            paymentElementConfiguration: paymentElementConfiguration,
            configuration: checkout.configuration,
            session: session
        )

        let intent = Intent.checkout(session)
        let experimentAnalyticsHelper = ExperimentAnalyticsHelper(integrationShape: .checkoutElements)
        PaymentSheetLoader.warnAboutUnactivatedPaymentMethods(elementsSession: elementsSession)
        // Filter PMs
        let paymentMethodTypes = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: intent,
            elementsSession: elementsSession,
            configuration: fcConfiguration, // assume this method returns the same result for Embedded
            logAvailability: true
        )
        // TODO: Define PaymentElement behavior when no supported payment methods remain.
        // Filter saved PMs
        // TODO: this logic should live on the server
        let savedPaymentMethods = PaymentSheetLoader.filterSavedPaymentMethods(
            intent: intent,
            elementsSession: elementsSession,
            configuration: fcConfiguration, // assume this method returns the same result for Embedded
            prefetchedSPMs: nil
        )
        // Create/reuse and update FC analytics helper
        let flowControllerAnalyticsHelper = checkout.paymentElement?.paymentSheetFlowController.analyticsHelper
            ?? PaymentSheetAnalyticsHelper(integrationShape: .flowController, configuration: fcConfiguration)
        let orientation = fcConfiguration.resolveLayout(elementsSession: elementsSession, paymentMethodTypes: paymentMethodTypes)
        flowControllerAnalyticsHelper.didLoad(intent: intent, elementsSession: elementsSession)
        flowControllerAnalyticsHelper.paymentMethodOrientation = orientation
        // Create/reuse and update Embedded analytics helper
        let embeddedAnalyticsHelper = checkout.paymentElement?.embeddedPaymentElement.analyticsHelper
        ?? PaymentSheetAnalyticsHelper(integrationShape: .embedded, configuration: embeddedConfiguration)
        embeddedAnalyticsHelper.didLoad(intent: intent, elementsSession: elementsSession)
        embeddedAnalyticsHelper.paymentMethodOrientation = .vertical
        // Deal with PMM Promotions Helper
        // TODO: Fix Checkout promotions exposure attribution. This uses the FC layout even
        // when the merchant uses Embedded (vertical) or neither UI; the actual UI is unknown here.
        // TODO: Restore Checkout promotions fetch/display analytics with the appropriate context.
        // Leave analyticsHelper nil until then.
        let promotionsHelper = PaymentMethodMessagingPromotionsHelper(
            elementsSession: elementsSession,
            intent: intent,
            configuration: fcConfiguration,
            paymentMethodTypes: paymentMethodTypes,
            experimentAnalyticsHelper: experimentAnalyticsHelper
        )
        promotionsHelper?.fetchData()
        // Return
        let flowControllerLoadResult = PaymentSheetLoader.LoadResult(
            intent: intent,
            elementsSession: elementsSession,
            savedPaymentMethods: savedPaymentMethods,
            paymentMethodTypes: paymentMethodTypes,
            paymentMethodMessagingPromotionsHelper: promotionsHelper,
            paymentMethodOrientation: orientation
        )
        let embeddedLoadResult = PaymentSheetLoader.LoadResult(
            intent: intent,
            elementsSession: elementsSession,
            savedPaymentMethods: savedPaymentMethods,
            paymentMethodTypes: paymentMethodTypes,
            paymentMethodMessagingPromotionsHelper: promotionsHelper,
            paymentMethodOrientation: .vertical
        )
        return (
            confirmationChallenge: confirmationChallenge,
            paymentElement: .init(
                flowController: .init(
                    configuration: fcConfiguration,
                    loadResult: flowControllerLoadResult,
                    analyticsHelper: flowControllerAnalyticsHelper
                ),
                embedded: .init(
                    configuration: embeddedConfiguration,
                    loadResult: embeddedLoadResult,
                    analyticsHelper: embeddedAnalyticsHelper
                )
            )
        )
    }

    private static func makeFlowControllerConfiguration(
        paymentElementConfiguration: PaymentElement.Configuration,
        configuration: CheckoutController.Configuration,
        session: CheckoutController.Session
    ) -> PaymentSheet.Configuration {
        var paymentSheetConfiguration = paymentElementConfiguration.makeFlowControllerConfiguration(
            apiClient: configuration.apiClient,
            returnURL: configuration.returnURL,
            defaults: configuration.defaults,
            merchantDisplayName: configuration.merchantDisplayName ?? session.businessName ?? Bundle.displayName ?? "",
            merchantCountryCode: session.merchantCountryCode,
            userInterfaceStyle: configuration.userInterfaceStyle
        )
        session.applyAddressOverrides(to: &paymentSheetConfiguration)
        return paymentSheetConfiguration
    }

    private static func makeEmbeddedConfiguration(
        paymentElementConfiguration: PaymentElement.Configuration,
        configuration: CheckoutController.Configuration,
        session: CheckoutController.Session
    ) -> EmbeddedPaymentElement.Configuration {
        var embeddedConfiguration = paymentElementConfiguration.makeEmbeddedConfiguration(
            apiClient: configuration.apiClient,
            returnURL: configuration.returnURL,
            defaults: configuration.defaults,
            merchantDisplayName: configuration.merchantDisplayName ?? session.businessName ?? Bundle.displayName ?? "",
            merchantCountryCode: session.merchantCountryCode,
            userInterfaceStyle: configuration.userInterfaceStyle
        )
        session.applyAddressOverrides(to: &embeddedConfiguration)
        return embeddedConfiguration
    }
}
