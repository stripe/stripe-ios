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
        let manualEntryFormView = ManualEntryFormView()
        manualEntryFormView.delegate = self
        return manualEntryFormView
    }()
    private lazy var footerView: ManualEntryFooterView = {
        let manualEntryFooterView = ManualEntryFooterView(
            didSelectContinue: { [weak self] in
                self?.didSelectContinue()
            }
        )
        return manualEntryFooterView
    }()

    init(dataSource: ManualEntryDataSource) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .customBackgroundColor

        let paneWithHeaderLayoutView = PaneWithHeaderLayoutView(
            title: STPLocalizedString(
                "Enter bank account details",
                "The title of a screen that allows a user to manually enter their bank account information."
            ),
            subtitle: dataSource.manifest.manualEntryUsesMicrodeposits
                ? STPLocalizedString(
                    "Your bank information will be verified with micro-deposits to your account",
                    "The subtitle/description in a screen that allows a user to manually enter their bank account information. It informs the user that their bank account information will have to be verified."
                ) : nil,
            contentView: manualEntryFormView,
            footerView: footerView
        )
        paneWithHeaderLayoutView.addTo(view: view)
        #if !canImport(CompositorServices)
        paneWithHeaderLayoutView.scrollView.keyboardDismissMode = .onDrag
        #endif
        stp_beginObservingKeyboardAndInsettingScrollView(paneWithHeaderLayoutView.scrollView, onChange: nil)

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

        footerView.setIsLoading(true)
        dataSource.attachBankAccountToLinkAccountSession(
            routingNumber: routingAndAccountNumber.routingNumber,
            accountNumber: routingAndAccountNumber.accountNumber
        ).observe(on: .main) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let resource):
                self.delegate?
                    .manualEntryViewController(
                        self,
                        didRequestToContinueWithPaymentAccountResource: resource,
                        accountNumberLast4: String(routingAndAccountNumber.accountNumber.suffix(4))
                    )
            case .failure(let error):
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
            self.footerView.setIsLoading(false)
        }
    }

    private func adjustContinueButtonStateIfNeeded() {
        footerView.continueButton.isEnabled = (manualEntryFormView.routingAndAccountNumber != nil)
    }
}

// MARK: - ManualEntryFormViewDelegate

extension ManualEntryViewController: ManualEntryFormViewDelegate {

    func manualEntryFormViewTextDidChange(_ view: ManualEntryFormView) {
        adjustContinueButtonStateIfNeeded()
    }
}
