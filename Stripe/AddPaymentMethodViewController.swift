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
    func didUpdate(_ viewController: AddPaymentMethodViewController)
}

/// This displays:
/// - A carousel of Payment Method types
/// - Input fields for the selected Payment Method type
class AddPaymentMethodViewController: UIViewController {
    // MARK: - Read-only Properties
    weak var delegate: AddPaymentMethodViewControllerDelegate?
    let shouldDisplaySavePaymentMethodCheckbox: Bool
    let paymentMethodTypes: [STPPaymentMethodType]
    var selectedPaymentMethodType: STPPaymentMethodType {
        return paymentMethodTypesView.selected
    }
    var paymentOption: PaymentOption? {
        if let params = paymentMethodDetailsView.paymentMethodParams {
            return .new(paymentMethodParams: params, shouldSave: shouldSavePaymentMethod)
        }
        return nil
    }
    private var shouldSavePaymentMethod: Bool {
        return shouldDisplaySavePaymentMethodCheckbox && paymentMethodDetailsView.shouldSavePaymentMethod
    }

    private let billingAddressCollection: PaymentSheet.BillingAddressCollectionLevel
    private let merchantDisplayName: String

    // MARK: - Views
    private lazy var paymentMethodDetailsView: AddPaymentMethodView = {
        return makeInputView(for: paymentMethodTypesView.selected)
    }()
    private lazy var paymentMethodTypesView: PaymentMethodTypeCollectionView = {
        let view = PaymentMethodTypeCollectionView(
            paymentMethodTypes: paymentMethodTypes, delegate: self)
        return view
    }()
    private lazy var paymentMethodDetailsContainerView: BottomPinningContainerView = {
        let view = BottomPinningContainerView()
        view.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        view.addPinnedSubview(paymentMethodDetailsView)
        view.updateHeight()
        return view
    }()

    // MARK: - Inits
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(
        paymentMethodTypes: [STPPaymentMethodType],
        shouldDisplaySavePaymentMethodCheckbox: Bool,
        billingAddressCollection: PaymentSheet.BillingAddressCollectionLevel,
        merchantDisplayName: String,
        delegate: AddPaymentMethodViewControllerDelegate
    ) {
        self.shouldDisplaySavePaymentMethodCheckbox = shouldDisplaySavePaymentMethodCheckbox
        self.billingAddressCollection = billingAddressCollection
        self.merchantDisplayName = merchantDisplayName
        self.delegate = delegate
        self.paymentMethodTypes = paymentMethodTypes
        super.init(nibName: nil, bundle: nil)
    }

    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CompatibleColor.systemBackground

        let stackView = UIStackView(arrangedSubviews: [
            paymentMethodTypesView, paymentMethodDetailsContainerView,
        ])
        stackView.bringSubviewToFront(paymentMethodTypesView)
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        if paymentMethodTypes == [.card] {
            paymentMethodTypesView.isHidden = true
        } else {
            paymentMethodTypesView.isHidden = false
        }
        updateUI()
    }

    // MARK: - Internal
    /// Returns true iff we could map the error to one of the displayed fields
    func setErrorIfNecessary(for error: Error?) -> Bool {
        if let error = error {
            return paymentMethodDetailsView.setErrorIfNecessary(for: error)
        } else {
            return false
        }
    }

    // MARK: - Private

    private func updateUI() {
        let paymentMethodType = paymentMethodTypesView.selected

        // Swap out the input view if necessary
        if paymentMethodDetailsView.paymentMethodType != paymentMethodType {
            let oldView = paymentMethodDetailsView
            let newView = makeInputView(for: paymentMethodType)
            self.paymentMethodDetailsView = newView

            // Add the new one and lay it out so it doesn't animate from a zero size
            paymentMethodDetailsContainerView.addPinnedSubview(newView)
            paymentMethodDetailsContainerView.layoutIfNeeded()
            newView.alpha = 0

            // Fade the new one in and the old one out
            animateHeightChange {
                self.paymentMethodDetailsContainerView.updateHeight()
                oldView.alpha = 0
                newView.alpha = 1
            } completion: { _ in
                // Remove the old one
                oldView.removeFromSuperview()
            }
        }
    }

    private func makeInputView(for type: STPPaymentMethodType) -> AddPaymentMethodView {
        let addPaymentMethodView: AddPaymentMethodView = {
            switch type {
            case .card:
                return CardDetailsEditView(
                    shouldDisplaySaveThisPaymentMethodCheckbox: shouldDisplaySavePaymentMethodCheckbox,
                    billingAddressCollection: billingAddressCollection,
                    merchantDisplayName: merchantDisplayName,
                    delegate: self
                )
            case .iDEAL:
                return IdealDetailsEditView(delegate: self)
            case .alipay:
                return AlipayDetailsEditView(
                    billingAddressCollectionLevel: billingAddressCollection)
            default:
                fatalError()
            }
        }()
        addPaymentMethodView.delegate = self
        return addPaymentMethodView
    }
}

// MARK: - PaymentMethodTypeCollectionViewDelegate

extension AddPaymentMethodViewController: PaymentMethodTypeCollectionViewDelegate {
    func didUpdateSelection(_ paymentMethodTypeCollectionView: PaymentMethodTypeCollectionView) {
        updateUI()
        delegate?.didUpdate(self)
    }
}

// MARK: - AddPaymentMethodViewDelegate

extension AddPaymentMethodViewController: AddPaymentMethodViewDelegate {
    func didUpdate(_ addPaymentMethodView: AddPaymentMethodView) {
        updateUI()
        delegate?.didUpdate(self)
    }
}

// MARK: - AddPaymentMethodView

protocol AddPaymentMethodViewDelegate: AnyObject {
    func didUpdate(_ addPaymentMethodView: AddPaymentMethodView)
}

protocol AddPaymentMethodView: UIView {
    var delegate: AddPaymentMethodViewDelegate? { get set }
    /// The type of payment method this view is displaying
    var paymentMethodType: STPPaymentMethodType { get }
    /// Return nil if incomplete or invalid
    var paymentMethodParams: STPPaymentMethodParams? { get }
    var shouldSavePaymentMethod: Bool { get }
    /// Returns true iff we could map the error to one of the displayed fields
    func setErrorIfNecessary(for apiError: Error) -> Bool
}
