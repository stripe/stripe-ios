//
//  AuthFlowController.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 6/6/22.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

@available(iOSApplicationExtension, unavailable)
protocol AuthFlowControllerDelegate: AnyObject {

    func authFlow(
        controller: AuthFlowController,
        didFinish result: FinancialConnectionsSheet.Result
    )
}

@available(iOSApplicationExtension, unavailable)
class AuthFlowController {

    private let dataManager: AuthFlowDataManager
    private let navigationController: FinancialConnectionsNavigationController
    weak var delegate: AuthFlowControllerDelegate?
    
    private lazy var navigationBarCloseBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem(
            image: Image.close.makeImage(template: false),
            style: .plain,
            target: self,
            action: #selector(didSelectNavigationBarCloseButton)
        )
        item.tintColor = .textDisabled
        return item
    }()

    init(
        dataManager: AuthFlowDataManager,
        navigationController: FinancialConnectionsNavigationController
    ) {
        self.dataManager = dataManager
        self.navigationController = navigationController
    }
    
    func startFlow() {
        guard
            let viewController = CreatePaneViewController(
                pane: dataManager.manifest.nextPane,
                authFlowController: self,
                dataManager: dataManager
            )
        else {
            assertionFailure("We should always get a view controller for the first pane: \(dataManager.manifest.nextPane)")
            showTerminalError()
            return
        }
        setNavigationControllerViewControllers([viewController], animated: false)
    }
    
    @objc private func didSelectNavigationBarCloseButton() {
        let showConfirmationAlert = (
            navigationController.topViewController is AccountPickerViewController
            || navigationController.topViewController is PartnerAuthViewController
            || navigationController.topViewController is AttachLinkedPaymentAccountViewController
        )
        closeAuthFlow(showConfirmationAlert: showConfirmationAlert, error: nil)
    }
}

// MARK: - Core Navigation Helpers

@available(iOSApplicationExtension, unavailable)
extension AuthFlowController {
    
    private func setNavigationControllerViewControllers(_ viewControllers: [UIViewController], animated: Bool = true) {
        viewControllers.forEach { viewController in
            FinancialConnectionsNavigationController.configureNavigationItemForNative(
                viewController.navigationItem,
                closeItem: navigationBarCloseBarButtonItem,
                isFirstViewController: (viewControllers.first is ConsentViewController)
            )
        }
        navigationController.setViewControllers(viewControllers, animated: animated)
    }
    
    private func pushViewController(_ viewController: UIViewController?, animated: Bool) {
        if let viewController = viewController {
            FinancialConnectionsNavigationController.configureNavigationItemForNative(
                viewController.navigationItem,
                closeItem: navigationBarCloseBarButtonItem,
                isFirstViewController: false // if we `push`, this is not the first VC
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
extension AuthFlowController {
    
    private func pushManualEntry() {
        let manualEntryViewController = CreatePaneViewController(
            pane: .manualEntry,
            authFlowController: self,
            dataManager: dataManager
        )
        pushViewController(manualEntryViewController, animated: true)
    }

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
                authFlowController: self,
                dataManager: dataManager
            )
        else {
            assertionFailure("We should always get a view controller for \(FinancialConnectionsSessionManifest.NextPane.resetFlow)")
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
                debugDescription: "Unknown terminal error. It is likely that we couldn't find a view controller for a specific pane."
            )
        }
        dataManager.terminalError = terminalError // needs to be set to create `terminalError` pane
        
        guard
            let terminalErrorViewController = CreatePaneViewController(
                pane: .terminalError,
                authFlowController: self,
                dataManager: dataManager
            )
        else {
            assertionFailure("We should always get a view controller for \(FinancialConnectionsSessionManifest.NextPane.terminalError)")
            closeAuthFlow(showConfirmationAlert: false, error: terminalError)
            return
        }
        setNavigationControllerViewControllers([terminalErrorViewController], animated: false)
    }
    
    // There's at least three types of close cases:
    // 1. User closes when getting an error. In that case `error != nil`. That's an error.
    // 2. User closes, there is no error, and fetching accounts returns accounts (or `paymentAccount`). That's a success.
    // 3. User closes, there is no error, and fetching accounts returns NO accounts. That's a cancel.
    @available(iOSApplicationExtension, unavailable)
    private func closeAuthFlow(
        showConfirmationAlert: Bool,
        error closeAuthFlowError: Error? = nil // user can also close AuthFlow while looking at an error screen
    ) {
        let finishAuthSession: (FinancialConnectionsSheet.Result) -> Void = { [weak self] result in
            guard let self = self else { return }
            self.delegate?.authFlow(controller: self, didFinish: result)
        }
        
        let completeFinancialConnectionsSession = { [weak self] in
            guard let self = self else { return }
            self.dataManager
                .completeFinancialConnectionsSession()
                .observe(on: .main) { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success(let session):
                        if session.accounts.data.count > 0 || session.paymentAccount != nil || session.bankAccountToken != nil {
                            finishAuthSession(.completed(session: session))
                        } else if let closeAuthFlowError = closeAuthFlowError {
                            finishAuthSession(.failed(error: closeAuthFlowError))
                        } else {
                            if let terminalError = self.dataManager.terminalError {
                                finishAuthSession(.failed(error: terminalError))
                            } else {
                                finishAuthSession(.canceled)
                            }
                        }
                    case .failure(let completeFinancialConnectionsSessionError):
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
}

// MARK: - ConsentViewControllerDelegate

@available(iOSApplicationExtension, unavailable)
extension AuthFlowController: ConsentViewControllerDelegate {
    
    func consentViewController(
        _ viewController: ConsentViewController,
        didConsentWithManifest manifest: FinancialConnectionsSessionManifest
    ) {
        dataManager.manifest = manifest
        
        let viewController = CreatePaneViewController(
            pane: manifest.nextPane,
            authFlowController: self,
            dataManager: dataManager
        )
        pushViewController(viewController, animated: true)
    }
    
    func consentViewControllerDidSelectManuallyVerify(_ viewController: ConsentViewController) {
        pushManualEntry()
    }
}

// MARK: - InstitutionPickerDelegate

@available(iOSApplicationExtension, unavailable)
extension AuthFlowController: InstitutionPickerDelegate {
    
    func institutionPicker(_ picker: InstitutionPicker, didSelect institution: FinancialConnectionsInstitution) {
        dataManager.institution = institution
        
        let partnerAuthViewController = CreatePaneViewController(
            pane: .partnerAuth,
            authFlowController: self,
            dataManager: dataManager
        )
        pushViewController(partnerAuthViewController, animated: true)
    }
    
    func institutionPickerDidSelectManuallyAddYourAccount(_ picker: InstitutionPicker) {
        pushManualEntry()
    }
}

// MARK: - PartnerAuthViewControllerDelegate

@available(iOSApplicationExtension, unavailable)
extension AuthFlowController: PartnerAuthViewControllerDelegate {
    
    func partnerAuthViewControllerUserDidSelectAnotherBank(_ viewController: PartnerAuthViewController) {
        didSelectAnotherBank()
    }
    
    func partnerAuthViewControllerDidRequestToGoBack(_ viewController: PartnerAuthViewController) {
        navigationController.popViewController(animated: true)
    }
    
    func partnerAuthViewControllerUserDidSelectEnterBankDetailsManually(_ viewController: PartnerAuthViewController) {
        pushManualEntry()
    }
    
    func partnerAuthViewController(
        _ viewController: PartnerAuthViewController,
        didCompleteWithAuthSession authSession: FinancialConnectionsAuthorizationSession
    ) {
        dataManager.authorizationSession = authSession
        
        let accountPickerViewController = CreatePaneViewController(
            pane: .accountPicker,
            authFlowController: self,
            dataManager: dataManager
        )
        pushViewController(accountPickerViewController, animated: true)
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
extension AuthFlowController: AccountPickerViewControllerDelegate {
    
    func accountPickerViewController(
        _ viewController: AccountPickerViewController,
        didSelectAccounts selectedAccounts: [FinancialConnectionsPartnerAccount],
        skipToSuccess: Bool
    ) {
        dataManager.linkedAccounts = selectedAccounts
        
        let pushToSuccessPane = {
            let successViewController = CreatePaneViewController(
                pane: .success,
                authFlowController: self,
                dataManager: self.dataManager
            )
            self.pushViewController(successViewController, animated: true)
        }
        
        if skipToSuccess {
            pushToSuccessPane()
        } else {
            let shouldAttachLinkedPaymentAccount = (dataManager.manifest.paymentMethodType != nil)
            if shouldAttachLinkedPaymentAccount {
                let attachLinkedPaymentMethodViewController = CreatePaneViewController(
                    pane: .attachLinkedPaymentAccount,
                    authFlowController: self,
                    dataManager: dataManager
                )
                // there is no need to animate `AttachLinkedPaymentAccount`
                // transition because it looks the same as the "select accounts"
                // step of `AccountPicker` to the user
                pushViewController(attachLinkedPaymentMethodViewController, animated: false)
            } else {
                pushToSuccessPane()
            }
        }
    }
    
    func accountPickerViewControllerDidSelectAnotherBank(_ viewController: AccountPickerViewController) {
        didSelectAnotherBank()
    }
    
    func accountPickerViewControllerDidSelectManualEntry(_ viewController: AccountPickerViewController) {
        pushManualEntry()
    }
    
    func accountPickerViewController(_ viewController: AccountPickerViewController, didReceiveTerminalError error: Error) {
        showTerminalError(error)
    }
}

// MARK: - SuccessViewControllerDelegate

@available(iOSApplicationExtension, unavailable)
extension AuthFlowController: SuccessViewControllerDelegate {
    
    func successViewControllerDidSelectLinkMoreAccounts(_ viewController: SuccessViewController) {
        didSelectAnotherBank()
    }
    
    func successViewControllerDidSelectDone(_ viewController: SuccessViewController) {
        closeAuthFlow(showConfirmationAlert: false, error: nil)
    }
}

// MARK: - ManualEntryViewControllerDelegate

@available(iOSApplicationExtension, unavailable)
extension AuthFlowController: ManualEntryViewControllerDelegate {
    
    func manualEntryViewController(
        _ viewController: ManualEntryViewController,
        didRequestToContinueWithPaymentAccountResource paymentAccountResource: FinancialConnectionsPaymentAccountResource,
        accountNumberLast4: String
    ) {
        dataManager.paymentAccountResource = paymentAccountResource
        dataManager.accountNumberLast4 = accountNumberLast4
        
        if dataManager.manifest.manualEntryUsesMicrodeposits {
            let manualEntrySuccessViewController = CreatePaneViewController(
                pane: .manualEntrySuccess,
                authFlowController: self,
                dataManager: dataManager
            )
            pushViewController(manualEntrySuccessViewController, animated: true)
        } else {
            closeAuthFlow(showConfirmationAlert: false, error: nil)
        }
    }
}

// MARK: - ManualEntrySuccessViewControllerDelegate

@available(iOSApplicationExtension, unavailable)
extension AuthFlowController: ManualEntrySuccessViewControllerDelegate {
    
    func manualEntrySuccessViewControllerDidFinish(_ viewController: ManualEntrySuccessViewController) {
        closeAuthFlow(showConfirmationAlert: false, error: nil)
    }
}

// MARK: - ResetFlowViewControllerDelegate

@available(iOSApplicationExtension, unavailable)
extension AuthFlowController: ResetFlowViewControllerDelegate {
    
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
        let nextViewController = CreatePaneViewController(
            pane: manifest.nextPane,
            authFlowController: self,
            dataManager: dataManager
        )
        pushViewController(nextViewController, animated: false)
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
extension AuthFlowController: TerminalErrorViewControllerDelegate {
    
    func terminalErrorViewController(
        _ viewController: TerminalErrorViewController,
        didCloseWithError error: Error
    ) {
        closeAuthFlow(showConfirmationAlert: false, error: error)
    }
    
    func terminalErrorViewControllerDidSelectManualEntry(_ viewController: TerminalErrorViewController) {
        pushManualEntry()
    }
}

// MARK: - AttachLinkedPaymentAccountViewControllerDelegate

@available(iOSApplicationExtension, unavailable)
extension AuthFlowController: AttachLinkedPaymentAccountViewControllerDelegate {
    
    func attachLinkedPaymentAccountViewController(
        _ viewController: AttachLinkedPaymentAccountViewController,
        didFinishWithPaymentAccountResource paymentAccountResource: FinancialConnectionsPaymentAccountResource
    ) {
        let viewController = CreatePaneViewController(
            pane: paymentAccountResource.nextPane,
            authFlowController: self,
            dataManager: dataManager
        )
        // the next pane is likely `success`
        pushViewController(viewController, animated: true)
    }
    
    func attachLinkedPaymentAccountViewControllerDidSelectAnotherBank(_ viewController: AttachLinkedPaymentAccountViewController) {
        didSelectAnotherBank()
    }
    
    func attachLinkedPaymentAccountViewControllerDidSelectManualEntry(_ viewController: AttachLinkedPaymentAccountViewController) {
        pushManualEntry()
    }
}

// MARK: - Static Helpers

@available(iOSApplicationExtension, unavailable)
private func CreatePaneViewController(
    pane: FinancialConnectionsSessionManifest.NextPane,
    authFlowController: AuthFlowController,
    dataManager: AuthFlowDataManager
) -> UIViewController? {
    switch pane {
    case .accountPicker:
        if let authorizationSession = dataManager.authorizationSession, let institution = dataManager.institution {
            let accountPickerDataSource = AccountPickerDataSourceImplementation(
                apiClient: dataManager.apiClient,
                clientSecret: dataManager.clientSecret,
                authorizationSession: authorizationSession,
                manifest: dataManager.manifest,
                institution: institution
            )
            let accountPickerViewController = AccountPickerViewController(dataSource: accountPickerDataSource)
            accountPickerViewController.delegate = authFlowController
            return accountPickerViewController
        } else {
            assertionFailure("Code logic error. Missing parameters for \(pane).")
            return nil
        }
    case .attachLinkedPaymentAccount:
        if let institution = dataManager.institution, let linkedAccountId = dataManager.linkedAccounts?.first?.linkedAccountId {
            let dataSource = AttachLinkedPaymentAccountDataSourceImplementation(
                apiClient: dataManager.apiClient,
                clientSecret: dataManager.clientSecret,
                manifest: dataManager.manifest,
                institution: institution,
                linkedAccountId: linkedAccountId
            )
            let attachedLinkedPaymentAccountViewController = AttachLinkedPaymentAccountViewController(
                dataSource: dataSource
            )
            attachedLinkedPaymentAccountViewController.delegate = authFlowController
            return attachedLinkedPaymentAccountViewController
        } else {
            assertionFailure("Code logic error. Missing parameters for \(pane).")
            return nil
        }
    case .consent:
        let consentDataSource = ConsentDataSourceImplementation(
            manifest: dataManager.manifest,
            consentModel: ConsentModel(businessName: dataManager.manifest.businessName),
            apiClient: dataManager.apiClient,
            clientSecret: dataManager.clientSecret
        )
        let consentViewController = ConsentViewController(dataSource: consentDataSource)
        consentViewController.delegate = authFlowController
        return consentViewController
    case .institutionPicker:
        let dataSource = InstitutionAPIDataSource(
            manifest: dataManager.manifest,
            apiClient: dataManager.apiClient,
            clientSecret: dataManager.clientSecret
        )
        let picker = InstitutionPicker(dataSource: dataSource)
        picker.delegate = authFlowController
        return picker
    case .linkConsent:
        assertionFailure("Not supported")
        return nil
    case .linkLogin:
        assertionFailure("Not supported")
        return nil
    case .manualEntry:
        let dataSource = ManualEntryDataSourceImplementation(
            apiClient: dataManager.apiClient,
            clientSecret: dataManager.clientSecret,
            manifest: dataManager.manifest
        )
        let manualEntryViewController = ManualEntryViewController(dataSource: dataSource)
        manualEntryViewController.delegate = authFlowController
        return manualEntryViewController
    case .manualEntrySuccess:
        if let paymentAccountResource = dataManager.paymentAccountResource, let accountNumberLast4 = dataManager.accountNumberLast4 {
            let manualEntrySuccessViewController = ManualEntrySuccessViewController(
                microdepositVerificationMethod: paymentAccountResource.microdepositVerificationMethod,
                accountNumberLast4: accountNumberLast4
            )
            manualEntrySuccessViewController.delegate = authFlowController
            return manualEntrySuccessViewController
        } else {
            assertionFailure("Code logic error. Missing parameters for \(pane).")
            return nil
        }
    case .networkingLinkSignupPane:
        assertionFailure("Not supported")
        return nil
    case .networkingLinkVerification:
        assertionFailure("Not supported")
        return nil
    case .partnerAuth:
        if let institution = dataManager.institution {
            let partnerAuthDataSource = PartnerAuthDataSourceImplementation(
                institution: institution,
                manifest: dataManager.manifest,
                apiClient: dataManager.apiClient,
                clientSecret: dataManager.clientSecret
            )
            let partnerAuthViewController = PartnerAuthViewController(dataSource: partnerAuthDataSource)
            partnerAuthViewController.delegate = authFlowController
            return partnerAuthViewController
        } else {
            assertionFailure("Code logic error. Missing parameters for \(pane).")
            return nil
        }
    case .success:
        if let linkedAccounts = dataManager.linkedAccounts, let institution = dataManager.institution {
            let successDataSource = SuccessDataSourceImplementation(
                manifest: dataManager.manifest,
                linkedAccounts: linkedAccounts,
                institution: institution,
                apiClient: dataManager.apiClient,
                clientSecret: dataManager.clientSecret
            )
            let successViewController = SuccessViewController(dataSource: successDataSource)
            successViewController.delegate = authFlowController
            return successViewController
        } else {
            assertionFailure("Code logic error. Missing parameters for \(pane).")
            return nil
        }
    case .unexpectedError:
        return nil
    case .authOptions:
        assertionFailure("Not supported")
        return nil
    case .networkingLinkLoginWarmup:
        assertionFailure("Not supported")
        return nil
    
    // client-side only panes below
    case .resetFlow:
        let resetFlowDataSource = ResetFlowDataSourceImplementation(
            apiClient: dataManager.apiClient,
            clientSecret: dataManager.clientSecret
        )
        let resetFlowViewController = ResetFlowViewController(
            dataSource: resetFlowDataSource
        )
        resetFlowViewController.delegate = authFlowController
        return resetFlowViewController
    case .terminalError:
        if let terminalError = dataManager.terminalError {
            let terminalErrorViewController = TerminalErrorViewController(
                error: terminalError,
                allowManualEntry: dataManager.manifest.allowManualEntry
            )
            terminalErrorViewController.delegate = authFlowController
            return terminalErrorViewController
        } else {
            assertionFailure("Code logic error. Missing parameters for \(pane).")
            return nil
        }
    case .unparsable:
        return nil
    }
}
