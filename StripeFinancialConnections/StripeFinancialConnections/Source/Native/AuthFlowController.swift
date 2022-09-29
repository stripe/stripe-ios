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
class AuthFlowController: NSObject {

    // MARK: - Properties
    
    weak var delegate: AuthFlowControllerDelegate?

    private let dataManager: AuthFlowDataManager
    private let navigationController: FinancialConnectionsNavigationController
    fileprivate let api: FinancialConnectionsAPIClient
    fileprivate let clientSecret: String

    private var result: FinancialConnectionsSheet.Result = .canceled

    // MARK: - UI
    
    private lazy var closeItem: UIBarButtonItem = {
        let item = UIBarButtonItem(image: Image.close.makeImage(template: false),
                                   style: .plain,
                                   target: self,
                                   action: #selector(didTapClose))

        item.tintColor = .textDisabled
        return item
    }()

    // MARK: - Init
    
    init(api: FinancialConnectionsAPIClient,
         clientSecret: String,
         dataManager: AuthFlowDataManager,
         navigationController: FinancialConnectionsNavigationController) {
        self.api = api
        self.clientSecret = clientSecret
        self.dataManager = dataManager
        self.navigationController = navigationController
        super.init()
        dataManager.delegate = self
    }
    
    private func setNavigationControllerViewControllers(_ viewControllers: [UIViewController], animated: Bool = true) {
        viewControllers.forEach { viewController in
            FinancialConnectionsNavigationController.configureNavigationItemForNative(
                viewController.navigationItem,
                closeItem: closeItem,
                isFirstViewController: (viewController === viewControllers.first)
            )
        }
        navigationController.setViewControllers(viewControllers, animated: animated)
    }
    
    private func pushViewController(_ viewController: UIViewController?, animated: Bool) {
        if let viewController = viewController {
            FinancialConnectionsNavigationController.configureNavigationItemForNative(
                viewController.navigationItem,
                closeItem: closeItem,
                isFirstViewController: false // if we `push`, this is not the first VC
            )
            navigationController.pushViewController(viewController, animated: animated)
        } else {
            dataManager.startTerminalError(
                error: FinancialConnectionsSheetError.unknown(
                    debugDescription: "Failed to find next pane: \(dataManager.nextPane().rawValue)"
                )
            )
        }
    }
}

// MARK: - Navigation Helpers

@available(iOSApplicationExtension, unavailable)
extension AuthFlowController {
    
    private func pushManualEntryViewController() {
        let manualEntryViewController = CreatePaneViewController(
            pane: .manualEntry,
            authFlowController: self,
            dataManager: dataManager
        )
        pushViewController(manualEntryViewController, animated: true)
    }
}

// MARK: - AuthFlowDataManagerDelegate

@available(iOSApplicationExtension, unavailable)
extension AuthFlowController: AuthFlowDataManagerDelegate {
    func authFlowDataManagerDidUpdateNextPane(_ dataManager: AuthFlowDataManager) {
        transitionToNextPane()
    }
    
    func authFlowDataManagerDidUpdateManifest(_ dataManager: AuthFlowDataManager) {
        // TODO(vardges): handle this
    }
    
    func authFlow(dataManager: AuthFlowDataManager, failedToUpdateManifest error: Error) {
        // TODO(vardges): handle this
    }
    
    func authFlowDataManagerDidRequestToClose(
        _ dataManager: AuthFlowDataManager,
        showConfirmationAlert: Bool,
        error: Error?
    ) {
        closeAuthFlow(showConfirmationAlert: showConfirmationAlert, error: error)
    }
}

// MARK: - Public

@available(iOSApplicationExtension, unavailable)
extension AuthFlowController {
    
    func startFlow() {
        guard let next = self.nextPane(isFirstPane: true) else {
            // TODO(vardges): handle this
            assertionFailure()
            return
        }

        navigationController.setViewControllers([next], animated: false)
    }
}

// MARK: - Helpers

@available(iOSApplicationExtension, unavailable)
private extension AuthFlowController {
    
    private func transitionToNextPane() {
        guard let next = self.nextPane(isFirstPane: false) else {
            dataManager.startTerminalError(
                error: FinancialConnectionsSheetError.unknown(
                    debugDescription: "Failed to find next pane: \(dataManager.nextPane().rawValue)"
                )
            )
            return
        }
        
        if next is ResetFlowViewController {
            // TODO(kgaidis): having to reference `ResetFlowViewController`
            //                in an "indirect" way is likely not optimal. We should
            //                consider refactoring some of the data flow once its finalized.
            var viewControllers: [UIViewController] = []
            if let consentViewController = navigationController.viewControllers.first as? ConsentViewController {
                viewControllers.append(consentViewController)
            }
            viewControllers.append(next)
            navigationController.setViewControllers(viewControllers, animated: true)
        } else if next is TerminalErrorViewController {
            navigationController.setViewControllers([next], animated: false)
        } else {
            // TODO(kgaidis): having to reference `ResetFlowViewController`
            //                in an "indirect" way is likely not optimal. We should
            //                consider refactoring some of the data flow once its finalized.
            if navigationController.topViewController is ResetFlowViewController {
                var viewControllers = navigationController.viewControllers
                _ = viewControllers.popLast() // remove `ResetFlowViewController`
                navigationController.setViewControllers(viewControllers + [next], animated: true)
            } else {
                // there is no need to animate `AttachLinkedPaymentAccount`
                // transition because it looks the same as the "select accounts"
                // step of `AccountPicker` to the user
                let isAnimated = !(next is AttachLinkedPaymentAccountViewController)
                navigationController.pushViewController(next, animated: isAnimated)
            }
        }
    }
    
    private func nextPane(isFirstPane: Bool) -> UIViewController? {
        let viewController = CreatePaneViewController(
            pane: dataManager.nextPane(),
            authFlowController: self,
            dataManager: dataManager
        )
         
        FinancialConnectionsNavigationController.configureNavigationItemForNative(
            viewController?.navigationItem,
            closeItem: closeItem,
            isFirstViewController: isFirstPane
        )
        return viewController
    }
    
    private func displayAlert(_ message: String, viewController: UIViewController) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
            alertController.dismiss(animated: true)
        }
        alertController.addAction(OKAction)
        
        viewController.present(alertController, animated: true, completion: nil)
    }

    @objc
    func didTapClose() {
        // TODO(kgaidis): implement `showConfirmationAlert` for more panes
        let showConfirmationAlert = (dataManager.nextPane() == .accountPicker)
        closeAuthFlow(showConfirmationAlert: showConfirmationAlert, error: nil)
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
        let completeFinancialConnectionsSession = { [weak self] in
            guard let self = self else { return }
            self.dataManager
                .completeFinancialConnectionsSession()
                .observe(on: .main) { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success(let session):
                        if let closeAuthFlowError = closeAuthFlowError {
                            self.finishAuthSession(result: .failed(error: closeAuthFlowError))
                        } else {
                            // TODO(kgaidis): Stripe.js does some more additional handling for Link.
                            // TODO(kgaidis): Stripe.js also seems to collect ALL accounts (because this API call returns only a part of the accounts [its paginated?])
                            
                            if session.accounts.data.count > 0 || session.paymentAccount != nil || session.bankAccountToken != nil {
                                self.finishAuthSession(result: .completed(session: session))
                            } else {
                                if let terminalError = self.dataManager.terminalError {
                                    self.finishAuthSession(result: .failed(error: terminalError))
                                } else {
                                    self.finishAuthSession(result: .canceled)
                                }
                                // TODO(kgaidis): user can press "X" any time they have an error, should we route all errors up to `AuthFlowController` so we can return "failed" if user sees?
                            }
                        }
                    case .failure(let completeFinancialConnectionsSessionError):
                        if let closeAuthFlowError = closeAuthFlowError {
                            self.finishAuthSession(result: .failed(error: closeAuthFlowError))
                        } else {
                            self.finishAuthSession(result: .failed(error: completeFinancialConnectionsSessionError))
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
    
    private func finishAuthSession(result: FinancialConnectionsSheet.Result) {
        delegate?.authFlow(controller: self, didFinish: result)
    }
    
    private func didSelectAnotherBank() {
        if dataManager.manifest.disableLinkMoreAccounts {
            // TODO(kgaidis): `showConfirmationAlert` _may_ sometimes need to be ture here
            closeAuthFlow(showConfirmationAlert: false, error: nil)
        } else {
            dataManager.startResetFlow()
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
        pushManualEntryViewController()
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
        pushManualEntryViewController()
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
        dataManager.startManualEntry()
    }
    
    func partnerAuthViewController(
        _ viewController: PartnerAuthViewController,
        didCompleteWithAuthSession authSession: FinancialConnectionsAuthorizationSession
    ) {
        dataManager.didCompletePartnerAuth(authSession: authSession)
    }
    
    func partnerAuthViewController(
        _ viewController: PartnerAuthViewController,
        didReceiveTerminalError error: Error
    ) {
        dataManager.startTerminalError(error: error)
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
        dataManager.didSelectAccounts(selectedAccounts, skipToSuccess: skipToSuccess)
    }
    
    func accountPickerViewControllerDidSelectAnotherBank(_ viewController: AccountPickerViewController) {
        didSelectAnotherBank()
    }
    
    func accountPickerViewControllerDidSelectManualEntry(_ viewController: AccountPickerViewController) {
        dataManager.startManualEntry()
    }
    
    func accountPickerViewController(_ viewController: AccountPickerViewController, didReceiveTerminalError error: Error) {
        dataManager.startTerminalError(error: error)
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
        dataManager.didCompleteManualEntry(
            withPaymentAccountResource: paymentAccountResource,
            accountNumberLast4: accountNumberLast4
        )
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
        
        // go to the next pane (likely `.institutionPicker`)
        dataManager.resetFlowDidSucceeedMarkLinkingMoreAccounts(manifest: manifest)
    }

    func resetFlowViewController(
        _ viewController: ResetFlowViewController,
        didFailWithError error: Error
    ) {
        result = .failed(error: error) // TODO(kgaidis): clean this up
        delegate?.authFlow(controller: self, didFinish: result)
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
        dataManager.startManualEntry()
    }
}

// MARK: - AttachLinkedPaymentAccountViewControllerDelegate

@available(iOSApplicationExtension, unavailable)
extension AuthFlowController: AttachLinkedPaymentAccountViewControllerDelegate {
    
    func attachLinkedPaymentAccountViewController(
        _ viewController: AttachLinkedPaymentAccountViewController,
        didFinishWithPaymentAccountResource paymentAccountResource: FinancialConnectionsPaymentAccountResource
    ) {
        dataManager.didCompleteAttachedLinkedPaymentAccount(
            paymentAccountResource: paymentAccountResource
        )
    }
    
    func attachLinkedPaymentAccountViewControllerDidSelectAnotherBank(_ viewController: AttachLinkedPaymentAccountViewController) {
        didSelectAnotherBank()
    }
    
    func attachLinkedPaymentAccountViewControllerDidSelectManualEntry(_ viewController: AttachLinkedPaymentAccountViewController) {
        dataManager.startManualEntry()
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
                apiClient: authFlowController.api,
                clientSecret: authFlowController.clientSecret,
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
                apiClient: authFlowController.api,
                clientSecret: authFlowController.clientSecret,
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
            apiClient: authFlowController.api,
            clientSecret: authFlowController.clientSecret
        )
        let consentViewController = ConsentViewController(dataSource: consentDataSource)
        consentViewController.delegate = authFlowController
        return consentViewController
    case .institutionPicker:
        let dataSource = InstitutionAPIDataSource(
            manifest: dataManager.manifest,
            api: authFlowController.api,
            clientSecret: authFlowController.clientSecret
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
            apiClient: authFlowController.api,
            clientSecret: authFlowController.clientSecret,
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
                apiClient: authFlowController.api,
                clientSecret: authFlowController.clientSecret
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
                apiClient: authFlowController.api,
                clientSecret: authFlowController.clientSecret
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
            apiClient: authFlowController.api,
            clientSecret: authFlowController.clientSecret
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
