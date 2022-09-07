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
    private let api: FinancialConnectionsAPIClient
    private let clientSecret: String

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
            // TODO(vardges): handle this
            assertionFailure()
            return
        }
        
        if next is ResetFlowViewController {
            // TODO(kgaidis): having to reference `ResetFlowViewController`
            //                in an "indirect" way is likely not optimal. We should
            //                consider refactoring some of the data flow once its finalized.
            guard
                let indexOfBankPicker = navigationController.viewControllers.firstIndex(
                    where: { $0 is InstitutionPicker }
                )
            else {
                assertionFailure("this should never happen")
                navigationController.setViewControllers([next], animated: true)
                return
            }
            let nextViewControllers = Array(navigationController.viewControllers[..<indexOfBankPicker]) + [next]
            navigationController.setViewControllers(nextViewControllers, animated: true)
        } else {
            // TODO(kgaidis): having to reference `ResetFlowViewController`
            //                in an "indirect" way is likely not optimal. We should
            //                consider refactoring some of the data flow once its finalized.
            if navigationController.topViewController is ResetFlowViewController {
                var viewControllers = navigationController.viewControllers
                _ = viewControllers.popLast() // remove `ResetFlowViewController
                navigationController.setViewControllers(viewControllers + [next], animated: true)
            } else {
                navigationController.pushViewController(next, animated: true)
            }
        }
    }
    
    private func nextPane(isFirstPane: Bool) -> UIViewController? {
        var viewController: UIViewController? = nil
        switch dataManager.nextPane() {
        case .accountPicker:
            if let authorizationSession = dataManager.authorizationSession, let institution = dataManager.institution {
                let accountPickerDataSource = AccountPickerDataSourceImplementation(
                    apiClient: api,
                    clientSecret: clientSecret,
                    authorizationSession: authorizationSession,
                    manifest: dataManager.manifest,
                    institution: institution
                )
                let accountPickerViewController = AccountPickerViewController(dataSource: accountPickerDataSource)
                accountPickerViewController.delegate = self
                viewController = accountPickerViewController
            } else {
                assertionFailure("this should never happen") // TODO(kgaidis): handle better?
            }
        case .attachLinkedPaymentAccount:
            fatalError("not been implemented")
        case .consent:
            viewController = ConsentViewController(
                manifest: dataManager.manifest,
                didConsent: { [weak self] in
                    self?.dataManager.consentAcquired()
                },
                didSelectManuallyVerify: dataManager.manifest.allowManualEntry ? { [weak self] in
                    self?.dataManager.requestedManualEntry()
                } : nil
            )
        case .institutionPicker:
            let dataSource = InstitutionAPIDataSource(api: api, clientSecret: clientSecret)
            let picker = InstitutionPicker(dataSource: dataSource)
            picker.delegate = self
            viewController = picker
        case .linkConsent:
            fatalError("not been implemented")
        case .linkLogin:
            fatalError("not been implemented")
        case .manualEntry:
            let dataSource = ManualEntryDataSourceImplementation(
                apiClient: api,
                clientSecret: clientSecret,
                manifest: dataManager.manifest
            )
            let manualEntryViewController = ManualEntryViewController(dataSource: dataSource)
            manualEntryViewController.delegate = self
            viewController = manualEntryViewController
        case .manualEntrySuccess:
            if let paymentAccountResource = dataManager.paymentAccountResource, let accountNumberLast4 = dataManager.accountNumberLast4 {
                let manualEntrySuccessViewController = ManualEntrySuccessViewController(
                    microdepositVerificationMethod: paymentAccountResource.microdepositVerificationMethod,
                    accountNumberLast4: accountNumberLast4
                )
                manualEntrySuccessViewController.delegate = self
                viewController = manualEntrySuccessViewController
            } else {
                assertionFailure("Developer logic error. Missing `paymentAccountResource` or `accountNumberLast4`.") // TODO(kgaidis): do we need to think of a better error handle here?
            }
        case .networkingLinkSignupPane:
            fatalError("not been implemented")
        case .networkingLinkVerification:
            fatalError("not been implemented")
        case .partnerAuth:
            if let institution = dataManager.institution {
                let partnerAuthDataSource = PartnerAuthDataSourceImplementation(
                    institution: institution,
                    apiClient: api,
                    clientSecret: clientSecret
                )
                let partnerAuthViewController = PartnerAuthViewController(dataSource: partnerAuthDataSource)
                partnerAuthViewController.delegate = self
                viewController = partnerAuthViewController
            } else {
                assertionFailure("Developer logic error. Missing authorization session.") // TODO(kgaidis): do we need to think of a better error handle here?
            }
        case .success:
            if let linkedAccounts = dataManager.linkedAccounts, let institution = dataManager.institution {
                let successDataSource = SuccessDataSourceImplementation(
                    manifest: dataManager.manifest,
                    linkedAccounts: linkedAccounts,
                    institution: institution,
                    apiClient: api,
                    clientSecret: clientSecret
                )
                let successViewController = SuccessViewController(dataSource: successDataSource)
                successViewController.delegate = self
                viewController = successViewController
            } else {
                assertionFailure("this should never happen") // TODO(kgaidis): figure out graceful error handling
            }
        case .unexpectedError:
            fatalError("not been implemented")
        case .unparsable:
            fatalError("not been implemented")
        case .authOptions:
            fatalError("not been implemented")
        case .networkingLinkLoginWarmup:
            fatalError("not been implemented")
        
        // client-side only panes below
        case .resetFlow:
            let resetFlowDataSource = ResetFlowDataSourceImplementation(
                apiClient: api,
                clientSecret: clientSecret
            )
            let resetFlowViewController = ResetFlowViewController(
                dataSource: resetFlowDataSource
            )
            resetFlowViewController.delegate = self
            viewController = resetFlowViewController
        }
        
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
        delegate?.authFlow(controller: self, didFinish: result)
    }
}

// MARK: - FinancialConnectionsNavigationControllerDelegate

@available(iOSApplicationExtension, unavailable)
extension AuthFlowController: FinancialConnectionsNavigationControllerDelegate {
    func financialConnectionsNavigationDidClose(_ navigationController: FinancialConnectionsNavigationController) {
        delegate?.authFlow(controller: self, didFinish: result)
    }
}

// MARK: - InstitutionPickerDelegate

@available(iOSApplicationExtension, unavailable)
extension AuthFlowController: InstitutionPickerDelegate {
    func institutionPicker(_ picker: InstitutionPicker, didSelect institution: FinancialConnectionsInstitution) {
        dataManager.picked(institution: institution)
    }
}

// MARK: - PartnerAuthViewControllerDelegate

@available(iOSApplicationExtension, unavailable)
extension AuthFlowController: PartnerAuthViewControllerDelegate {
    
    func partnerAuthViewControllerDidRequestBankPicker(_ viewController: PartnerAuthViewController) {
        navigationController.popViewController(animated: true)
    }
    
    func partnerAuthViewControllerDidRequestManualEntry(_ viewController: PartnerAuthViewController) {
        assertionFailure("not implemented") // TODO(kgaidis): implement manual entry
    }
    
    func partnerAuthViewController(
        _ viewController: PartnerAuthViewController,
        didCompleteWithAuthSession authSession: FinancialConnectionsAuthorizationSession
    ) {
        dataManager.didCompletePartnerAuth(authSession: authSession)
    }
    
    func partnerAuthViewControllerDidSelectClose(_ viewController: PartnerAuthViewController) {
        delegate?.authFlow(controller: self, didFinish: result)
    }
}
// MARK: - AccountPickerViewControllerDelegate

@available(iOSApplicationExtension, unavailable)
extension AuthFlowController: AccountPickerViewControllerDelegate {
    
    func accountPickerViewController(
        _ viewController: AccountPickerViewController,
        didLinkAccounts linkedAccounts: [FinancialConnectionsPartnerAccount]
    ) {
        dataManager.didLinkAccounts(linkedAccounts)
    }
}

// MARK: - SuccessViewControllerDelegate

@available(iOSApplicationExtension, unavailable)
extension AuthFlowController: SuccessViewControllerDelegate {
    
    func successViewControllerDidSelectLinkMoreAccounts(_ viewController: SuccessViewController) {
        dataManager.didSelectLinkMoreAccounts()
    }
    
    func successViewController(
        _ viewController: SuccessViewController,
        didCompleteSession session: StripeAPI.FinancialConnectionsSession
    ) {
        let result = FinancialConnectionsSheet.Result.completed(session: session)
        self.result = result // TODO(kgaidis): this needs to be set for some reason because of FinancialConnectionsNavigationControllerDelegate. However, it gives the illusion that calling didFinish below is what the result would be
        delegate?.authFlow(controller: self, didFinish: result)
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
        delegate?.authFlow(controller: self, didFinish: result)
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
        result = .failed(error: error)
        delegate?.authFlow(controller: self, didFinish: result)
    }
}
