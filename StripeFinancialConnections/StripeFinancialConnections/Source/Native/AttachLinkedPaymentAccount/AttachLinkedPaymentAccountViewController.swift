//
//  AttachLinkedPaymentAccountViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/28/22.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol AttachLinkedPaymentAccountViewControllerDelegate: AnyObject {
    func attachLinkedPaymentAccountViewController(
        _ viewController: AttachLinkedPaymentAccountViewController,
        didFinishWithPaymentAccountResource paymentAccountResource: FinancialConnectionsPaymentAccountResource,
        saveToLinkWithStripeSucceeded: Bool?
    )
    func attachLinkedPaymentAccountViewControllerDidSelectAnotherBank(
        _ viewController: AttachLinkedPaymentAccountViewController
    )
    func attachLinkedPaymentAccountViewControllerDidSelectManualEntry(
        _ viewController: AttachLinkedPaymentAccountViewController
    )
    func attachLinkedPaymentAccountViewController(
        _ viewController: AttachLinkedPaymentAccountViewController,
        didReceiveEvent event: FinancialConnectionsEvent
    )
}

final class AttachLinkedPaymentAccountViewController: UIViewController {

    private let dataSource: AttachLinkedPaymentAccountDataSource
    weak var delegate: AttachLinkedPaymentAccountViewControllerDelegate?

    private var didSelectAnotherBank: () -> Void {
        return { [weak self] in
            guard let self = self else { return }
            self.delegate?.attachLinkedPaymentAccountViewControllerDidSelectAnotherBank(self)
        }
    }
    // we only allow to retry once
    private var allowRetry = true
    private var didSelectTryAgain: (() -> Void)? {
        return allowRetry
            ? { [weak self] in
                guard let self = self else { return }
                self.allowRetry = false
                self.showErrorView(nil)
                self.attachLinkedAccountIdToLinkAccountSession()
            } : nil
    }
    private var didSelectManualEntry: (() -> Void)? {
        return (dataSource.manifest.allowManualEntry && !dataSource.reduceManualEntryProminenceInErrors)
            ? { [weak self] in
                guard let self = self else { return }
                self.delegate?.attachLinkedPaymentAccountViewControllerDidSelectManualEntry(self)
            } : nil
    }
    private var errorView: UIView?

    init(dataSource: AttachLinkedPaymentAccountDataSource) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = FinancialConnectionsAppearance.Colors.background
        navigationItem.hidesBackButton = true

        dataSource
            .analyticsClient
            .logPaneLoaded(pane: .attachLinkedPaymentAccount)

        attachLinkedAccountIdToLinkAccountSession()
    }

    private func attachLinkedAccountIdToLinkAccountSession() {
        let loadingView = SpinnerView(appearance: dataSource.manifest.appearance)
        view.addAndPinSubviewToSafeArea(loadingView)

        let pollingStartDate = Date()
        dataSource.attachLinkedAccountIdToLinkAccountSession()
            .observe { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let paymentAccountResource):
                    var saveToLinkWithStripeSucceeded: Bool?
                    if self.dataSource.manifest.isNetworkingUserFlow == true {
                        if self.dataSource.manifest.accountholderIsLinkConsumer == true {
                            saveToLinkWithStripeSucceeded = paymentAccountResource.networkingSuccessful
                        }
                    }

                    self.dataSource
                        .analyticsClient
                        .log(
                            eventName: "polling.attachPayment.success",
                            parameters: [
                                "duration": Date().timeIntervalSince(pollingStartDate).milliseconds,
                                "authSessionId": self.dataSource.authSessionId ?? "unknown",
                            ],
                            pane: .attachLinkedPaymentAccount
                        )

                    self.delegate?.attachLinkedPaymentAccountViewController(
                        self,
                        didFinishWithPaymentAccountResource: paymentAccountResource,
                        saveToLinkWithStripeSucceeded: saveToLinkWithStripeSucceeded
                    )
                // we don't remove `linkingAccountsLoadingView` on success
                // because this is the last time the user will see this
                // screen, and we don't want to show a blank background
                // while we transition to the next pane
                case .failure(let error):
                    loadingView.removeFromSuperview()
                    if let error = error as? StripeError,
                        case .apiError(let apiError) = error,
                        let extraFields = apiError.allResponseFields["extra_fields"] as? [String: Any],
                        let reason = extraFields["reason"] as? String,
                        reason == "account_number_retrieval_failed"
                    {
                        let errorView = AccountNumberRetrievalErrorView(
                            institution: self.dataSource.institution,
                            appearance: self.dataSource.manifest.appearance,
                            didSelectAnotherBank: self.didSelectAnotherBank,
                            didSelectEnterBankDetailsManually: self.didSelectManualEntry
                        )
                        self.showErrorView(errorView)
                        self.dataSource
                            .analyticsClient
                            .logExpectedError(
                                error,
                                errorName: "AccountNumberRetrievalError",
                                pane: .attachLinkedPaymentAccount
                            )
                    } else {
                        // something unknown happened here, allow a retry
                        let errorView = AccountPickerAccountLoadErrorView(
                            institution: self.dataSource.institution,
                            appearance: self.dataSource.manifest.appearance,
                            didSelectAnotherBank: self.didSelectAnotherBank,
                            didSelectTryAgain: self.didSelectTryAgain,
                            didSelectEnterBankDetailsManually: self.didSelectManualEntry
                        )
                        self.showErrorView(errorView)
                        self.dataSource
                            .analyticsClient
                            .logUnexpectedError(
                                error,
                                errorName: "AttachLinkedPaymentAccountError",
                                pane: .attachLinkedPaymentAccount
                            )
                    }
                }
            }
    }

    private func showErrorView(_ errorView: UIView?) {
        if let errorView = errorView {
            view.addAndPinSubview(errorView)
        } else {
            // clear last error
            self.errorView?.removeFromSuperview()
        }
        self.errorView = errorView
    }
}
