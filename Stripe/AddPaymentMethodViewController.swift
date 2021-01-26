//
//  AddPaymentMethodViewController.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 10/13/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

protocol AddPaymentMethodViewControllerDelegate: AnyObject {
    func didUpdatePaymentMethodParams(_ viewController: AddPaymentMethodViewController)
}

/**
 This displays:
 - A carousel of Payment Method types
 - Input fields for the selected Payment Method type
 */
class AddPaymentMethodViewController: UIViewController {
    // MARK: - Read-only Properties
    weak var delegate: AddPaymentMethodViewControllerDelegate?
    private let isGuestMode: Bool
    private let paymentMethodTypes: [STPPaymentMethodType]
    var paymentOption: PaymentOption? {
        if let params = paymentMethodDetailsView.paymentMethodParams {
            return .new(paymentMethodParams: params, shouldSave: shouldSavePaymentMethod)
        }
        return nil
    }
    private var shouldSavePaymentMethod: Bool {
        return !isGuestMode && paymentMethodDetailsView.shouldSavePaymentMethod
    }

    private let billingAddressCollection: PaymentSheet.BillingAddressCollectionLevel
    private let merchantDisplayName: String

    // MARK: - Views
    private lazy var paymentMethodDetailsView: AddPaymentMethodView = {
        return makeInputView(for: paymentMethodTypesView.selected)
    }()
    private lazy var paymentMethodTypesView: PaymentMethodTypeCollectionView = {
        let view = PaymentMethodTypeCollectionView(paymentMethodTypes: paymentMethodTypes, delegate: self)
        return view
    }()
    private lazy var containerStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [paymentMethodTypesView, paymentMethodDetailsView])
        stackView.axis = .vertical
        stackView.spacing = 8
        return stackView
    }()

    // MARK: - Inits
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(paymentMethodTypes: Set<STPPaymentMethodType>,
                  isGuestMode: Bool,
                  billingAddressCollection: PaymentSheet.BillingAddressCollectionLevel,
                  merchantDisplayName: String,
                  delegate: AddPaymentMethodViewControllerDelegate) {
        self.isGuestMode = isGuestMode
        self.paymentMethodTypes = Array(paymentMethodTypes)
        self.billingAddressCollection = billingAddressCollection
        self.merchantDisplayName = merchantDisplayName
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CompatibleColor.systemBackground

        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerStackView)
        view.directionalLayoutMargins = PaymentSheetUI.defaultMargins

        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
        updateUI()
    }
    
    // MARK: - Internal
    /// Returns true iff we could map the error to one of the displayed fields
    internal func markFormErrors(for apiError: Error) -> Bool {
        paymentMethodDetailsView.markFormErrors(for: apiError)
    }

    // MARK: - Private

    private func updateUI() {
        let paymentMethodType = paymentMethodTypesView.selected
        // If there's only one possible payment method type, don't show the carousel
        if paymentMethodTypes.count <= 1 {
            paymentMethodTypesView.isHidden = true
        } else {
            paymentMethodTypesView.isHidden = false
        }

        // Swap out the input view if necessary
        if paymentMethodDetailsView.paymentMethodType != paymentMethodType {
            let newPaymentMethodDetailsView = makeInputView(for: paymentMethodType)
            newPaymentMethodDetailsView.delegate = self
            paymentMethodTypesView.removeFromSuperview()
            containerStackView.addArrangedSubview(newPaymentMethodDetailsView)
        }
    }

    private func makeInputView(for type: STPPaymentMethodType) -> AddPaymentMethodView {
        // Hardcoded to cards for now
        let cardDetailsView = CardDetailsEditView(canSaveCard: !isGuestMode, billingAddressCollection: billingAddressCollection, merchantDisplayName: merchantDisplayName, delegate: self)
        return cardDetailsView
    }
}

// MARK: - PaymentMethodTypeCollectionViewDelegate

extension AddPaymentMethodViewController: PaymentMethodTypeCollectionViewDelegate {
    func didUpdateSelection(_ paymentMethodTypeCollectionView: PaymentMethodTypeCollectionView) {
        updateUI()
    }
}

// MARK: - AddPaymentMethodViewDelegate

extension AddPaymentMethodViewController: AddPaymentMethodViewDelegate {
    func didUpdate(_ addPaymentMethodView: AddPaymentMethodView) {
        updateUI()
        delegate?.didUpdatePaymentMethodParams(self)
    }
}

// MARK: - AddPaymentMethodView

protocol AddPaymentMethodViewDelegate: AnyObject {
    func didUpdate(_ addPaymentMethodView: AddPaymentMethodView)
}

protocol AddPaymentMethodView: UIView {
    /// The type of payment method this view is displaying
    var paymentMethodType: STPPaymentMethodType { get }
    /// Return nil if incomplete or invalid
    var paymentMethodParams: STPPaymentMethodParams? { get }
    var delegate: AddPaymentMethodViewDelegate? { get set }
    var shouldSavePaymentMethod: Bool { get }
    /// Returns true iff we could map the error to one of the displayed fields
    func markFormErrors(for apiError: Error) -> Bool
}
