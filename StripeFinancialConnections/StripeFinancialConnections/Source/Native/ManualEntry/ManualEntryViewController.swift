//
//  ManualEntryViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/23/22.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol ManualEntryViewControllerDelegate: AnyObject {
    func manualEntryViewController(
        _ viewController: ManualEntryViewController,
        didRequestToContinueWithPaymentAccountResource paymentAccountResource:
            FinancialConnectionsPaymentAccountResource,
        accountNumberLast4: String
    )
}

final class ManualEntryViewController: UIViewController {

    private let dataSource: ManualEntryDataSource
    weak var delegate: ManualEntryViewControllerDelegate?

    private lazy var manualEntryFormView: ManualEntryFormView = {
        let manualEntryFormView = ManualEntryFormView(
            isTestMode: dataSource.manifest.isTestMode,
            appearance: dataSource.manifest.appearance
        )
        manualEntryFormView.delegate = self
        return manualEntryFormView
    }()

    private var footerButton: StripeUICore.Button?
    private var paneLayoutView: PaneLayoutView?

    init(dataSource: ManualEntryDataSource) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = FinancialConnectionsAppearance.Colors.background

        let footerView = PaneLayoutView.createFooterView(
            primaryButtonConfiguration: PaneLayoutView.ButtonConfiguration(
                title: STPLocalizedString(
                    "Submit",
                    "The submit button for a screen that allows a user to manually enter their bank account information."
                ),
                accessibilityIdentifier: "manual_entry_continue_button",
                action: didSelectContinue
            ),
            appearance: dataSource.manifest.appearance
        )
        self.footerButton = footerView.primaryButton

        self.paneLayoutView = PaneLayoutView(
            contentView: PaneLayoutView.createContentView(
                iconView: nil,
                title: STPLocalizedString(
                    "Enter bank details",
                    "The title of a screen that allows a user to manually enter their bank account information."
                ),
                subtitle: {
                    let checkingOnly = !dataSource.manifest.product.hasSuffix("onboarding")
                    if checkingOnly {
                        if dataSource.manifest.manualEntryUsesMicrodeposits {
                            return STPLocalizedString(
                                "Your bank information will be verified via micro-deposits to your account, typically within 1-2 business days. Only checking accounts are supported.",
                                "The subtitle/description in a screen that allows a user to manually enter their bank account information."
                            )
                        } else {
                            return STPLocalizedString(
                                "Only checking accounts are supported.",
                                "The subtitle/description in a screen that allows a user to manually enter their bank account information."
                            )
                        }
                    } else { // checking or savings
                        if dataSource.manifest.manualEntryUsesMicrodeposits {
                            return STPLocalizedString(
                                "Your bank information will be verified with micro-deposits to your account. This typically takes 1-2 business days.",
                                "The subtitle/description in a screen that allows a user to manually enter their bank account information."
                            )
                        } else {
                            return STPLocalizedString(
                                "Checking and savings accounts are supported.",
                                "The subtitle/description in a screen that allows a user to manually enter their bank account information."
                            )
                        }
                    }
                }(),
                contentView: manualEntryFormView
            ),
            footerView: footerView.footerView,
            keepFooterAboveKeyboard: true
        )
        paneLayoutView?.addTo(view: view)
        #if !canImport(CompositorServices)
        paneLayoutView?.scrollView.keyboardDismissMode = .onDrag
        #endif

        adjustContinueButtonStateIfNeeded()

        dataSource
            .analyticsClient
            .logPaneLoaded(pane: .manualEntry)
    }

    private func didSelectContinue() {
        guard let routingAndAccountNumber = manualEntryFormView.routingAndAccountNumber else {
            assertionFailure("user should never be able to press continue if we have no routing/account number")
            return
        }
        manualEntryFormView.setError(text: nil)  // clear previous error

        footerButton?.isLoading = true
        dataSource.attachBankAccountToLinkAccountSession(
            routingNumber: routingAndAccountNumber.routingNumber,
            accountNumber: routingAndAccountNumber.accountNumber
        ).observe(on: .main) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let resource):
                // note: we are not stopping the footer button loading in the `success`
                // case because we will transition to a different screen
                // so we want to avoid slight animation 'blip' by stopping
                self.delegate?
                    .manualEntryViewController(
                        self,
                        didRequestToContinueWithPaymentAccountResource: resource,
                        accountNumberLast4: String(routingAndAccountNumber.accountNumber.suffix(4))
                    )
            case .failure(let error):
                self.footerButton?.isLoading = false

                let errorText: String
                if let stripeError = error as? StripeError, case .apiError(let apiError) = stripeError {
                    errorText = apiError.message ?? stripeError.localizedDescription
                } else {
                    errorText = error.localizedDescription
                }
                self.manualEntryFormView.setError(text: errorText)
                self.dataSource
                    .analyticsClient
                    .logUnexpectedError(
                        error,
                        errorName: "ManualEntryAttachBankAccountToLinkAccountSessionError",
                        pane: .manualEntry
                    )
            }
        }
    }

    private func adjustContinueButtonStateIfNeeded() {
        footerButton?.isEnabled = (manualEntryFormView.routingAndAccountNumber != nil)
    }
}

// MARK: - ManualEntryFormViewDelegate

extension ManualEntryViewController: ManualEntryFormViewDelegate {

    func manualEntryFormViewTextDidChange(_ view: ManualEntryFormView) {
        adjustContinueButtonStateIfNeeded()
    }

    func manualEntryFormViewShouldSubmit(_ view: ManualEntryFormView) {
        adjustContinueButtonStateIfNeeded()
        didSelectContinue()
    }
}
