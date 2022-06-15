//
//  AddPaymentMethodViewController.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 10/13/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore
@_spi(STP) import StripeCore
protocol AddPaymentMethodViewControllerDelegate: AnyObject {
    func didUpdate(_ viewController: AddPaymentMethodViewController)
    func shouldOfferLinkSignup(_ viewController: AddPaymentMethodViewController) -> Bool
    func updateErrorLabel(for: Error?)
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
    // MARK: - Read-only Properties
    weak var delegate: AddPaymentMethodViewControllerDelegate?
    lazy var paymentMethodTypes: [PaymentSheet.PaymentMethodType] = {
        var recommendedPaymentMethodTypes = PaymentSheet.PaymentMethodType.recommendedPaymentMethodTypes(from: intent)
        if configuration.linkPaymentMethodsOnly {
            // If we're in the Link modal, manually add instant debit
            // as an option and let the support calls decide if it's allowed
            recommendedPaymentMethodTypes.append(.linkInstantDebit)
        }

        let paymentTypes = recommendedPaymentMethodTypes.filter {
            PaymentSheet.PaymentMethodType.supportsAdding(
                paymentMethod: $0,
                configuration: configuration,
                intent: intent,
                supportedPaymentMethods: configuration.linkPaymentMethodsOnly ?
                    PaymentSheet.supportedLinkPaymentMethods : PaymentSheet.supportedPaymentMethods
            )
        }
        return paymentTypes
    }()
    var selectedPaymentMethodType: PaymentSheet.PaymentMethodType {
        return paymentMethodTypesView.selected
    }
    var paymentOption: PaymentOption? {
        if let linkEnabledElement = paymentMethodFormElement as? LinkEnabledPaymentMethodElement {
            return linkEnabledElement.makePaymentOption()
        }

        if let params = paymentMethodFormElement.updateParams(
            params: IntentConfirmParams(type: selectedPaymentMethodType)
        ) {
            return .new(confirmParams: params)
        }
        return nil
    }

    var linkAccount: PaymentSheetLinkAccount? {
        didSet {
            // This property changes when PaymentSheet is in the background. We must set the correct
            // theme before updating the form.
            configuration.appearance.asElementsTheme.performAsCurrent {
                updateFormElement()
            }
        }
    }

    var overrideCallToAction: ConfirmButton.CallToActionType? {
        return overrideBuyButtonBehavior != nil
        ? ConfirmButton.CallToActionType.customWithLock(title: String.Localized.continue)
        : nil
    }

    var overrideCallToActionShouldEnable: Bool {
        guard let overrideBuyButtonBehavior = overrideBuyButtonBehavior else {
            return false
        }
        switch overrideBuyButtonBehavior {
        case .LinkUSBankAccount:
            return usBankAccountFormElement?.canLinkAccount ?? false
        }
    }

    var bottomNoticeAttributedString: NSAttributedString? {
        if selectedPaymentMethodType == .USBankAccount {
            if let usBankPaymentMethodElement = paymentMethodFormElement as? USBankAccountPaymentMethodElement {
                return usBankPaymentMethodElement.mandateString
            }
        }
        return nil
    }

    var overrideBuyButtonBehavior: OverrideableBuyButtonBehavior? {
        if selectedPaymentMethodType == .USBankAccount {
            if let paymentOption = paymentOption,
               case .new = paymentOption {
                return nil // already have PaymentOption
            } else {
                return .LinkUSBankAccount
            }
        }
        return nil
    }

    private let intent: Intent
    private let configuration: PaymentSheet.Configuration

    private lazy var usBankAccountFormElement: USBankAccountPaymentMethodElement? = {
        // We are keeping usBankAccountInfo in memory to preserve state
        // if the user switches payment method types
        let paymentMethodElement = makeElement(for: selectedPaymentMethodType)
        if let usBankAccountPaymentMethodElement = paymentMethodElement as? USBankAccountPaymentMethodElement {
            usBankAccountPaymentMethodElement.presentingViewControllerDelegate = self
        } else {
            assertionFailure("Wrong type for usBankAccountFormElement")
        }
        return paymentMethodElement as? USBankAccountPaymentMethodElement
    }()
    private lazy var paymentMethodFormElement: PaymentMethodElement = {
        if selectedPaymentMethodType == .USBankAccount,
        let usBankAccountFormElement = usBankAccountFormElement {
            return usBankAccountFormElement
        }
        return makeElement(for: selectedPaymentMethodType)
    }()

    // MARK: - Views
    private lazy var paymentMethodDetailsView: UIView = {
        return paymentMethodFormElement.view
    }()
    private lazy var paymentMethodTypesView: PaymentMethodTypeCollectionView = {
        let view = PaymentMethodTypeCollectionView(
            paymentMethodTypes: paymentMethodTypes, appearance: configuration.appearance, delegate: self)
        return view
    }()
    private lazy var paymentMethodDetailsContainerView: DynamicHeightContainerView = {
        // when displaying link, we aren't in the bottom/payment sheet so pin to top for height changes
        let view = DynamicHeightContainerView(pinnedDirection: configuration.linkPaymentMethodsOnly ? .top : .bottom)
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
        delegate: AddPaymentMethodViewControllerDelegate,
        linkAccount: PaymentSheetLinkAccount? = nil
    ) {
        self.configuration = configuration
        self.intent = intent
        self.delegate = delegate
        self.linkAccount = linkAccount
        super.init(nibName: nil, bundle: nil)
        self.view.backgroundColor = configuration.appearance.colors.background
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
                // This if check protects against a race condition where if you switch
                // between types with a re-used element (aka USBankAccountPaymentPaymentElement)
                // we swap the views before the animation completes
                if oldView !== self.paymentMethodDetailsView {
                    oldView.removeFromSuperview()
                }
            }
        }
    }

    private func makeElement(for type: PaymentSheet.PaymentMethodType) -> PaymentMethodElement {
        let offerSaveToLinkWhenSupported = delegate?.shouldOfferLinkSignup(self) ?? false

        let formElement = PaymentSheetFormFactory(
            intent: intent,
            configuration: configuration,
            paymentMethod: type,
            offerSaveToLinkWhenSupported: offerSaveToLinkWhenSupported,
            linkAccount: linkAccount
        ).make()
        formElement.delegate = self
        return formElement
    }

    private func updateFormElement() {
        if selectedPaymentMethodType == .USBankAccount,
        let usBankAccountFormElement = usBankAccountFormElement {
            paymentMethodFormElement = usBankAccountFormElement
        } else {
            paymentMethodFormElement = makeElement(for: selectedPaymentMethodType)
        }
        updateUI()
    }

    func didTapCallToActionButton(behavior: OverrideableBuyButtonBehavior, from viewController: UIViewController) {
        switch(behavior) {
        case .LinkUSBankAccount:
            handleCollectBankAccount(from: viewController)
        }
    }

    func handleCollectBankAccount(from viewController: UIViewController) {
        guard let usBankAccountPaymentMethodElement = self.paymentMethodFormElement as? USBankAccountPaymentMethodElement,
        let name = usBankAccountPaymentMethodElement.name,
        let email = usBankAccountPaymentMethodElement.email else {
            assertionFailure()
            return
        }

        let params = STPCollectBankAccountParams.collectUSBankAccountParams(
            with: name,
            email: email)
        let client = STPBankAccountCollector()
        let errorText = STPLocalizedString("Something went wrong when linking your account.\nPlease try again later.",
                                           "Error message when an error case happens when linking your account")
        let genericError = PaymentSheetError.unknown(debugDescription: errorText)

        let financialConnectionsCompletion: (FinancialConnectionsSDKResult?, LinkAccountSession?, NSError?) -> Void = { result, linkAccountSession, error in
            if let _ = error {
                self.delegate?.updateErrorLabel(for: genericError)
                return
            }
            guard let financialConnectionsResult = result else {
                self.delegate?.updateErrorLabel(for: genericError)
                return
            }

            switch(financialConnectionsResult) {
            case .cancelled:
                break
            case .completed(let linkedBank):
                usBankAccountPaymentMethodElement.setLinkedBank(linkedBank)
            case .failed:
                self.delegate?.updateErrorLabel(for: genericError)
            }
        }
        switch(intent) {
        case .paymentIntent:
            client.collectBankAccountForPayment(clientSecret: intent.clientSecret,
                                                params: params,
                                                from: viewController,
                                                financialConnectionsCompletion: financialConnectionsCompletion)
        case .setupIntent:
            client.collectBankAccountForSetup(clientSecret: intent.clientSecret,
                                              params: params,
                                              from: viewController,
                                              financialConnectionsCompletion: financialConnectionsCompletion)
        }
    }
}

// MARK: - PaymentMethodTypeCollectionViewDelegate

extension AddPaymentMethodViewController: PaymentMethodTypeCollectionViewDelegate {
    func didUpdateSelection(_ paymentMethodTypeCollectionView: PaymentMethodTypeCollectionView) {
        updateFormElement()
        delegate?.didUpdate(self)
    }
}

// MARK: - ElementDelegate

extension AddPaymentMethodViewController: ElementDelegate {
    func continueToNextField(element: Element) {
        delegate?.didUpdate(self)
    }
    
    func didUpdate(element: Element) {
        delegate?.didUpdate(self)
        animateHeightChange()
    }
}

extension AddPaymentMethodViewController: PresentingViewControllerDelegate {
    func presentViewController(viewController: UIViewController, completion: (() -> Void)?) {
        self.present(viewController, animated: true, completion: completion)
    }
}
