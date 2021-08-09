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
    lazy var paymentMethodTypes: [STPPaymentMethodType] = {
        return intent.orderedPaymentMethodTypes.filter {
            PaymentSheet.supportsAdding(paymentMethod: $0, with: configuration)
        }
    }()
    var selectedPaymentMethodType: STPPaymentMethodType {
        return paymentMethodTypesView.selected
    }
    var paymentOption: PaymentOption? {
        if let params = paymentMethodFormElement.updateParams(
            params: IntentConfirmParams(type: selectedPaymentMethodType)
        ) {
            return .new(confirmParams: params)
        }
        return nil
    }

    private let intent: Intent
    private let configuration: PaymentSheet.Configuration
    private lazy var paymentMethodFormElement: Element = {
        return makeElement(for: selectedPaymentMethodType)
    }()

    // MARK: - Views
    private lazy var paymentMethodDetailsView: UIView = {
        return paymentMethodFormElement.view
    }()
    private lazy var paymentMethodTypesView: PaymentMethodTypeCollectionView = {
        let view = PaymentMethodTypeCollectionView(
            paymentMethodTypes: paymentMethodTypes, delegate: self)
        return view
    }()
    private lazy var paymentMethodDetailsContainerView: DynamicHeightContainerView = {
        let view = DynamicHeightContainerView()
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
        intent: Intent,
        configuration: PaymentSheet.Configuration,
        delegate: AddPaymentMethodViewControllerDelegate
    ) {
        self.configuration = configuration
        self.intent = intent
        self.delegate = delegate
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

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        if let cardDetailsView = paymentMethodDetailsView as? CardDetailsEditView {
            cardDetailsView.deviceOrientation = UIDevice.current.orientation
        }
    }

    // MARK: - Internal
    
    /// Returns true iff we could map the error to one of the displayed fields
    func setErrorIfNecessary(for error: Error?) -> Bool {
        // TODO
        return false
    }

    // MARK: - Private

    private func updateUI() {
        // Swap out the input view if necessary
        if paymentMethodFormElement.view !== paymentMethodDetailsView {
            let oldView = paymentMethodDetailsView
            let newView = paymentMethodFormElement.view
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
                oldView.removeFromSuperview()
            }
        }
    }

    private func makeElement(for type: STPPaymentMethodType) -> Element {
        let saveMode: FormElement.Configuration.SaveMode = {
            switch intent {
            case let .paymentIntent(paymentIntent):
                if configuration.customer == nil {
                    return .none
                } else if paymentIntent.setupFutureUsage != .none {
                    return .merchantRequired
                } else {
                    return .userSelectable
                }
            case .setupIntent:
                return .merchantRequired
            }
        }()
        let formConfiguration = FormElement.Configuration(
            saveMode: saveMode,
            merchantDisplayName: configuration.merchantDisplayName
        )
        let paymentMethodElement: Element = {
            switch type {
            case .card:
                return CardDetailsEditView(
                    shouldDisplaySaveThisPaymentMethodCheckbox: saveMode == .userSelectable,
                    billingAddressCollection: configuration.billingAddressCollectionLevel,
                    merchantDisplayName: configuration.merchantDisplayName
                )
            case .bancontact:
                return FormElement.makeBancontact(configuration: formConfiguration)
            case .iDEAL:
                return FormElement.makeIdeal(configuration: formConfiguration)
            case .alipay:
                return FormElement(elements: [])
            case .sofort:
                return FormElement.makeSofort(configuration: formConfiguration)
            case .SEPADebit:
                return FormElement.makeSepa(configuration: formConfiguration)
            case .giropay:
                return FormElement.makeGiropay(configuration: formConfiguration)
            case .EPS:
                return FormElement.makeEPS(configuration: formConfiguration)
            case .przelewy24:
                return FormElement.makeP24(configuration: formConfiguration)
            default:
                fatalError()
            }
        }()
        paymentMethodElement.delegate = self
        return paymentMethodElement
    }
}

// MARK: - PaymentMethodTypeCollectionViewDelegate

extension AddPaymentMethodViewController: PaymentMethodTypeCollectionViewDelegate {
    func didUpdateSelection(_ paymentMethodTypeCollectionView: PaymentMethodTypeCollectionView) {
        paymentMethodFormElement = makeElement(for: paymentMethodTypeCollectionView.selected)
        updateUI()
        delegate?.didUpdate(self)
    }
}

// MARK: - AddPaymentMethodViewDelegate

extension AddPaymentMethodViewController: ElementDelegate {
    func didFinishEditing(element: Element) { /* no-op */ }
    
    func didUpdate(element: Element) {
        delegate?.didUpdate(self)
        animateHeightChange()
    }
}
