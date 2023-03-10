//
//  NativeFlowController.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 6/6/22.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

@available(iOSApplicationExtension, unavailable)
protocol NativeFlowControllerDelegate: AnyObject {

    func authFlow(
        controller: NativeFlowController,
        didFinish result: FinancialConnectionsSheet.Result
    )
}

@available(iOSApplicationExtension, unavailable)
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
            parameters: [
                "pane":
                    FinancialConnectionsAnalyticsClient
                    .paneFromViewController(navigationController.topViewController)
                    .rawValue,
            ]
        )

        let showConfirmationAlert =
            (navigationController.topViewController is AccountPickerViewController
                || navigationController.topViewController is PartnerAuthViewController
                || navigationController.topViewController is AttachLinkedPaymentAccountViewController)
        closeAuthFlow(showConfirmationAlert: showConfirmationAlert, error: nil)
    }
}

// MARK: - Core Navigation Helpers

@available(iOSApplicationExtension, unavailable)
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

    private func pushPane(_ pane: FinancialConnectionsSessionManifest.NextPane, animated: Bool) {
        if pane == .success && dataManager.manifest.skipSuccessPane == true {
            closeAuthFlow(showConfirmationAlert: false, error: nil)
        } else if pane == .manualEntry && dataManager.manifest.manualEntryMode == .custom {
            closeAuthFlow(showConfirmationAlert: false, customManualEntry: true)
        } else {
            let manualEntryViewController = CreatePaneViewController(
                pane: pane,
                nativeFlowController: self,
                dataManager: dataManager
            )
            pushViewController(manualEntryViewController, animated: animated)
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

@available(iOSApplicationExtension, unavailable)
extension NativeFlowController {

    private func didSelectAnotherBank() {
        if dataManager.manifest.disableLinkMoreAccounts {
            closeAuthFlow(showConfirmationAlert: false, error: nil)
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
            closeAuthFlow(showConfirmationAlert: false, error: terminalError)
            return
        }
        setNavigationControllerViewControllers([terminalErrorViewController], animated: false)
    }

    // There's at least four types of close cases:
    // 1. User closes, and accounts are returned (or `paymentAccount` or `bankAccountToken`). That's a success.
    // 2. User closes, no accounts are returned, and there's an error. That's a failure.
    // 3. User closes, no accounts are returned, and there's no error. That's a cancel.
    // 4. User closes, and fetching accounts returns an error. That's a failure.
    @available(iOSApplicationExtension, unavailable)
    private func closeAuthFlow(
        showConfirmationAlert: Bool,
        customManualEntry: Bool = false,
        error closeAuthFlowError: Error? = nil  // user can also close AuthFlow while looking at an error screen
    ) {
        let finishAuthSession: (FinancialConnectionsSheet.Result) -> Void = { [weak self] result in
            guard let self = self else { return }
            self.delegate?.authFlow(controller: self, didFinish: result)
        }

        let completeFinancialConnectionsSession = { [weak self] in
            guard let self = self else { return }
            self.dataManager
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
                                    self.logCompleteEvent(
                                        type: eventType,
                                        status: "canceled"
                                    )
                                    finishAuthSession(.canceled)
                                }
                            }
                        }
                    case .failure(let completeFinancialConnectionsSessionError):
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

        if showConfirmationAlert {
            CloseConfirmationAlertHandler.present(
                businessName: dataManager.manifest.businessName,
                didSelectOK: {
                    completeFinancialConnectionsSession()
                }
            )
        } else {
            completeFinancialConnectionsSession()
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
            .log(eventName: "complete", parameters: parameters)
    }
}

// MARK: - ConsentViewControllerDelegate

@available(iOSApplicationExtension, unavailable)
extension NativeFlowController: ConsentViewControllerDelegate {

    func consentViewController(
        _ viewController: ConsentViewController,
        didConsentWithManifest manifest: FinancialConnectionsSessionManifest
    ) {
        dataManager.manifest = manifest

        pushPane(manifest.nextPane, animated: true)
    }

    func consentViewControllerDidSelectManuallyVerify(_ viewController: ConsentViewController) {
        pushPane(.manualEntry, animated: true)
    }
}

// MARK: - InstitutionPickerViewControllerDelegate

@available(iOSApplicationExtension, unavailable)
extension NativeFlowController: InstitutionPickerViewControllerDelegate {

    func institutionPickerViewController(
        _ viewController: InstitutionPickerViewController,
        didSelect institution: FinancialConnectionsInstitution
    ) {
        dataManager.institution = institution

        pushPane(.partnerAuth, animated: true)
    }

    func institutionPickerViewControllerDidSelectManuallyAddYourAccount(
        _ viewController: InstitutionPickerViewController
    ) {
        pushPane(.manualEntry, animated: true)
    }
}

// MARK: - PartnerAuthViewControllerDelegate

@available(iOSApplicationExtension, unavailable)
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
}

// MARK: - AccountPickerViewControllerDelegate

@available(iOSApplicationExtension, unavailable)
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
}

// MARK: - SuccessViewControllerDelegate

@available(iOSApplicationExtension, unavailable)
extension NativeFlowController: SuccessViewControllerDelegate {

    func successViewControllerDidSelectLinkMoreAccounts(_ viewController: SuccessViewController) {
        didSelectAnotherBank()
    }

    func successViewControllerDidSelectDone(_ viewController: SuccessViewController) {
        closeAuthFlow(showConfirmationAlert: false, error: nil)
    }
}

// MARK: - ManualEntryViewControllerDelegate

@available(iOSApplicationExtension, unavailable)
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
            closeAuthFlow(showConfirmationAlert: false, error: nil)
        }
    }
}

// MARK: - ManualEntrySuccessViewControllerDelegate

@available(iOSApplicationExtension, unavailable)
extension NativeFlowController: ManualEntrySuccessViewControllerDelegate {

    func manualEntrySuccessViewControllerDidFinish(_ viewController: ManualEntrySuccessViewController) {
        closeAuthFlow(showConfirmationAlert: false, error: nil)
    }
}

// MARK: - ResetFlowViewControllerDelegate

@available(iOSApplicationExtension, unavailable)
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
        closeAuthFlow(showConfirmationAlert: false, error: error)
    }
}

// MARK: - TerminalErrorViewControllerDelegate

@available(iOSApplicationExtension, unavailable)
extension NativeFlowController: TerminalErrorViewControllerDelegate {

    func terminalErrorViewController(
        _ viewController: TerminalErrorViewController,
        didCloseWithError error: Error
    ) {
        closeAuthFlow(showConfirmationAlert: false, error: error)
    }

    func terminalErrorViewControllerDidSelectManualEntry(_ viewController: TerminalErrorViewController) {
        pushPane(.manualEntry, animated: true)
    }
}

// MARK: - AttachLinkedPaymentAccountViewControllerDelegate

@available(iOSApplicationExtension, unavailable)
extension NativeFlowController: AttachLinkedPaymentAccountViewControllerDelegate {

    func attachLinkedPaymentAccountViewController(
        _ viewController: AttachLinkedPaymentAccountViewController,
        didFinishWithPaymentAccountResource paymentAccountResource: FinancialConnectionsPaymentAccountResource
    ) {
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
}

// MARK: - Static Helpers

@available(iOSApplicationExtension, unavailable)
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
                analyticsClient: dataManager.analyticsClient
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
                authSessionId: dataManager.authSession?.id
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
    case .linkConsent:
        assertionFailure("Not supported")
        viewController = nil
    case .linkLogin:
        assertionFailure("Not supported")
        viewController = nil
    case .manualEntry:
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
        assertionFailure("Not supported")
        viewController = nil
    case .networkingLinkVerification:
        assertionFailure("Not supported")
        viewController = nil
    case .partnerAuth:
        if let institution = dataManager.institution {
            let partnerAuthDataSource = PartnerAuthDataSourceImplementation(
                institution: institution,
                manifest: dataManager.manifest,
                returnURL: dataManager.returnURL,
                apiClient: dataManager.apiClient,
                clientSecret: dataManager.clientSecret,
                analyticsClient: dataManager.analyticsClient
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
        assertionFailure("Not supported")
        viewController = nil

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
                parameters: ["pane": pane.rawValue]
            )
    }

    return viewController
}

@available(iOSApplicationExtension, unavailable)
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
