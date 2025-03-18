//
//  NativeFlowController.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 6/6/22.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol NativeFlowControllerDelegate: AnyObject {

    func nativeFlowController(
        _ nativeFlowController: NativeFlowController,
        didFinish result: HostControllerResult
    )

    func nativeFlowController(
        _ nativeFlowController: NativeFlowController,
        didReceiveEvent event: FinancialConnectionsEvent
    )

    func nativeFlowController(
        _ nativeFlowController: NativeFlowController,
        shouldLaunchWebFlow manifest: FinancialConnectionsSessionManifest,
        prefillDetails: WebPrefillDetails
    )
}

class NativeFlowController {

    private let dataManager: NativeFlowDataManager
    private let navigationController: FinancialConnectionsNavigationController
    weak var delegate: NativeFlowControllerDelegate?

    private lazy var navigationBarCloseBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem(
            image: Image.close.makeImage(template: false),
            style: .plain,
            target: self,
            action: #selector(didSelectNavigationBarCloseButton)
        )
        item.tintColor = FinancialConnectionsAppearance.Colors.icon
        item.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 5)
        return item
    }()

    init(
        dataManager: NativeFlowDataManager,
        navigationController: FinancialConnectionsNavigationController
    ) {
        self.dataManager = dataManager
        self.navigationController = navigationController
        navigationController.analyticsClient = dataManager.analyticsClient
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    func startFlow() {
        assert(navigationController.analyticsClient != nil)
        let pane = dataManager.manifest.nextPane
        guard
            let viewController = CreatePaneViewController(
                pane: pane,
                nativeFlowController: self,
                dataManager: dataManager
            )
        else {
            assertionFailure(
                "We should always get a view controller for the first pane: \(dataManager.manifest.nextPane)"
            )
            showTerminalError()
            return
        }
        if pane == .manualEntry && dataManager.manifest.manualEntryMode == .custom {
            // if we ever activate "manual entry only" mode (ex. due to an incident)
            // then also handle "custom manual entry mode"
            closeAuthFlow(customManualEntry: true)
        } else {
            setNavigationControllerViewControllers([viewController], animated: false)
        }
    }

    @objc private func didSelectNavigationBarCloseButton() {
        FeedbackGeneratorAdapter.buttonTapped()
        dataManager.analyticsClient.log(
            eventName: "click.nav_bar.close",
            pane: FinancialConnectionsAnalyticsClient
                .paneFromViewController(navigationController.topViewController)
        )

        let showConfirmationAlert = !(
            navigationController.topViewController is ConsentViewController
            || navigationController.topViewController is SuccessViewController
            || navigationController.topViewController is TerminalErrorViewController
            || ((navigationController.topViewController as? ErrorViewController)?.isTerminal == true)
            || (navigationController.topViewController is InstitutionPickerViewController && !dataManager.manifest.consentAcquired)
        )

        let finishClosingAuthFlow = { [weak self] in
            self?.closeAuthFlow()
        }
        if showConfirmationAlert {
            let closeConfirmationViewController = CloseConfirmationViewController(
                appearance: dataManager.manifest.appearance,
                didSelectClose: {
                    finishClosingAuthFlow()
                }
            )
            closeConfirmationViewController.present(on: navigationController)
        } else {
            finishClosingAuthFlow()
        }
    }

    @objc private func applicationWillEnterForeground() {
        dataManager
            .analyticsClient
            .log(
                eventName: "mobile.app_entered_foreground",
                pane: FinancialConnectionsAnalyticsClient
                    .paneFromViewController(navigationController.topViewController)
            )
    }

    @objc private func applicationDidEnterBackground() {
        dataManager
            .analyticsClient
            .log(
                eventName: "mobile.app_entered_background",
                pane: FinancialConnectionsAnalyticsClient
                    .paneFromViewController(navigationController.topViewController)
            )
    }
}

// MARK: - Core Navigation Helpers

extension NativeFlowController {

    private func setNavigationControllerViewControllers(
        _ viewControllers: [UIViewController],
        animated: Bool = true
    ) {
        dismissVisibleSheetsIfNeeded { [weak self] in
            guard let self else { return }
            viewControllers.forEach { viewController in
                FinancialConnectionsNavigationController.configureNavigationItemForNative(
                    viewController.navigationItem,
                    closeItem: self.navigationBarCloseBarButtonItem,
                    shouldHideLogo: ShouldHideLogoInNavigationBar(
                        forViewController: viewController,
                        reducedBranding: self.dataManager.reducedBranding,
                        merchantLogo: self.dataManager.merchantLogo
                    ),
                    appearance: self.dataManager.manifest.appearance,
                    isTestMode: self.dataManager.manifest.isTestMode
                )
            }
            self.navigationController.setViewControllers(viewControllers, animated: animated)
        }
    }

    private func pushPane(
        _ pane: FinancialConnectionsSessionManifest.NextPane,
        parameters: CreatePaneParameters? = nil,
        animated: Bool,
        // useful for cases where we want to prevent the user from navigating back
        //
        // keeping this logic in `pushPane` is helpful because we want to
        // reuse `skipSuccessPane` and `manualEntryMode == .custom` logic
        clearNavigationStack: Bool = false,
        // Useful for cases where we want to prevent the current pane from being shown again,
        // but not affect any previous panes.
        removeCurrent: Bool = false
    ) {
        if pane == .success && dataManager.manifest.skipSuccessPane == true {
            closeAuthFlow(error: nil)
        } else if pane == .manualEntry && dataManager.manifest.manualEntryMode == .custom {
            closeAuthFlow(customManualEntry: true)
        } else {
            let paneViewController = CreatePaneViewController(
                pane: pane,
                parameters: parameters,
                nativeFlowController: self,
                dataManager: dataManager
            )
            if clearNavigationStack, let paneViewController {
                setNavigationControllerViewControllers([paneViewController], animated: animated)
            } else if removeCurrent, let paneViewController {
                let viewControllers = Array(navigationController.viewControllers.dropLast())
                setNavigationControllerViewControllers(viewControllers + [paneViewController], animated: animated)
            } else {
                pushViewController(paneViewController, animated: animated)
            }
        }
    }

    private func pushViewController(_ viewController: UIViewController?, animated: Bool) {
        dismissVisibleSheetsIfNeeded { [weak self] in
            guard let self else { return }
            if let viewController = viewController {
                FinancialConnectionsNavigationController.configureNavigationItemForNative(
                    viewController.navigationItem,
                    closeItem: self.navigationBarCloseBarButtonItem,
                    shouldHideLogo: ShouldHideLogoInNavigationBar(
                        forViewController: viewController,
                        reducedBranding: self.dataManager.reducedBranding,
                        merchantLogo: self.dataManager.merchantLogo
                    ),
                    appearance: dataManager.manifest.appearance,
                    isTestMode: self.dataManager.manifest.isTestMode
                )
                self.navigationController.pushViewController(viewController, animated: animated)
            } else {
                // when we can't find a view controller to present,
                // show a terminal error
                self.showTerminalError()
            }
        }
    }

    private func presentPaneAsSheet(
        _ pane: FinancialConnectionsSessionManifest.NextPane,
        parameters: CreatePaneParameters? = nil
    ) {
        let paneViewController = CreatePaneViewController(
            pane: pane,
            parameters: parameters,
            nativeFlowController: self,
            dataManager: dataManager,
            panePresentationStyle: .sheet
        )
        guard let paneViewController = paneViewController as? SheetViewController else {
            assertionFailure("expected the pane to always be a sheet if `presentAsSheet` is used")
            pushPane(pane, animated: true)
            return
        }
        paneViewController.present(on: navigationController)
    }

    private func dismissVisibleSheetsIfNeeded(
        animated: Bool = true,
        completionHandler: @escaping () -> Void
    ) {
        if let viewController = navigationController.presentedViewController {
            viewController.dismiss(
                animated: animated,
                completion: { [weak self] in
                    // recursively dismiss any presented VC until
                    // there are none
                    //
                    // this is likely not needed, but it's there as
                    // an extra safe-guard
                    self?.dismissVisibleSheetsIfNeeded(completionHandler: completionHandler)
                }
            )
        } else {
            completionHandler()
        }
    }

    private func dismissCurrentPane(animated: Bool) {
        if
            let sheetViewController = navigationController.presentedViewController as? SheetViewController,
            sheetViewController.panePresentationStyle == .sheet
        {
            sheetViewController.dismiss(animated: animated)
        } else {
            navigationController.popViewController(animated: animated)
        }
    }
}

// MARK: - Other Helpers

extension NativeFlowController {

    private struct PaymentMethodWithIncentiveEligibility {
        let paymentMethod: LinkBankPaymentMethod
        let incentiveEligible: Bool
    }

    private func didSelectAnotherBank() {
        if dataManager.manifest.disableLinkMoreAccounts {
            closeAuthFlow(error: nil)
        } else {
            startResetFlow()
        }
    }

    private func startResetFlow() {
        guard
            let resetFlowViewController = CreatePaneViewController(
                pane: .resetFlow,
                nativeFlowController: self,
                dataManager: dataManager
            )
        else {
            assertionFailure(
                "We should always get a view controller for \(FinancialConnectionsSessionManifest.NextPane.resetFlow)"
            )
            showTerminalError()
            return
        }

        var viewControllers: [UIViewController] = []
        if let consentViewController = navigationController.viewControllers.first as? ConsentViewController {
            viewControllers.append(consentViewController)
        }
        viewControllers.append(resetFlowViewController)

        setNavigationControllerViewControllers(viewControllers, animated: true)
    }

    private func showTerminalError(_ error: Error? = nil) {
        let terminalError: Error
        if let error = error {
            terminalError = error
        } else {
            terminalError = FinancialConnectionsSheetError.unknown(
                debugDescription:
                    "Unknown terminal error. It is likely that we couldn't find a view controller for a specific pane."
            )
        }
        dataManager.terminalError = terminalError  // needs to be set to create `terminalError` pane

        guard
            let terminalErrorViewController = CreatePaneViewController(
                pane: .terminalError,
                nativeFlowController: self,
                dataManager: dataManager
            )
        else {
            assertionFailure(
                "We should always get a view controller for \(FinancialConnectionsSessionManifest.NextPane.terminalError)"
            )
            closeAuthFlow(error: terminalError)
            return
        }
        setNavigationControllerViewControllers([terminalErrorViewController], animated: false)
    }

    // There's at least four types of close cases:
    // 1. User closes, and accounts are returned (or `paymentAccount` or `bankAccountToken`). That's a success.
    // 2. User closes, no accounts are returned, and there's an error. That's a failure.
    // 3. User closes, no accounts are returned, and there's no error. That's a cancel.
    // 4. User closes, and fetching accounts returns an error. That's a failure.
    private func closeAuthFlow(
        customManualEntry: Bool = false,
        error closeAuthFlowError: Error? = nil  // user can also close AuthFlow while looking at an error screen
    ) {
        if customManualEntry {
            // if we don't display manual entry pane, and instead skip it
            // we still want to log that we initiated manual entry
            delegate?.nativeFlowController(
                self,
                didReceiveEvent: FinancialConnectionsEvent(name: .manualEntryInitiated)
            )
        }

        let finishAuthSession: (HostControllerResult) -> Void = { [weak self] result in
            guard let self = self else { return }
            let updatedResult = result.updateWith(self.dataManager.manifest)
            self.delegate?.nativeFlowController(self, didFinish: updatedResult)
        }

        dataManager
            .completeFinancialConnectionsSession(
                terminalError: customManualEntry ? "user_initiated_with_custom_manual_entry" : nil
            )
            .observe(on: .main) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let session):
                    let eventType = "object"
                    if session.status == .cancelled
                        && session.statusDetails?.cancelled?.reason == .customManualEntry
                    {
                        self.logCompleteEvent(
                            type: eventType,
                            status: "custom_manual_entry"
                        )
                        finishAuthSession(.failed(error: FinancialConnectionsCustomManualEntryRequiredError()))
                    } else {
                        if !session.accounts.data.isEmpty || session.paymentAccount != nil
                            || session.bankAccountToken != nil
                        {
                            if dataManager.manifest.isProductInstantDebits {
                                // For Instant Debits, create a payment method and complete with it.
                                createPaymentMethod(for: session) { result in
                                    switch result {
                                    case .success(let linkedBank):
                                        self.delegate?.nativeFlowController(
                                            self,
                                            didReceiveEvent: FinancialConnectionsEvent(
                                                name: .success,
                                                metadata: FinancialConnectionsEvent.Metadata(
                                                    manualEntry: session.paymentAccount?.isManualEntry ?? false
                                                )
                                            )
                                        )
                                        self.logCompleteEvent(
                                            type: eventType,
                                            status: "completed",
                                            numberOfLinkedAccounts: session.accounts.data.count
                                        )
                                        finishAuthSession(.completed(.instantDebits(linkedBank)))
                                    case .failure(let createPaymentError):
                                        self.logCompleteEvent(
                                            type: eventType,
                                            status: "failed",
                                            error: createPaymentError
                                        )
                                        finishAuthSession(.failed(error: createPaymentError))
                                    }
                                }
                            } else {
                                // Otherwise, complete with the existing session details.
                                self.delegate?.nativeFlowController(
                                    self,
                                    didReceiveEvent: FinancialConnectionsEvent(
                                        name: .success,
                                        metadata: FinancialConnectionsEvent.Metadata(
                                            manualEntry: session.paymentAccount?.isManualEntry ?? false
                                        )
                                    )
                                )
                                self.logCompleteEvent(
                                    type: eventType,
                                    status: "completed",
                                    numberOfLinkedAccounts: session.accounts.data.count
                                )
                                finishAuthSession(.completed(.financialConnections(session)))
                            }
                        } else if let closeAuthFlowError = closeAuthFlowError {
                            self.logCompleteEvent(
                                type: eventType,
                                status: "failed",
                                error: closeAuthFlowError
                            )
                            finishAuthSession(.failed(error: closeAuthFlowError))
                        } else {
                            if let terminalError = self.dataManager.terminalError {
                                self.logCompleteEvent(
                                    type: eventType,
                                    status: "failed",
                                    error: terminalError
                                )
                                finishAuthSession(.failed(error: terminalError))
                            } else {
                                self.delegate?.nativeFlowController(
                                    self,
                                    didReceiveEvent: FinancialConnectionsEvent(name: .cancel)
                                )
                                self.logCompleteEvent(
                                    type: eventType,
                                    status: "canceled"
                                )
                                finishAuthSession(.canceled)
                            }
                        }
                    }
                case .failure(let completeFinancialConnectionsSessionError):
                    self.dataManager
                        .analyticsClient
                        .logUnexpectedError(
                            completeFinancialConnectionsSessionError,
                            errorName: "CompleteSessionError",
                            pane: FinancialConnectionsAnalyticsClient
                                .paneFromViewController(self.navigationController.topViewController)
                        )
                    self.logCompleteEvent(
                        type: "error",
                        status: "failed",
                        error: completeFinancialConnectionsSessionError
                    )

                    if let closeAuthFlowError = closeAuthFlowError {
                        finishAuthSession(.failed(error: closeAuthFlowError))
                    } else {
                        finishAuthSession(.failed(error: completeFinancialConnectionsSessionError))
                    }
                }
            }
    }

    private func createPaymentMethod(
        for session: StripeAPI.FinancialConnectionsSession,
        completion: @escaping (Result<InstantDebitsLinkedBank, Error>) -> Void
    ) {
        // Extract bank account ID from the session
        let bankAccountId: String?
        switch session.paymentAccount {
        case .bankAccount(let account):
            bankAccountId = account.id
        case .linkedAccount(let account):
            bankAccountId = account.id
        default:
            bankAccountId = nil
        }

        // Validate bank account ID
        guard let bankAccountId else {
            let error = "InstantDebitsCompletionError: No bank account ID available when trying to create a payment method."
            completion(.failure(FinancialConnectionsSheetError.unknown(debugDescription: error)))
            return
        }

        // Validate consumer session
        guard let consumerSession = dataManager.consumerSession else {
            let error = "InstantDebitsCompletionError: No consumer session available when trying to create a payment method."
            completion(.failure(FinancialConnectionsSheetError.unknown(debugDescription: error)))
            return
        }

        var paymentDetails: RedactedPaymentDetails?
        var bankAccountDetails: BankAccountDetails?

        let elementsSessionContext = dataManager.elementsSessionContext
        let linkMode = elementsSessionContext?.linkMode
        let email = elementsSessionContext?.billingDetails?.email ?? dataManager.consumerSession?.emailAddress
        let phone = elementsSessionContext?.billingDetails?.phone
        dataManager.createPaymentDetails(
            consumerSessionClientSecret: consumerSession.clientSecret,
            bankAccountId: bankAccountId,
            billingAddress: elementsSessionContext?.billingAddress,
            billingEmail: email
        )
        .chained { [weak self] response -> Future<LinkBankPaymentMethod> in
            guard let self else {
                return Promise(error: FinancialConnectionsSheetError.unknown(debugDescription: "data source deallocated"))
            }

            paymentDetails = response.redactedPaymentDetails
            bankAccountDetails = response.redactedPaymentDetails.bankAccountDetails

            // Decide which API to call based on the payment mode
            if let linkMode, linkMode.isPantherPayment {
                return self.dataManager.apiClient.sharePaymentDetails(
                    consumerSessionClientSecret: consumerSession.clientSecret,
                    paymentDetailsId: response.redactedPaymentDetails.id,
                    expectedPaymentMethodType: linkMode.expectedPaymentMethodType,
                    billingEmail: email,
                    billingPhone: phone
                )
                .transformed { $0.paymentMethod }
            } else {
                return self.dataManager.apiClient.paymentMethods(
                    consumerSessionClientSecret: consumerSession.clientSecret,
                    paymentDetailsId: response.redactedPaymentDetails.id,
                    billingDetails: elementsSessionContext?.billingDetails
                )
            }
        }
        .chained { [weak self] paymentMethod -> Future<PaymentMethodWithIncentiveEligibility> in
            guard let self else {
                return Promise(error: FinancialConnectionsSheetError.unknown(debugDescription: "data source deallocated"))
            }

            guard let paymentDetailsID = paymentDetails?.id else {
                return Promise(error: FinancialConnectionsSheetError.unknown(debugDescription: "redactedPaymentDetails cannot be nil"))
            }

            return updateIncentiveEligibility(
                incentiveEligibilitySession: elementsSessionContext?.incentiveEligibilitySession,
                paymentDetailsID: paymentDetailsID,
                consumerSession: consumerSession,
                paymentMethod: paymentMethod
            )
        }
        .observe { [weak self] result in
            switch result {
            case .success(let paymentMethodWithIncentiveEligibility):
                let linkedBank = InstantDebitsLinkedBank(
                    paymentMethod: paymentMethodWithIncentiveEligibility.paymentMethod,
                    bankName: bankAccountDetails?.bankName,
                    last4: bankAccountDetails?.last4,
                    linkMode: linkMode,
                    incentiveEligible: paymentMethodWithIncentiveEligibility.incentiveEligible,
                    linkAccountSessionId: self?.dataManager.manifest.id
                )
                completion(.success(linkedBank))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func updateIncentiveEligibility(
        incentiveEligibilitySession: ElementsSessionContext.IntentID?,
        paymentDetailsID: String,
        consumerSession: ConsumerSessionData,
        paymentMethod: LinkBankPaymentMethod
    ) -> Promise<PaymentMethodWithIncentiveEligibility> {
        guard let incentiveEligibilitySession else {
            // The session isn't eligible for an incentive, so we just continue to finish the flow.
            let result = PaymentMethodWithIncentiveEligibility(
                paymentMethod: paymentMethod,
                incentiveEligible: false
            )
            return Promise(value: result)
        }

        let promise = Promise<PaymentMethodWithIncentiveEligibility>()

        self.dataManager.apiClient.updateAvailableIncentives(
            consumerSessionClientSecret: consumerSession.clientSecret,
            sessionID: incentiveEligibilitySession.id,
            paymentDetailsID: paymentDetailsID
        ).observe { result in
            switch result {
            case .success(let availableIncentives):
                let result = PaymentMethodWithIncentiveEligibility(
                    paymentMethod: paymentMethod,
                    incentiveEligible: availableIncentives.data.isEmpty == false
                )
                promise.resolve(with: result)
            case .failure(let error):
                // We weren't able to determine eligibility, so we assume ineligibility
                // and continue to finish the flow.
                NSLog("Failed to update available incentives: \(error)")
                let result = PaymentMethodWithIncentiveEligibility(
                    paymentMethod: paymentMethod,
                    incentiveEligible: false
                )
                promise.resolve(with: result)
            }
        }

        return promise
    }

    private func logCompleteEvent(
        type: String,
        status: String,
        numberOfLinkedAccounts: Int? = nil,
        error: Error? = nil
    ) {
        var parameters: [String: Any] = [
            "type": type,
            "status": status,
        ]
        parameters["num_linked_accounts"] = numberOfLinkedAccounts
        if let error = error {
            if let stripeError = error as? StripeError,
                case .apiError(let apiError) = stripeError
            {
                parameters["error_type"] = apiError.type.rawValue
                parameters["error_message"] = apiError.message
                parameters["code"] = apiError.code
            } else {
                parameters["error_type"] = (error as NSError).domain
                parameters["error_message"] = (error as NSError).localizedDescription
                parameters["code"] = (error as NSError).code
            }
        }
        dataManager
            .analyticsClient
            .log(
                eventName: "complete",
                parameters: parameters,
                pane: FinancialConnectionsAnalyticsClient
                    .paneFromViewController(navigationController.topViewController)
            )
    }

    private func showErrorPane(
        forError error: Error,
        referrerPane: FinancialConnectionsSessionManifest.NextPane
    ) {
        // the error pane acts as a replacement
        // for the current pane so we need to first
        // dismiss the current pane
        dismissCurrentPane(animated: false)

        dataManager.errorPaneError = error
        dataManager.errorPaneReferrerPane = referrerPane
        pushPane(.unexpectedError, animated: false)
    }
}

// MARK: - ConsentViewControllerDelegate

extension NativeFlowController: ConsentViewControllerDelegate {

    func consentViewController(
        _ viewController: ConsentViewController,
        didConsentWithResult result: ConsentAcquiredResult
    ) {
        delegate?.nativeFlowController(
            self,
            didReceiveEvent: FinancialConnectionsEvent(name: .consentAcquired)
        )

        dataManager.manifest = result.manifest
        dataManager.consumerSession = result.consumerSession
        dataManager.consumerPublishableKey = result.consumerPublishableKey

        let nextPane = result.nextPane
        if nextPane == .networkingLinkLoginWarmup {
            presentPaneAsSheet(nextPane)
        } else {
            pushPane(nextPane, animated: true)
        }
    }

    func consentViewController(
        _ viewController: ConsentViewController,
        didRequestNextPane nextPane: FinancialConnectionsSessionManifest.NextPane,
        nextPaneOrDrawerOnSecondaryCta: String?
    ) {
        let parameters = CreatePaneParameters(
            nextPaneOrDrawerOnSecondaryCta: nextPaneOrDrawerOnSecondaryCta
        )
        if nextPane == .networkingLinkLoginWarmup {
            presentPaneAsSheet(nextPane, parameters: parameters)
        } else {
            pushPane(nextPane, parameters: parameters, animated: true)
        }
    }

    func consentViewControllerDidFailAttestationVerdict(
        _ viewController: ConsentViewController,
        prefillDetails: WebPrefillDetails
    ) {
        delegate?.nativeFlowController(
            self,
            shouldLaunchWebFlow: dataManager.manifest,
            prefillDetails: prefillDetails
        )
    }
}

// MARK: - IDConsentContentViewControllerDelegate

extension NativeFlowController: IDConsentContentViewControllerDelegate {
    func idConsentContentViewController(
        _ viewController: IDConsentContentViewController,
        didRequestNextPane nextPane: FinancialConnectionsSessionManifest.NextPane,
        nextPaneOrDrawerOnSecondaryCta: String?
    ) {
        let parameters = CreatePaneParameters(
            nextPaneOrDrawerOnSecondaryCta: nextPaneOrDrawerOnSecondaryCta
        )
        if nextPane == .networkingLinkLoginWarmup {
            presentPaneAsSheet(nextPane, parameters: parameters)
        } else {
            pushPane(nextPane, parameters: parameters, animated: true)
        }
    }

    func idConsentContentViewController(
        _ viewController: IDConsentContentViewController,
        didConsentWithManifest manifest: FinancialConnectionsSessionManifest
    ) {
        delegate?.nativeFlowController(
            self,
            didReceiveEvent: FinancialConnectionsEvent(name: .consentAcquired)
        )

        dataManager.manifest = manifest

        let nextPane = manifest.nextPane
        if nextPane == .networkingLinkLoginWarmup {
            presentPaneAsSheet(nextPane)
        } else {
            pushPane(nextPane, animated: true)
        }
    }
}

// MARK: - InstitutionPickerViewControllerDelegate

extension NativeFlowController: InstitutionPickerViewControllerDelegate {
    func institutionPickerViewController(
        _ viewController: InstitutionPickerViewController,
        didSelect institution: FinancialConnectionsInstitution
    ) {
        // necessary to pass on institution for `ErrorViewController`
        dataManager.institution = institution
    }

    func institutionPickerViewController(
        _ viewController: InstitutionPickerViewController,
        didFinishSelecting institution: FinancialConnectionsInstitution,
        authSession: FinancialConnectionsAuthSession
    ) {
        delegate?.nativeFlowController(
            self,
            didReceiveEvent: FinancialConnectionsEvent(
                name: .institutionSelected,
                metadata: FinancialConnectionsEvent.Metadata(
                    institutionName: institution.name
                )
            )
        )
        dataManager.institution = institution
        dataManager.authSession = authSession

        if authSession.isOauthNonOptional {
            presentPaneAsSheet(.partnerAuth)
        } else {
            pushPane(.partnerAuth, animated: true)
        }
    }

    func institutionPickerViewController(
        _ viewController: InstitutionPickerViewController,
        didFinishSelecting institution: FinancialConnectionsInstitution,
        payload: FinancialConnectionsSelectInstitution
    ) {
        delegate?.nativeFlowController(
            self,
            didReceiveEvent: FinancialConnectionsEvent(
                name: .institutionSelected,
                metadata: FinancialConnectionsEvent.Metadata(
                    institutionName: institution.name
                )
            )
        )
        dataManager.institution = institution
        dataManager.manifest = payload.manifest
        dataManager.idConsentContent = payload.text?.idConsentContentPane

        pushPane(payload.manifest.nextPane, animated: true, clearNavigationStack: true)
    }

    func institutionPickerViewControllerDidSelectManuallyAddYourAccount(
        _ viewController: InstitutionPickerViewController
    ) {
        pushPane(.manualEntry, animated: true)
    }

    func institutionPickerViewControllerDidSearch(
        _ viewController: InstitutionPickerViewController
    ) {
        delegate?.nativeFlowController(
            self,
            didReceiveEvent: FinancialConnectionsEvent(name: .searchInitiated)
        )
    }

    func institutionPickerViewController(
        _ viewController: InstitutionPickerViewController,
        didReceiveError error: Error
    ) {
        showErrorPane(forError: error, referrerPane: .institutionPicker)
    }
}

// MARK: - PartnerAuthViewControllerDelegate

extension NativeFlowController: PartnerAuthViewControllerDelegate {

    func partnerAuthViewControllerDidRequestToGoBack(_ viewController: PartnerAuthViewController) {
        dataManager.authSession = nil // clear any lingering auth sessions

        switch viewController.panePresentationStyle {
        case .sheet:
            viewController.dismiss(animated: true)
        case .fullscreen:
            navigationController.popViewController(animated: true)
        }
    }

    func partnerAuthViewController(
        _ viewController: PartnerAuthViewController,
        didCompleteWithAuthSession authSession: FinancialConnectionsAuthSession
    ) {
        delegate?.nativeFlowController(
            self,
            didReceiveEvent: FinancialConnectionsEvent(name: .institutionAuthorized)
        )

        dataManager.authSession = authSession

        // This is a weird thing to do, but effectively we don't want to
        // animate for OAuth since we make the authorize call in that case
        // and already have the same loading screen.
        let shouldAnimate = !authSession.isOauthNonOptional
        pushPane(.accountPicker, animated: shouldAnimate)
    }

    func partnerAuthViewController(
        _ viewController: PartnerAuthViewController,
        didReceiveEvent event: FinancialConnectionsEvent
    ) {
        delegate?.nativeFlowController(self, didReceiveEvent: event)
    }

    func partnerAuthViewController(
        _ viewController: PartnerAuthViewController,
        didReceiveError error: Error
    ) {
        dataManager.authSession = nil // clear any lingering auth sessions

        showErrorPane(forError: error, referrerPane: .partnerAuth)
    }

    func partnerAuthViewController(
        _ viewController: PartnerAuthViewController,
        didRequestNextPane nextPane: FinancialConnectionsSessionManifest.NextPane
    ) {
        dataManager.authSession = nil // clear any lingering auth sessions
        pushPane(nextPane, animated: true, removeCurrent: true)
    }
}

// MARK: - AccountPickerViewControllerDelegate

extension NativeFlowController: AccountPickerViewControllerDelegate {

    func accountPickerViewController(
        _ viewController: AccountPickerViewController,
        didSelectAccounts selectedAccounts: [FinancialConnectionsPartnerAccount],
        nextPane: FinancialConnectionsSessionManifest.NextPane,
        customSuccessPaneMessage: String?,
        saveToLinkWithStripeSucceeded: Bool?
    ) {
        dataManager.linkedAccounts = selectedAccounts
        dataManager.customSuccessPaneSubCaption = customSuccessPaneMessage
        if let saveToLinkWithStripeSucceeded {
            dataManager.saveToLinkWithStripeSucceeded = saveToLinkWithStripeSucceeded
        }

        // this prevents an unnecessary push transition when presenting `attachLinkedPaymentAccount`
        //
        // `attachLinkedPaymentAccount` looks the same as the last step of `accountPicker`
        // so navigating to a "Linking account" loading screen can look buggy to the user
        let isAnimated = (nextPane != .attachLinkedPaymentAccount)
        pushPane(nextPane, animated: isAnimated)
    }

    func accountPickerViewControllerDidSelectAnotherBank(_ viewController: AccountPickerViewController) {
        didSelectAnotherBank()
    }

    func accountPickerViewControllerDidSelectManualEntry(_ viewController: AccountPickerViewController) {
        pushPane(.manualEntry, animated: true)
    }

    func accountPickerViewController(
        _ viewController: AccountPickerViewController,
        didReceiveTerminalError error: Error
    ) {
        showTerminalError(error)
    }

    func accountPickerViewController(
        _ viewController: AccountPickerViewController,
        didReceiveEvent event: StripeCore.FinancialConnectionsEvent
    ) {
        delegate?.nativeFlowController(self, didReceiveEvent: event)
    }
}

// MARK: - SuccessViewControllerDelegate

extension NativeFlowController: SuccessViewControllerDelegate {

    func successViewControllerDidSelectDone(_ viewController: SuccessViewController) {
        closeAuthFlow(error: nil)
    }
}

// MARK: - ManualEntryViewControllerDelegate

extension NativeFlowController: ManualEntryViewControllerDelegate {

    func manualEntryViewController(
        _ viewController: ManualEntryViewController,
        didRequestToContinueWithPaymentAccountResource paymentAccountResource:
            FinancialConnectionsPaymentAccountResource,
        accountNumberLast4: String
    ) {
        // #ir-magnesium-presser; keeping accounts selected can lead to them being passed along
        // to the Link signup/save call later in the flow. We don't need them anymore since we know
        // they've failed us in some way at this point.
        dataManager.linkedAccounts = nil

        dataManager.paymentAccountResource = paymentAccountResource
        dataManager.accountNumberLast4 = accountNumberLast4

        if dataManager.manifest.manualEntryUsesMicrodeposits {
            dataManager.customSuccessPaneCaption = STPLocalizedString(
                "Almost there",
                "The title of the success screen that appears when a user manually entered their bank account information."
            )
            dataManager.customSuccessPaneSubCaption = String(
                format: STPLocalizedString(
                    "You can expect micro-deposits to account ••••%@ in 1-2 days and an email with further instructions.",
                    "The subtitle/description of the success screen that appears when a user manually entered their bank account information. It informs the user that their bank account information will have to be verified."
                ),
                accountNumberLast4
            )
        }
        pushPane(paymentAccountResource.nextPane ?? .success, animated: true)
    }
}

// MARK: - ResetFlowViewControllerDelegate

extension NativeFlowController: ResetFlowViewControllerDelegate {

    func resetFlowViewController(
        _ viewController: ResetFlowViewController,
        didSucceedWithManifest manifest: FinancialConnectionsSessionManifest
    ) {
        assert(navigationController.topViewController is ResetFlowViewController)
        if navigationController.topViewController is ResetFlowViewController {
            // remove ResetFlowViewController from the navigation stack
            if navigationController.viewControllers.count == 1 {
                // there's a chance that `ResetFlowViewController`
                // is the only VC on the stack and `popViewController`
                // will not work
                //
                // scenario:
                // 1. be returning Link consumer
                // 2. press "Not Now" from warm up pane
                // 3. go through reset flow
                //    (ex. select down bank scheduled > select another bank)
                navigationController.setViewControllers([], animated: false)
            } else {
                navigationController.popViewController(animated: false)
            }
        }

        // reset all the state because we are starting
        // a new auth session
        dataManager.resetState(withNewManifest: manifest)

        // go to the next pane (likely `institutionPicker`)
        pushPane(manifest.nextPane, animated: false)
    }

    func resetFlowViewController(
        _ viewController: ResetFlowViewController,
        didFailWithError error: Error
    ) {
        closeAuthFlow(error: error)
    }
}

// MARK: - NetworkingLinkSignupViewControllerDelegate

extension NativeFlowController: NetworkingLinkSignupViewControllerDelegate {
    func networkingLinkSignupViewController(
        _ viewController: NetworkingLinkSignupViewController,
        foundReturningConsumerWithSession consumerSession: ConsumerSessionData
    ) {
        dataManager.consumerSession = consumerSession
        pushPane(.networkingSaveToLinkVerification, animated: true)
    }

    func networkingLinkSignupViewControllerDidFinish(
        _ viewController: NetworkingLinkSignupViewController,
        saveToLinkWithStripeSucceeded: Bool?,
        customSuccessPaneMessage: String?,
        withError error: Error?
    ) {
        if let customSuccessPaneMessage {
            dataManager.customSuccessPaneSubCaption = customSuccessPaneMessage
        }
        if saveToLinkWithStripeSucceeded != nil {
            dataManager.saveToLinkWithStripeSucceeded = saveToLinkWithStripeSucceeded
        }
        pushPane(.success, animated: true)
    }

    func networkingLinkSignupViewController(
        _ viewController: NetworkingLinkSignupViewController,
        didReceiveTerminalError error: Error
    ) {
        showTerminalError(error)
    }

    func networkingLinkSignupViewControllerDidFailAttestationVerdict(
        _ viewController: NetworkingLinkSignupViewController,
        prefillDetails: WebPrefillDetails
    ) {
        delegate?.nativeFlowController(
            self,
            shouldLaunchWebFlow: dataManager.manifest,
            prefillDetails: prefillDetails
        )
    }
}

// MARK: - NetworkingLinkLoginWarmupViewControllerDelegate

extension NativeFlowController: NetworkingLinkLoginWarmupViewControllerDelegate {

    func networkingLinkLoginWarmupViewControllerDidFindConsumerSession(
        _ viewController: NetworkingLinkLoginWarmupViewController,
        consumerSession: ConsumerSessionData,
        consumerPublishableKey: String
    ) {
        dataManager.consumerSession = consumerSession
        dataManager.consumerPublishableKey = consumerPublishableKey
    }

    func networkingLinkLoginWarmupViewControllerDidSelectContinue(
        _ viewController: NetworkingLinkLoginWarmupViewController
    ) {
        pushPane(.networkingLinkVerification, animated: true)
    }

    func networkingLinkLoginWarmupViewControllerDidSelectCancel(
        _ viewController: NetworkingLinkLoginWarmupViewController
    ) {
        viewController.dismiss(animated: true)
    }

    func networkingLinkLoginWarmupViewController(
        _ viewController: NetworkingLinkLoginWarmupViewController,
        didSelectSkipWithManifest manifest: FinancialConnectionsSessionManifest
    ) {
        dataManager.manifest = manifest
        pushPane(
            manifest.nextPane,
            animated: true,
            // skipping disables networking, which means
            // we don't want the user to navigate back to
            // the warm-up pane
            clearNavigationStack: true
        )
    }

    func networkingLinkLoginWarmupViewController(
        _ viewController: NetworkingLinkLoginWarmupViewController,
        didReceiveTerminalError error: Error
    ) {
        showTerminalError(error)
    }

    func networkingLinkLoginWarmupViewControllerDidFailAttestationVerdict(
        _ viewController: NetworkingLinkLoginWarmupViewController,
        prefillDetails: WebPrefillDetails
    ) {
        delegate?.nativeFlowController(
            self,
            shouldLaunchWebFlow: dataManager.manifest,
            prefillDetails: prefillDetails
        )
    }
}

// MARK: - TerminalErrorViewControllerDelegate

extension NativeFlowController: TerminalErrorViewControllerDelegate {

    func terminalErrorViewController(
        _ viewController: TerminalErrorViewController,
        didCloseWithError error: Error
    ) {
        closeAuthFlow(error: error)
    }

    func terminalErrorViewControllerDidSelectManualEntry(_ viewController: TerminalErrorViewController) {
        pushPane(.manualEntry, animated: true)
    }
}

// MARK: - AttachLinkedPaymentAccountViewControllerDelegate

extension NativeFlowController: AttachLinkedPaymentAccountViewControllerDelegate {

    func attachLinkedPaymentAccountViewController(
        _ viewController: AttachLinkedPaymentAccountViewController,
        didFinishWithPaymentAccountResource paymentAccountResource: FinancialConnectionsPaymentAccountResource,
        saveToLinkWithStripeSucceeded: Bool?
    ) {
        if saveToLinkWithStripeSucceeded != nil {
            dataManager.saveToLinkWithStripeSucceeded = saveToLinkWithStripeSucceeded
        }
        pushPane(paymentAccountResource.nextPane ?? .success, animated: true)
    }

    func attachLinkedPaymentAccountViewControllerDidSelectAnotherBank(
        _ viewController: AttachLinkedPaymentAccountViewController
    ) {
        didSelectAnotherBank()
    }

    func attachLinkedPaymentAccountViewControllerDidSelectManualEntry(
        _ viewController: AttachLinkedPaymentAccountViewController
    ) {
        pushPane(.manualEntry, animated: true)
    }

    func attachLinkedPaymentAccountViewController(
        _ viewController: AttachLinkedPaymentAccountViewController,
        didReceiveEvent event: FinancialConnectionsEvent
    ) {
        delegate?.nativeFlowController(self, didReceiveEvent: event)
    }
}

// MARK: - NetworkingLinkVerificationViewControllerDelegate

extension NativeFlowController: NetworkingLinkVerificationViewControllerDelegate {
    func networkingLinkVerificationViewController(
        _ viewController: NetworkingLinkVerificationViewController,
        didRequestNextPane nextPane: FinancialConnectionsSessionManifest.NextPane,
        consumerSession: ConsumerSessionData?,
        preventBackNavigation: Bool
    ) {
        dataManager.consumerSession = consumerSession
        pushPane(nextPane, animated: true, clearNavigationStack: preventBackNavigation)
    }

    func networkingLinkVerificationViewController(
        _ viewController: NetworkingLinkVerificationViewController,
        didReceiveTerminalError error: Error
    ) {
        showTerminalError(error)
    }
}

// MARK: - LinkAccountPickerViewControllerDelegate

extension NativeFlowController: LinkAccountPickerViewControllerDelegate {

    func linkAccountPickerViewController(
        _ viewController: LinkAccountPickerViewController,
        didSelectAccounts selectedAccounts: [FinancialConnectionsPartnerAccount]
    ) {
        dataManager.linkedAccounts = selectedAccounts
    }

    func linkAccountPickerViewController(
        _ viewController: LinkAccountPickerViewController,
        requestedPartnerAuthWithInstitution institution: FinancialConnectionsInstitution
    ) {
        dataManager.institution = institution
        pushPane(.partnerAuth, animated: true)
    }

    func linkAccountPickerViewController(
        _ viewController: LinkAccountPickerViewController,
        requestedBankAuthRepairWithInstitution institution: FinancialConnectionsInstitution,
        forAuthorization authorization: String
    ) {
        dataManager.institution = institution
        dataManager.pendingRelinkAuthorization = authorization
        pushPane(.bankAuthRepair, animated: true, clearNavigationStack: true)
    }

    func linkAccountPickerViewController(
        _ viewController: LinkAccountPickerViewController,
        didRequestNextPane nextPane: FinancialConnectionsSessionManifest.NextPane,
        hideBackButtonOnNextPane: Bool
    ) {
        pushPane(nextPane, animated: true, clearNavigationStack: hideBackButtonOnNextPane)
    }

    func linkAccountPickerViewController(
        _ viewController: LinkAccountPickerViewController,
        didRequestNextPane nextPane: FinancialConnectionsSessionManifest.NextPane,
        customSuccessPaneCaption: String,
        customSuccessPaneSubCaption: String
    ) {
        dataManager.customSuccessPaneCaption = customSuccessPaneCaption
        dataManager.customSuccessPaneSubCaption = customSuccessPaneSubCaption
        pushPane(nextPane, animated: true)
    }

    func linkAccountPickerViewController(
        _ viewController: LinkAccountPickerViewController,
        didReceiveTerminalError error: Error
    ) {
        showTerminalError(error)
    }

    func linkAccountPickerViewController(
        _ viewController: LinkAccountPickerViewController,
        didReceiveEvent event: StripeCore.FinancialConnectionsEvent
    ) {
        delegate?.nativeFlowController(self, didReceiveEvent: event)
    }
}

// MARK: - NetworkingSaveToLinkVerificationDelegate

extension NativeFlowController: NetworkingSaveToLinkVerificationViewControllerDelegate {

    func networkingSaveToLinkVerificationViewControllerDidFinish(
        _ viewController: NetworkingSaveToLinkVerificationViewController,
        saveToLinkWithStripeSucceeded: Bool?,
        customSuccessPaneMessage: String?
    ) {
        if saveToLinkWithStripeSucceeded != nil {
            dataManager.saveToLinkWithStripeSucceeded = saveToLinkWithStripeSucceeded
        }
        dataManager.customSuccessPaneSubCaption = customSuccessPaneMessage
        pushPane(.success, animated: true)
    }

    func networkingSaveToLinkVerificationViewController(
        _ viewController: NetworkingSaveToLinkVerificationViewController,
        didReceiveTerminalError error: Error
    ) {
        showTerminalError(error)
    }
}

// MARK: - NetworkingLinkStepUpVerificationViewControllerDelegate

extension NativeFlowController: NetworkingLinkStepUpVerificationViewControllerDelegate {

    func networkingLinkStepUpVerificationViewController(
        _ viewController: NetworkingLinkStepUpVerificationViewController,
        didCompleteVerificationWithInstitution institution: FinancialConnectionsInstitution?,
        nextPane: FinancialConnectionsSessionManifest.NextPane,
        customSuccessPaneCaption: String?,
        customSuccessPaneSubCaption: String?
    ) {
        dataManager.institution = institution
        dataManager.customSuccessPaneCaption = customSuccessPaneCaption
        dataManager.customSuccessPaneSubCaption = customSuccessPaneSubCaption
        pushPane(nextPane, animated: true)
    }

    func networkingLinkStepUpVerificationViewController(
        _ viewController: NetworkingLinkStepUpVerificationViewController,
        didReceiveTerminalError error: Error
    ) {
        showTerminalError(error)
    }
}

// MARK: - LinkLoginViewControllerDelegate

extension NativeFlowController: LinkLoginViewControllerDelegate {
    func linkLoginViewController(
        _ viewController: LinkLoginViewController,
        foundReturningUserWith lookupConsumerSessionResponse: LookupConsumerSessionResponse
    ) {
        dataManager.consumerPublishableKey = lookupConsumerSessionResponse.publishableKey
        dataManager.consumerSession = lookupConsumerSessionResponse.consumerSession
        pushPane(.networkingLinkVerification, animated: true)
    }

    func linkLoginViewController(
        _ viewController: LinkLoginViewController,
        receivedLinkSignUpResponse linkSignUpResponse: LinkSignUpResponse
    ) {
        dataManager.consumerPublishableKey = linkSignUpResponse.publishableKey
        dataManager.consumerSession = linkSignUpResponse.consumerSession
    }

    func linkLoginViewController(
        _ viewController: LinkLoginViewController,
        signedUpAttachedAndSynchronized synchronizePayload: FinancialConnectionsSynchronize
    ) {
        dataManager.manifest = synchronizePayload.manifest
        pushPane(synchronizePayload.manifest.nextPane, animated: true, clearNavigationStack: true)
    }

    func linkLoginViewController(
        _ viewController: LinkLoginViewController,
        didReceiveTerminalError error: any Error
    ) {
        showTerminalError(error)
    }

    func linkLoginViewControllerDidFailAttestationVerdict(
        _ viewController: LinkLoginViewController,
        prefillDetails: WebPrefillDetails
    ) {
        delegate?.nativeFlowController(
            self,
            shouldLaunchWebFlow: dataManager.manifest,
            prefillDetails: prefillDetails
        )
    }
}

// MARK: - ErrorViewControllerDelegate

extension NativeFlowController: ErrorViewControllerDelegate {
    func errorViewControllerDidSelectAnotherBank(_ viewController: ErrorViewController) {
        didSelectAnotherBank()
    }

    func errorViewControllerDidSelectManualEntry(_ viewController: ErrorViewController) {
        pushPane(.manualEntry, animated: true)
    }

    func errorViewController(
        _ viewController: ErrorViewController,
        didSelectCloseWithError error: Error
    ) {
        closeAuthFlow(error: error)
    }
}

// MARK: - Static Helpers

private func CreatePaneViewController(
    pane: FinancialConnectionsSessionManifest.NextPane,
    parameters: CreatePaneParameters? = nil,
    nativeFlowController: NativeFlowController,
    dataManager: NativeFlowDataManager,
    panePresentationStyle: PanePresentationStyle = .fullscreen
) -> UIViewController? {
    let viewController: UIViewController?
    switch pane {
    case .accountPicker:
        if let authSession = dataManager.authSession, let institution = dataManager.institution {
            let accountPickerDataSource = AccountPickerDataSourceImplementation(
                apiClient: dataManager.apiClient,
                clientSecret: dataManager.clientSecret,
                accountPickerPane: dataManager.accountPickerPane,
                authSession: authSession,
                manifest: dataManager.manifest,
                institution: institution,
                analyticsClient: dataManager.analyticsClient,
                reduceManualEntryProminenceInErrors: dataManager.reduceManualEntryProminenceInErrors,
                dataAccessNotice: dataManager.consentPaneModel?.dataAccessNotice,
                consumerSessionClientSecret: dataManager.consumerSession?.clientSecret,
                isRelink: dataManager.pendingRelinkAuthorization != nil
            )
            let accountPickerViewController = AccountPickerViewController(dataSource: accountPickerDataSource)
            accountPickerViewController.delegate = nativeFlowController
            viewController = accountPickerViewController
        } else {
            assertionFailure("Code logic error. Missing parameters for \(pane).")
            viewController = nil
        }
    case .attachLinkedPaymentAccount:
        if let institution = dataManager.institution,
           let linkedAccountId = dataManager.linkedAccounts?.first?.linkedAccountId
        {
            let dataSource = AttachLinkedPaymentAccountDataSourceImplementation(
                apiClient: dataManager.apiClient,
                clientSecret: dataManager.clientSecret,
                manifest: dataManager.manifest,
                institution: institution,
                linkedAccountId: linkedAccountId,
                analyticsClient: dataManager.analyticsClient,
                authSessionId: dataManager.authSession?.id,
                consumerSessionClientSecret: dataManager.consumerSession?.clientSecret,
                reduceManualEntryProminenceInErrors: dataManager.reduceManualEntryProminenceInErrors
            )
            let attachedLinkedPaymentAccountViewController = AttachLinkedPaymentAccountViewController(
                dataSource: dataSource
            )
            attachedLinkedPaymentAccountViewController.delegate = nativeFlowController
            viewController = attachedLinkedPaymentAccountViewController
        } else {
            assertionFailure("Code logic error. Missing parameters for \(pane).")
            viewController = nil
        }
    case .bankAuthRepair:
        if let institution = dataManager.institution, let relinkAuthorization = dataManager.pendingRelinkAuthorization {
            let partnerAuthDataSource = PartnerAuthDataSourceImplementation(
                authSession: dataManager.authSession,
                institution: institution,
                manifest: dataManager.manifest,
                relinkAuthorization: relinkAuthorization,
                returnURL: dataManager.returnURL,
                apiClient: dataManager.apiClient,
                clientSecret: dataManager.clientSecret,
                analyticsClient: dataManager.analyticsClient
            )
            let partnerAuthViewController = PartnerAuthViewController(
                dataSource: partnerAuthDataSource,
                panePresentationStyle: panePresentationStyle
            )
            partnerAuthViewController.delegate = nativeFlowController
            viewController = partnerAuthViewController
        } else {
            assertionFailure("Code logic error. Missing parameters for \(pane).")
            viewController = nil
        }
    case .consent:
        if let consentPaneModel = dataManager.consentPaneModel {
            let consentDataSource = ConsentDataSourceImplementation(
                manifest: dataManager.manifest,
                consent: consentPaneModel,
                merchantLogo: dataManager.merchantLogo,
                apiClient: dataManager.apiClient,
                clientSecret: dataManager.clientSecret,
                analyticsClient: dataManager.analyticsClient,
                elementsSessionContext: dataManager.elementsSessionContext
            )
            let consentViewController = ConsentViewController(dataSource: consentDataSource)
            consentViewController.delegate = nativeFlowController
            viewController = consentViewController
        } else {
            assertionFailure("Code logic error. Missing parameters for \(pane).")
            viewController = nil
        }
    case .idConsentContent:
        if let idConsentContent = dataManager.idConsentContent {
            let idConsentContentDataSource = IDConsentContentDataSourceImplementation(
                manifest: dataManager.manifest,
                idConsentContent: idConsentContent,
                apiClient: dataManager.apiClient,
                clientSecret: dataManager.clientSecret,
                analyticsClient: dataManager.analyticsClient
            )
            let idConsentContentViewController = IDConsentContentViewController(dataSource: idConsentContentDataSource)
            idConsentContentViewController.delegate = nativeFlowController
            viewController = idConsentContentViewController
        } else {
            assertionFailure("Code logic error. Missing parameters for \(pane).")
            viewController = nil
        }
    case .institutionPicker:
        let dataSource = InstitutionAPIDataSource(
            manifest: dataManager.manifest,
            apiClient: dataManager.apiClient,
            clientSecret: dataManager.clientSecret,
            analyticsClient: dataManager.analyticsClient
        )
        let picker = InstitutionPickerViewController(dataSource: dataSource)
        picker.delegate = nativeFlowController
        viewController = picker
    case .linkAccountPicker:
        if let consumerSession = dataManager.consumerSession {
            let linkAccountPickerDataSource = LinkAccountPickerDataSourceImplementation(
                manifest: dataManager.manifest,
                apiClient: dataManager.apiClient,
                analyticsClient: dataManager.analyticsClient,
                clientSecret: dataManager.clientSecret,
                consumerSession: consumerSession,
                dataAccessNotice: dataManager.consentPaneModel?.dataAccessNotice
            )
            let linkAccountPickerViewController = LinkAccountPickerViewController(
                dataSource: linkAccountPickerDataSource
            )
            linkAccountPickerViewController.delegate = nativeFlowController
            viewController = linkAccountPickerViewController
        } else {
            assertionFailure("Code logic error. Missing parameters for \(pane).")
            viewController = nil
        }
    case .linkConsent:
        assertionFailure("Not supported")
        viewController = nil
    case .linkLogin:
        let linkLoginDataSource = LinkLoginDataSourceImplementation(
            manifest: dataManager.manifest,
            analyticsClient: dataManager.analyticsClient,
            clientSecret: dataManager.clientSecret,
            returnURL: dataManager.returnURL,
            apiClient: dataManager.apiClient,
            elementsSessionContext: dataManager.elementsSessionContext
        )
        let linkLoginViewController = LinkLoginViewController(dataSource: linkLoginDataSource)
        linkLoginViewController.delegate = nativeFlowController
        viewController = linkLoginViewController
    case .manualEntry:
        nativeFlowController.delegate?.nativeFlowController(
            nativeFlowController,
            didReceiveEvent: FinancialConnectionsEvent(name: .manualEntryInitiated)
        )

        let dataSource = ManualEntryDataSourceImplementation(
            apiClient: dataManager.apiClient,
            clientSecret: dataManager.clientSecret,
            manifest: dataManager.manifest,
            analyticsClient: dataManager.analyticsClient,
            consumerSessionClientSecret: dataManager.consumerSession?.clientSecret
        )
        let manualEntryViewController = ManualEntryViewController(dataSource: dataSource)
        manualEntryViewController.delegate = nativeFlowController
        viewController = manualEntryViewController
    case .networkingLinkSignupPane:
        let networkingLinkSignupDataSource = NetworkingLinkSignupDataSourceImplementation(
            manifest: dataManager.manifest,
            selectedAccounts: dataManager.linkedAccounts,
            returnURL: dataManager.returnURL,
            apiClient: dataManager.apiClient,
            clientSecret: dataManager.clientSecret,
            analyticsClient: dataManager.analyticsClient,
            elementsSessionContext: dataManager.elementsSessionContext
        )
        let networkingLinkSignupViewController = NetworkingLinkSignupViewController(
            dataSource: networkingLinkSignupDataSource
        )
        networkingLinkSignupViewController.delegate = nativeFlowController
        viewController = networkingLinkSignupViewController
    case .networkingLinkVerification:
        if let consumerSession = dataManager.consumerSession {
            let networkingLinkVerificationDataSource = NetworkingLinkVerificationDataSourceImplementation(
                manifest: dataManager.manifest,
                apiClient: dataManager.apiClient,
                clientSecret: dataManager.clientSecret,
                returnURL: dataManager.returnURL,
                consumerSession: consumerSession,
                analyticsClient: dataManager.analyticsClient
            )
            let networkingLinkVerificationViewController = NetworkingLinkVerificationViewController(dataSource: networkingLinkVerificationDataSource)
            networkingLinkVerificationViewController.delegate = nativeFlowController
            viewController = networkingLinkVerificationViewController
        } else {
            assertionFailure("Code logic error. Missing parameters for \(pane).")
            viewController = nil
        }
    case .networkingSaveToLinkVerification:
        if let consumerSession = dataManager.consumerSession {
            let networkingSaveToLinkVerificationDataSource = NetworkingSaveToLinkVerificationDataSourceImplementation(
                manifest: dataManager.manifest,
                consumerSession: consumerSession,
                selectedAccounts: dataManager.linkedAccounts,
                apiClient: dataManager.apiClient,
                clientSecret: dataManager.clientSecret,
                analyticsClient: dataManager.analyticsClient
            )
            let networkingSaveToLinkVerificationViewController = NetworkingSaveToLinkVerificationViewController(
                dataSource: networkingSaveToLinkVerificationDataSource
            )
            networkingSaveToLinkVerificationViewController.delegate = nativeFlowController
            viewController = networkingSaveToLinkVerificationViewController
        } else {
            assertionFailure("Code logic error. Missing parameters for \(pane).")
            viewController = nil
        }
    case .networkingLinkStepUpVerification:
        if
            let consumerSession = dataManager.consumerSession,
            let selectedAccountIds = dataManager.linkedAccounts?.map({ $0.id })
        {
            let networkingLinkStepUpVerificationDataSource = NetworkingLinkStepUpVerificationDataSourceImplementation(
                consumerSession: consumerSession,
                selectedAccountIds: selectedAccountIds,
                manifest: dataManager.manifest,
                apiClient: dataManager.apiClient,
                clientSecret: dataManager.clientSecret,
                analyticsClient: dataManager.analyticsClient
            )
            let networkingLinkStepUpVerificationViewController = NetworkingLinkStepUpVerificationViewController(
                dataSource: networkingLinkStepUpVerificationDataSource
            )
            networkingLinkStepUpVerificationViewController.delegate = nativeFlowController
            viewController = networkingLinkStepUpVerificationViewController
        } else {
            assertionFailure("Code logic error. Missing parameters for \(pane).")
            viewController = nil
        }
    case .partnerAuth:
        if let institution = dataManager.institution {
            let partnerAuthDataSource = PartnerAuthDataSourceImplementation(
                authSession: dataManager.authSession,
                institution: institution,
                manifest: dataManager.manifest,
                relinkAuthorization: nil,
                returnURL: dataManager.returnURL,
                apiClient: dataManager.apiClient,
                clientSecret: dataManager.clientSecret,
                analyticsClient: dataManager.analyticsClient
            )
            let partnerAuthViewController = PartnerAuthViewController(
                dataSource: partnerAuthDataSource,
                panePresentationStyle: panePresentationStyle
            )
            partnerAuthViewController.delegate = nativeFlowController
            viewController = partnerAuthViewController
        } else {
            assertionFailure("Code logic error. Missing parameters for \(pane).")
            viewController = nil
        }
    case .manualEntrySuccess:
        fallthrough
    case .success:
        let successDataSource = SuccessDataSourceImplementation(
            manifest: dataManager.manifest,
            linkedAccountsCount: dataManager.linkedAccounts?.count ?? 0,
            saveToLinkWithStripeSucceeded: dataManager.saveToLinkWithStripeSucceeded,
            apiClient: dataManager.apiClient,
            clientSecret: dataManager.clientSecret,
            analyticsClient: dataManager.analyticsClient,
            customSuccessPaneCaption: dataManager.customSuccessPaneCaption,
            customSuccessPaneSubCaption: dataManager.customSuccessPaneSubCaption
        )
        let successViewController = SuccessViewController(dataSource: successDataSource)
        successViewController.delegate = nativeFlowController
        viewController = successViewController
    case .unexpectedError:
        if
            let errorPaneError = dataManager.errorPaneError,
            let errorPaneReferrerPane = dataManager.errorPaneReferrerPane
        {
            let errorDataSource = ErrorDataSource(
                error: errorPaneError,
                referrerPane: errorPaneReferrerPane,
                manifest: dataManager.manifest,
                reduceManualEntryProminenceInErrors: dataManager.reduceManualEntryProminenceInErrors,
                analyticsClient: dataManager.analyticsClient,
                institution: dataManager.institution
            )
            let errorViewController = ErrorViewController(dataSource: errorDataSource)
            errorViewController.delegate = nativeFlowController
            viewController = errorViewController
        } else {
            // if backend returns `unexpected_error`, the parameters being NULL
            // might be OK and we will go to terminal error
            viewController = nil
        }
    case .authOptions:
        assertionFailure("Not supported")
        viewController = nil
    case .networkingLinkLoginWarmup:
        let networkingLinkWarmupDataSource = NetworkingLinkLoginWarmupDataSourceImplementation(
            manifest: dataManager.manifest,
            apiClient: dataManager.apiClient,
            clientSecret: dataManager.clientSecret,
            analyticsClient: dataManager.analyticsClient,
            nextPaneOrDrawerOnSecondaryCta: parameters?.nextPaneOrDrawerOnSecondaryCta,
            elementsSessionContext: dataManager.elementsSessionContext
        )
        let networkingLinkWarmupViewController = NetworkingLinkLoginWarmupViewController(
            dataSource: networkingLinkWarmupDataSource,
            panePresentationStyle: panePresentationStyle
        )
        networkingLinkWarmupViewController.delegate = nativeFlowController
        viewController = networkingLinkWarmupViewController

    // client-side only panes below
    case .resetFlow:
        let resetFlowDataSource = ResetFlowDataSourceImplementation(
            apiClient: dataManager.apiClient,
            clientSecret: dataManager.clientSecret,
            manifest: dataManager.manifest,
            analyticsClient: dataManager.analyticsClient
        )
        let resetFlowViewController = ResetFlowViewController(
            dataSource: resetFlowDataSource
        )
        resetFlowViewController.delegate = nativeFlowController
        viewController = resetFlowViewController
    case .terminalError:
        if let terminalError = dataManager.terminalError {
            let terminalErrorViewController = TerminalErrorViewController(
                error: terminalError,
                allowManualEntry: dataManager.manifest.allowManualEntry,
                appearance: dataManager.manifest.appearance
            )
            terminalErrorViewController.delegate = nativeFlowController
            viewController = terminalErrorViewController
        } else {
            assertionFailure("Code logic error. Missing parameters for \(pane).")
            viewController = nil
        }
    case .unparsable:
        viewController = nil
    }

    if let viewController = viewController {
        // this assert should ensure that it's nearly impossible to miss
        // adding new cases to `paneFromViewController`
        assert(
            FinancialConnectionsAnalyticsClient.paneFromViewController(viewController) == pane
            // `manualEntrySuccess` is a special case where it maps to the
            // same thing as `success` so this assert is not necessary
            || pane == .manualEntrySuccess,
            "Found a new view controller (\(viewController.self)) that needs to be added to `paneFromViewController`."
        )

        // this logging isn't perfect because one could call `CreatePaneViewController`
        // and never use the view controller, but that is not the case today
        // and it is difficult to imagine when that would be the case in the future
        dataManager
            .analyticsClient
            .log(
                eventName: "pane.launched",
                parameters: {
                    var parameters: [String: Any] = [:]
                    parameters["referrer_pane"] = dataManager.lastPaneLaunched?.rawValue
                    return parameters
                }(),
                pane: pane
            )
        dataManager.lastPaneLaunched = pane
    } else {
        dataManager
            .analyticsClient
            .logUnexpectedError(
                FinancialConnectionsSheetError.unknown(
                    debugDescription: "Pane Not Found: either app state is invalid, or an unsupported pane was requested."
                ),
                errorName: "PaneNotFound",
                pane: pane
            )
    }

    // Applies the style configuration to each view controller.
    dataManager.configuration.style.configure(viewController)
    return viewController
}

private func ShouldHideLogoInNavigationBar(
    forViewController viewController: UIViewController,
    reducedBranding: Bool,
    merchantLogo: [String]?
) -> Bool {
    if viewController is ConsentViewController {
        let willShowMerchantLogoInConsentScreen = (merchantLogo != nil)
        if willShowMerchantLogoInConsentScreen {
            // if we are going to show merchant logo in consent screen,
            // do not show the logo in the navigation bar
            return true
        } else {
            return reducedBranding
        }
    } else {
        return reducedBranding
    }
}
