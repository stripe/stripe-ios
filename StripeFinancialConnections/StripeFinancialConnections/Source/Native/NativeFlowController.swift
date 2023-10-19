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
        didFinish result: FinancialConnectionsSheet.Result
    )

    func nativeFlowController(
        _ nativeFlowController: NativeFlowController,
        didReceiveEvent event: FinancialConnectionsEvent
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
        item.tintColor = .textDisabled
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
        guard
            let viewController = CreatePaneViewController(
                pane: dataManager.manifest.nextPane,
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
        setNavigationControllerViewControllers([viewController], animated: false)
    }

    @objc private func didSelectNavigationBarCloseButton() {
        dataManager.analyticsClient.log(
            eventName: "click.nav_bar.close",
            pane: FinancialConnectionsAnalyticsClient
                .paneFromViewController(navigationController.topViewController)
        )

        let showConfirmationAlert =
            !(navigationController.topViewController is ConsentViewController
                || navigationController.topViewController is SuccessViewController
                || navigationController.topViewController is ManualEntrySuccessViewController)

        let finishClosingAuthFlow = { [weak self] in
            self?.closeAuthFlow()
        }
        if showConfirmationAlert {
            CloseConfirmationAlertHandler.present(
                businessName: dataManager.manifest.businessName,
                showNetworkingLanguageInConfirmationAlert: (dataManager.manifest.isNetworkingUserFlow == true && navigationController.topViewController is NetworkingLinkSignupViewController),
                didSelectOK: {
                    finishClosingAuthFlow()
                }
            )
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

    private func setNavigationControllerViewControllers(_ viewControllers: [UIViewController], animated: Bool = true) {
        viewControllers.forEach { viewController in
            FinancialConnectionsNavigationController.configureNavigationItemForNative(
                viewController.navigationItem,
                closeItem: navigationBarCloseBarButtonItem,
                shouldHideStripeLogo: ShouldHideStripeLogoInNavigationBar(
                    forViewController: viewController,
                    reducedBranding: dataManager.reducedBranding,
                    merchantLogo: dataManager.merchantLogo
                ),
                shouldLeftAlignStripeLogo: viewControllers.first == viewController
                    && viewController is ConsentViewController
            )
        }
        navigationController.setViewControllers(viewControllers, animated: animated)
    }

    private func pushPane(
        _ pane: FinancialConnectionsSessionManifest.NextPane,
        animated: Bool,
        // useful for cases where we want to prevent the user from navigating back
        //
        // keeping this logic in `pushPane` is helpful because we want to
        // reuse `skipSuccessPane` and `manualEntryMode == .custom` logic
        clearNavigationStack: Bool = false
    ) {
        if pane == .success && dataManager.manifest.skipSuccessPane == true {
            closeAuthFlow(error: nil)
        } else if pane == .manualEntry && dataManager.manifest.manualEntryMode == .custom {
            closeAuthFlow(customManualEntry: true)
        } else {
            let paneViewController = CreatePaneViewController(
                pane: pane,
                nativeFlowController: self,
                dataManager: dataManager
            )
            if clearNavigationStack, let paneViewController = paneViewController {
                setNavigationControllerViewControllers([paneViewController], animated: animated)
            } else {
                pushViewController(paneViewController, animated: animated)
            }
        }
    }

    private func pushViewController(_ viewController: UIViewController?, animated: Bool) {
        if let viewController = viewController {
            FinancialConnectionsNavigationController.configureNavigationItemForNative(
                viewController.navigationItem,
                closeItem: navigationBarCloseBarButtonItem,
                shouldHideStripeLogo: ShouldHideStripeLogoInNavigationBar(
                    forViewController: viewController,
                    reducedBranding: dataManager.reducedBranding,
                    merchantLogo: dataManager.merchantLogo
                ),
                shouldLeftAlignStripeLogo: false  // if we `push`, this is not the first VC
            )
            navigationController.pushViewController(viewController, animated: animated)
        } else {
            // when we can't find a view controller to present,
            // show a terminal error
            showTerminalError()
        }
    }
}

// MARK: - Other Helpers

extension NativeFlowController {

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

        let finishAuthSession: (FinancialConnectionsSheet.Result) -> Void = { [weak self] result in
            guard let self = self else { return }
            self.delegate?.nativeFlowController(self, didFinish: result)
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
                            finishAuthSession(.completed(session: session))
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
}

// MARK: - ConsentViewControllerDelegate

extension NativeFlowController: ConsentViewControllerDelegate {

    func consentViewController(
        _ viewController: ConsentViewController,
        didConsentWithManifest manifest: FinancialConnectionsSessionManifest
    ) {
        delegate?.nativeFlowController(
            self,
            didReceiveEvent: FinancialConnectionsEvent(name: .consentAcquired)
        )

        dataManager.manifest = manifest

        pushPane(manifest.nextPane, animated: true)
    }

    func consentViewControllerDidSelectManuallyVerify(_ viewController: ConsentViewController) {
        pushPane(.manualEntry, animated: true)
    }
}

// MARK: - InstitutionPickerViewControllerDelegate

extension NativeFlowController: InstitutionPickerViewControllerDelegate {

    func institutionPickerViewController(
        _ viewController: InstitutionPickerViewController,
        didSelect institution: FinancialConnectionsInstitution
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

        pushPane(.partnerAuth, animated: true)
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
}

// MARK: - PartnerAuthViewControllerDelegate

extension NativeFlowController: PartnerAuthViewControllerDelegate {

    func partnerAuthViewControllerUserDidSelectAnotherBank(_ viewController: PartnerAuthViewController) {
        didSelectAnotherBank()
    }

    func partnerAuthViewControllerDidRequestToGoBack(_ viewController: PartnerAuthViewController) {
        navigationController.popViewController(animated: true)
    }

    func partnerAuthViewControllerUserDidSelectEnterBankDetailsManually(_ viewController: PartnerAuthViewController) {
        pushPane(.manualEntry, animated: true)
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
        didReceiveTerminalError error: Error
    ) {
        showTerminalError(error)
    }

    func partnerAuthViewController(
        _ viewController: PartnerAuthViewController,
        didReceiveEvent event: FinancialConnectionsEvent
    ) {
        delegate?.nativeFlowController(self, didReceiveEvent: event)
    }
}

// MARK: - AccountPickerViewControllerDelegate

extension NativeFlowController: AccountPickerViewControllerDelegate {

    func accountPickerViewController(
        _ viewController: AccountPickerViewController,
        didSelectAccounts selectedAccounts: [FinancialConnectionsPartnerAccount]
    ) {
        dataManager.linkedAccounts = selectedAccounts

        let shouldAttachLinkedPaymentAccount = (dataManager.manifest.paymentMethodType != nil)
        if shouldAttachLinkedPaymentAccount {
            // this prevents an unnecessary push transition when presenting `attachLinkedPaymentAccount`
            //
            // `attachLinkedPaymentAccount` looks the same as the last step of `accountPicker`
            // so navigating to a "Linking account" loading screen can look buggy to the user
            pushPane(.attachLinkedPaymentAccount, animated: false)
        } else {
            pushPane(.success, animated: true)
        }
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
        dataManager.paymentAccountResource = paymentAccountResource
        dataManager.accountNumberLast4 = accountNumberLast4

        if dataManager.manifest.manualEntryUsesMicrodeposits {
            pushPane(.manualEntrySuccess, animated: true)
        } else {
            closeAuthFlow(error: nil)
        }
    }
}

// MARK: - ManualEntrySuccessViewControllerDelegate

extension NativeFlowController: ManualEntrySuccessViewControllerDelegate {

    func manualEntrySuccessViewControllerDidFinish(_ viewController: ManualEntrySuccessViewController) {
        closeAuthFlow(error: nil)
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
            navigationController.popViewController(animated: false)
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
        withError error: Error?
    ) {
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
}

// MARK: - NetworkingLinkLoginWarmupViewControllerDelegate

extension NativeFlowController: NetworkingLinkLoginWarmupViewControllerDelegate {

    func networkingLinkLoginWarmupViewControllerDidSelectContinue(
        _ viewController: NetworkingLinkLoginWarmupViewController
    ) {
        pushPane(.networkingLinkVerification, animated: true)
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
        consumerSession: ConsumerSessionData?
    ) {
        if let consumerSession = consumerSession {
            dataManager.consumerSession = consumerSession
        }
        pushPane(nextPane, animated: true)
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
        didSelectAccount selectedAccount: FinancialConnectionsPartnerAccount
    ) {
        dataManager.linkedAccounts = [selectedAccount]
    }

    func linkAccountPickerViewController(
        _ viewController: LinkAccountPickerViewController,
        didRequestSuccessPaneWithInstitution institution: FinancialConnectionsInstitution
    ) {
        assert(dataManager.linkedAccounts?.count == 1, "expected a selected account to be set")
        dataManager.institution = institution
        pushPane(.success, animated: true)
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
        didRequestNextPane nextPane: FinancialConnectionsSessionManifest.NextPane
    ) {
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
        error: Error?
    ) {
        if saveToLinkWithStripeSucceeded != nil {
            dataManager.saveToLinkWithStripeSucceeded = saveToLinkWithStripeSucceeded
        }
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
        didCompleteVerificationWithInstitution institution: FinancialConnectionsInstitution
    ) {
        dataManager.institution = institution
        pushPane(.success, animated: true)
    }

    func networkingLinkStepUpVerificationViewController(
        _ viewController: NetworkingLinkStepUpVerificationViewController,
        didReceiveTerminalError error: Error
    ) {
        showTerminalError(error)
    }

    func networkingLinkStepUpVerificationViewControllerEncounteredSoftError(
        _ viewController: NetworkingLinkStepUpVerificationViewController
    ) {
        pushPane(.institutionPicker, animated: true)
    }
}

// MARK: - Static Helpers

private func CreatePaneViewController(
    pane: FinancialConnectionsSessionManifest.NextPane,
    nativeFlowController: NativeFlowController,
    dataManager: NativeFlowDataManager
) -> UIViewController? {
    let viewController: UIViewController?
    switch pane {
    case .accountPicker:
        if let authSession = dataManager.authSession, let institution = dataManager.institution {
            let accountPickerDataSource = AccountPickerDataSourceImplementation(
                apiClient: dataManager.apiClient,
                clientSecret: dataManager.clientSecret,
                authSession: authSession,
                manifest: dataManager.manifest,
                institution: institution,
                analyticsClient: dataManager.analyticsClient,
                reduceManualEntryProminenceInErrors: dataManager.reduceManualEntryProminenceInErrors
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
        assertionFailure("Not supported")
        viewController = nil
    case .consent:
        let consentDataSource = ConsentDataSourceImplementation(
            manifest: dataManager.manifest,
            consent: dataManager.consentPaneModel,
            merchantLogo: dataManager.merchantLogo,
            apiClient: dataManager.apiClient,
            clientSecret: dataManager.clientSecret,
            analyticsClient: dataManager.analyticsClient
        )
        let consentViewController = ConsentViewController(dataSource: consentDataSource)
        consentViewController.delegate = nativeFlowController
        viewController = consentViewController
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
                consumerSession: consumerSession
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
        assertionFailure("Not supported")
        viewController = nil
    case .manualEntry:
        nativeFlowController.delegate?.nativeFlowController(
            nativeFlowController,
            didReceiveEvent: FinancialConnectionsEvent(name: .manualEntryInitiated)
        )

        let dataSource = ManualEntryDataSourceImplementation(
            apiClient: dataManager.apiClient,
            clientSecret: dataManager.clientSecret,
            manifest: dataManager.manifest,
            analyticsClient: dataManager.analyticsClient
        )
        let manualEntryViewController = ManualEntryViewController(dataSource: dataSource)
        manualEntryViewController.delegate = nativeFlowController
        viewController = manualEntryViewController
    case .manualEntrySuccess:
        if let paymentAccountResource = dataManager.paymentAccountResource,
           let accountNumberLast4 = dataManager.accountNumberLast4
        {
            let manualEntrySuccessViewController = ManualEntrySuccessViewController(
                microdepositVerificationMethod: paymentAccountResource.microdepositVerificationMethod,
                accountNumberLast4: accountNumberLast4,
                analyticsClient: dataManager.analyticsClient
            )
            manualEntrySuccessViewController.delegate = nativeFlowController
            viewController = manualEntrySuccessViewController
        } else {
            assertionFailure("Code logic error. Missing parameters for \(pane).")
            viewController = nil
        }
    case .networkingLinkSignupPane:
        if let linkedAccountIds = dataManager.linkedAccounts?.map({ $0.id }) {
            let networkingLinkSignupDataSource = NetworkingLinkSignupDataSourceImplementation(
                manifest: dataManager.manifest,
                selectedAccountIds: linkedAccountIds,
                returnURL: dataManager.returnURL,
                apiClient: dataManager.apiClient,
                clientSecret: dataManager.clientSecret,
                analyticsClient: dataManager.analyticsClient
            )
            let networkingLinkSignupViewController = NetworkingLinkSignupViewController(
                dataSource: networkingLinkSignupDataSource
            )
            networkingLinkSignupViewController.delegate = nativeFlowController
            viewController = networkingLinkSignupViewController
        } else {
            assertionFailure("Code logic error. Missing parameters for \(pane).")
            viewController = nil
        }
    case .networkingLinkVerification:
        if let accountholderCustomerEmailAddress = dataManager.manifest.accountholderCustomerEmailAddress {
            let networkingLinkVerificationDataSource = NetworkingLinkVerificationDataSourceImplementation(
                accountholderCustomerEmailAddress: accountholderCustomerEmailAddress,
                manifest: dataManager.manifest,
                apiClient: dataManager.apiClient,
                clientSecret: dataManager.clientSecret,
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
        if
            let consumerSession = dataManager.consumerSession,
            let selectedAccountId = dataManager.linkedAccounts?.map({ $0.id }).first
        {
            let networkingSaveToLinkVerificationDataSource = NetworkingSaveToLinkVerificationDataSourceImplementation(
                consumerSession: consumerSession,
                selectedAccountId: selectedAccountId,
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
            let selectedAccountId = dataManager.linkedAccounts?.map({ $0.id }).first
        {
            let networkingLinkStepUpVerificationDataSource = NetworkingLinkStepUpVerificationDataSourceImplementation(
                consumerSession: consumerSession,
                selectedAccountId: selectedAccountId,
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
                institution: institution,
                manifest: dataManager.manifest,
                returnURL: dataManager.returnURL,
                apiClient: dataManager.apiClient,
                clientSecret: dataManager.clientSecret,
                analyticsClient: dataManager.analyticsClient,
                reduceManualEntryProminenceInErrors: dataManager.reduceManualEntryProminenceInErrors
            )
            let partnerAuthViewController = PartnerAuthViewController(dataSource: partnerAuthDataSource)
            partnerAuthViewController.delegate = nativeFlowController
            viewController = partnerAuthViewController
        } else {
            assertionFailure("Code logic error. Missing parameters for \(pane).")
            viewController = nil
        }
    case .success:
        if let linkedAccounts = dataManager.linkedAccounts, let institution = dataManager.institution {
            let successDataSource = SuccessDataSourceImplementation(
                manifest: dataManager.manifest,
                linkedAccounts: linkedAccounts,
                institution: institution,
                saveToLinkWithStripeSucceeded: dataManager.saveToLinkWithStripeSucceeded,
                apiClient: dataManager.apiClient,
                clientSecret: dataManager.clientSecret,
                analyticsClient: dataManager.analyticsClient
            )
            let successViewController = SuccessViewController(dataSource: successDataSource)
            successViewController.delegate = nativeFlowController
            viewController = successViewController
        } else {
            assertionFailure("Code logic error. Missing parameters for \(pane).")
            viewController = nil
        }
    case .unexpectedError:
        viewController = nil
    case .authOptions:
        assertionFailure("Not supported")
        viewController = nil
    case .networkingLinkLoginWarmup:
        let networkingLinkWarmupDataSource = NetworkingLinkLoginWarmupDataSourceImplementation(
            manifest: dataManager.manifest,
            apiClient: dataManager.apiClient,
            clientSecret: dataManager.clientSecret,
            analyticsClient: dataManager.analyticsClient
        )
        let networkingLinkWarmupViewController = NetworkingLinkLoginWarmupViewController(
            dataSource: networkingLinkWarmupDataSource
        )
        networkingLinkWarmupViewController.delegate = nativeFlowController
        viewController = networkingLinkWarmupViewController

    // client-side only panes below
    case .resetFlow:
        let resetFlowDataSource = ResetFlowDataSourceImplementation(
            apiClient: dataManager.apiClient,
            clientSecret: dataManager.clientSecret,
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
                allowManualEntry: dataManager.manifest.allowManualEntry
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
            FinancialConnectionsAnalyticsClient.paneFromViewController(viewController) == pane,
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

    return viewController
}

private func ShouldHideStripeLogoInNavigationBar(
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
