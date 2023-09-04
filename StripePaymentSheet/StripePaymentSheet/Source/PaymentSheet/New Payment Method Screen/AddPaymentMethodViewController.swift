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
import SwiftUI
import UIKit
protocol AddPaymentMethodViewControllerDelegate: AnyObject {
    func didUpdate(_ viewController: AddPaymentMethodViewController)
}

enum OverrideableBuyButtonBehavior {
    case LinkUSBankAccount
}

/// This displays:
/// - A carousel of Payment Method types
/// - Input fields for the selected Payment Method type
/// For internal SDK use only
@objc(STP_Internal_AddPaymentMethodViewController)
class AddPaymentMethodViewController: UIViewController {
    var viewModel: AddPaymentMethodViewModel

    // MARK: - Read-only Properties
    weak var delegate: AddPaymentMethodViewControllerDelegate?

    // MARK: - Views
    private lazy var paymentMethodDetailsView: UIView = {
        return viewModel.paymentMethodFormElement.view
    }()
    private lazy var paymentMethodTypesView: UIView = {
        return PaymentMethodTypeCollectionView(
            viewModel: viewModel.paymentMethodTypeSelectorViewModel,
            appearance: viewModel.configuration.appearance
        )
    }()
    private lazy var paymentMethodDetailsContainerView: DynamicHeightContainerView = {
        // when displaying link, we aren't in the bottom/payment sheet so pin to top for height changes
        let view = DynamicHeightContainerView(pinnedDirection: viewModel.configuration.linkPaymentMethodsOnly ? .top : .bottom)
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
        viewModel: AddPaymentMethodViewModel,
        delegate: AddPaymentMethodViewControllerDelegate? = nil
    ) {
        self.viewModel = viewModel
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)

        bindViewModel()
    }

    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = viewModel.configuration.appearance.colors.background

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
        if viewModel.paymentMethodTypeSelectorViewModel.paymentMethodTypes == [.card] {
            paymentMethodTypesView.isHidden = true
        } else {
            paymentMethodTypesView.isHidden = false
        }
        updateUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let formElement = (viewModel.paymentMethodFormElement as? PaymentMethodElementWrapper<FormElement>)?.element
            ?? viewModel.paymentMethodFormElement
        if viewModel.configuration.defaultBillingDetails == .init(),
           let addressSection = formElement.getAllSubElements()
            .compactMap({ $0 as? PaymentMethodElementWrapper<AddressSectionElement> }).first?.element
        {
            // If we're displaying an AddressSectionElement and we don't have default billing details, update it with the latest shipping details
            let delegate = addressSection.delegate
            addressSection.delegate = nil  // Stop didUpdate delegate calls to avoid laying out while we're being presented
            if let newShippingAddress = viewModel.configuration.shippingDetails()?.address {
                addressSection.updateBillingSameAsShippingDefaultAddress(.init(newShippingAddress))
            } else {
                addressSection.updateBillingSameAsShippingDefaultAddress(.init())
            }
            addressSection.delegate = delegate
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sendEventToSubviews(.viewDidAppear, from: view)
        delegate?.didUpdate(self)
    }

    // MARK: - Private

    private func bindViewModel() {
        viewModel.presentingViewControllerDelegate = self

        viewModel.addObserver(self) { [weak self] in
            guard let self = self else { return }

            self.updateUI()
            self.delegate?.didUpdate(self)
            sendEventToSubviews(.viewDidAppear, from: self.view)
        }
    }

    private func updateUI() {
        // Swap out the input view if necessary
        if viewModel.paymentMethodFormElement.view !== paymentMethodDetailsView {
            let oldView = paymentMethodDetailsView
            let newView = viewModel.paymentMethodFormElement.view
            self.paymentMethodDetailsView = newView

            // Add the new one and lay it out so it doesn't animate from a zero size
            paymentMethodDetailsContainerView.addPinnedSubview(newView)
            paymentMethodDetailsContainerView.layoutIfNeeded()
            newView.alpha = 0

            UISelectionFeedbackGenerator().selectionChanged()
            // Fade the new one in and the old one out
            animateHeightChange {
                self.paymentMethodDetailsContainerView.updateHeight()
                oldView.alpha = 0
                newView.alpha = 1
            } completion: { _ in
                // Remove the old one
                // This if check protects against a race condition where if you switch
                // between types with a re-used element (aka USBankAccountPaymentPaymentElement)
                // we swap the views before the animation completes
                if oldView !== self.paymentMethodDetailsView {
                    oldView.removeFromSuperview()
                }
            }
        }
    }

    func didTapCallToActionButton(behavior: OverrideableBuyButtonBehavior, from viewController: UIViewController) {
        switch behavior {
        case .LinkUSBankAccount:
            viewModel.handleCollectBankAccount(from: viewController)
        }
    }
}

// MARK: - PresentingViewControllerDelegate
extension AddPaymentMethodViewController: PresentingViewControllerDelegate {
    func presentViewController(viewController: UIViewController, completion: (() -> Void)?) {
        self.present(viewController, animated: true, completion: completion)
    }
}
