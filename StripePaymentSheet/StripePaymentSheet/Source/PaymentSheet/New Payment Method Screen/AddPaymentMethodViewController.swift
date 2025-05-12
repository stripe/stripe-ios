//
//  AddPaymentMethodViewController.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 10/13/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit
protocol AddPaymentMethodViewControllerDelegate: AnyObject {
    func getWalletHeaders() -> [String]
    func didUpdate(_ viewController: AddPaymentMethodViewController)
    func updateErrorLabel(for: Error?)
}

enum OverrideableBuyButtonBehavior {
    case LinkUSBankAccount
    case instantDebits
}

/// This displays:
/// - A carousel of Payment Method types
/// - Input fields for the selected Payment Method type
/// For internal SDK use only
@objc(STP_Internal_AddPaymentMethodViewController)
class AddPaymentMethodViewController: UIViewController {
    enum Error: Swift.Error {
        case paymentMethodTypesEmpty
    }

    // MARK: - Read-only Properties
    weak var delegate: AddPaymentMethodViewControllerDelegate?
    let paymentMethodTypes: [PaymentSheet.PaymentMethodType]
    var selectedPaymentMethodType: PaymentSheet.PaymentMethodType {
        paymentMethodTypesView.selected
    }
    var paymentOption: PaymentOption? {
        paymentMethodFormViewController.paymentOption
    }

    var overridePrimaryButtonState: OverridePrimaryButtonState? {
        paymentMethodFormViewController.overridePrimaryButtonState
    }

    var bottomNoticeAttributedString: NSAttributedString? {
        paymentMethodFormViewController.bottomNoticeAttributedString
    }

    private let intent: Intent
    private let elementsSession: STPElementsSession
    private let configuration: PaymentElementConfiguration
    private let formCache: PaymentMethodFormCache
    private let analyticsHelper: PaymentSheetAnalyticsHelper
    var previousCustomerInput: IntentConfirmParams?

    private var paymentMethodFormElement: PaymentMethodElement {
        paymentMethodFormViewController.form
    }

    // MARK: - Views
    private lazy var paymentMethodFormViewController: PaymentMethodFormViewController = {
        let pmFormVC = PaymentMethodFormViewController(type: selectedPaymentMethodType, intent: intent, elementsSession: elementsSession, previousCustomerInput: previousCustomerInput, formCache: formCache, configuration: configuration, headerView: nil, analyticsHelper: analyticsHelper, delegate: self)
        // Only use the previous customer input in the very first load, to avoid overwriting customer input
        previousCustomerInput = nil
        return pmFormVC
    }()
    private lazy var paymentMethodTypesView: PaymentMethodTypeCollectionView = {
        let view = PaymentMethodTypeCollectionView(
            paymentMethodTypes: paymentMethodTypes,
            initialPaymentMethodType: previousCustomerInput?.paymentMethodType,
            appearance: configuration.appearance,
            currency: intent.currency,
            incentive: elementsSession.incentive,
            delegate: self
        )
        return view
    }()
    private lazy var paymentMethodDetailsContainerView: DynamicHeightContainerView = {
        let view = DynamicHeightContainerView(pinnedDirection: .bottom)
        view.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        return view
    }()

    // MARK: - Inits
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(
        intent: Intent,
        elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration,
        previousCustomerInput: IntentConfirmParams? = nil,
        paymentMethodTypes: [PaymentSheet.PaymentMethodType],
        formCache: PaymentMethodFormCache,
        analyticsHelper: PaymentSheetAnalyticsHelper,
        delegate: AddPaymentMethodViewControllerDelegate? = nil
    ) {
        if paymentMethodTypes.isEmpty {
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetError,
                                              error: Error.paymentMethodTypesEmpty)
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
        }
        stpAssert(!paymentMethodTypes.isEmpty, "At least one payment method type must be available.")
        self.configuration = configuration
        self.intent = intent
        self.elementsSession = elementsSession
        self.previousCustomerInput = previousCustomerInput
        self.paymentMethodTypes = paymentMethodTypes
        self.delegate = delegate
        self.formCache = formCache
        self.analyticsHelper = analyticsHelper
        super.init(nibName: nil, bundle: nil)
    }

    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = configuration.appearance.colors.background

        let stackView = UIStackView(arrangedSubviews: [
            paymentMethodTypesView, paymentMethodDetailsContainerView,
        ])
        stackView.bringSubviewToFront(paymentMethodTypesView)
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addAndPinSubview(stackView)
        if paymentMethodTypes == [.stripe(.card)] {
            paymentMethodTypesView.isHidden = true
        } else {
            paymentMethodTypesView.isHidden = false
        }
        updateUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logRenderLPMs()
        delegate?.didUpdate(self)
    }

    private func logRenderLPMs() {
        // These are the cells that are visible without scrolling in the horizontal carousel
        let visibleLPMCells: [PaymentMethodTypeCollectionView.PaymentTypeCell] = paymentMethodTypesView.visibleCells.compactMap { $0 as? PaymentMethodTypeCollectionView.PaymentTypeCell }
        var visibleLPMs: [String] = visibleLPMCells.compactMap { $0.paymentMethodType.identifier }
        // If there are no cells in the carousel and one payment method type, it's because the form is expanded
        if visibleLPMCells.isEmpty, paymentMethodTypes.count == 1, let paymentMethodType = paymentMethodTypes.first {
            visibleLPMs.append(paymentMethodType.identifier)
        }
        // Add wallet LPMs
        let walletLPMs: [String] = delegate?.getWalletHeaders() ?? []
        visibleLPMs.append(contentsOf: walletLPMs)
        // These LPMs are not visible without without scrolling in the horizontal carousel
        let hiddenLPMs: [String] = paymentMethodTypes.compactMap { $0.identifier }.filter { !visibleLPMs.contains($0) }
        analyticsHelper.logRenderLPMs(visibleLPMs: visibleLPMs, hiddenLPMs: hiddenLPMs)
    }

    // MARK: - Private

    private func updateUI() {
        // Swap out the input view if necessary
        switchContentIfNecessary(to: paymentMethodFormViewController, containerView: paymentMethodDetailsContainerView)
    }

    private func updateFormElement() {
        if selectedPaymentMethodType != paymentMethodFormViewController.paymentMethodType {
            paymentMethodFormViewController = PaymentMethodFormViewController(
                type: selectedPaymentMethodType,
                intent: intent,
                elementsSession: elementsSession,
                previousCustomerInput: previousCustomerInput,
                formCache: formCache,
                configuration: configuration,
                headerView: nil,
                analyticsHelper: analyticsHelper,
                delegate: self
            )
        }
        updateUI()
    }

    // MARK: - Internal

    func didTapCallToActionButton(from viewController: UIViewController) {
        paymentMethodFormViewController.didTapCallToActionButton(from: viewController)
    }

    func clearTextFields() {
        paymentMethodFormElement.clearTextFields()
    }
}

// MARK: - PaymentMethodTypeCollectionViewDelegate

extension AddPaymentMethodViewController: PaymentMethodTypeCollectionViewDelegate {
    func didUpdateSelection(_ paymentMethodTypeCollectionView: PaymentMethodTypeCollectionView) {
        analyticsHelper.logNewPaymentMethodSelected(paymentMethodTypeIdentifier: selectedPaymentMethodType.identifier)
#if !canImport(CompositorServices)
            UISelectionFeedbackGenerator().selectionChanged()
#endif
        updateFormElement()
        delegate?.didUpdate(self)
    }
}

// MARK: - PaymentMethodFormViewControllerDelegate

extension AddPaymentMethodViewController: PaymentMethodFormViewControllerDelegate {
    func didUpdate(_ viewController: PaymentMethodFormViewController) {
        delegate?.didUpdate(self)

        if let instantDebitsFormElement = viewController.form as? InstantDebitsPaymentMethodElement {
            let incentive = instantDebitsFormElement.displayableIncentive
            paymentMethodTypesView.setIncentive(incentive)
        }
    }

    func updateErrorLabel(for error: Swift.Error?) {
        delegate?.updateErrorLabel(for: error)
    }
}
