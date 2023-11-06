//
//  CustomerAddPaymentMethodViewController.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

protocol CustomerAddPaymentMethodViewControllerDelegate: AnyObject {
    func didUpdate(_ viewController: CustomerAddPaymentMethodViewController)
    func updateErrorLabel(for: Error?)
}

@objc(STP_Internal_CustomerAddPaymentMethodViewController)
class CustomerAddPaymentMethodViewController: UIViewController {

    let paymentMethodTypes: [PaymentSheet.PaymentMethodType]

    // MARK: - Read-only Properties
    weak var delegate: CustomerAddPaymentMethodViewControllerDelegate?

    var selectedPaymentMethodType: PaymentSheet.PaymentMethodType {
        return paymentMethodTypesView.selected
    }
    var paymentOption: PaymentOption? {
        let params = IntentConfirmParams(type: selectedPaymentMethodType)
        params.setDefaultBillingDetailsIfNecessary(for: configuration)
        if let params = paymentMethodFormElement.updateParams(params: params) {
            return .new(confirmParams: params)
        }
        return nil
    }
    // MARK: - Writable Properties
    private let configuration: CustomerSheet.Configuration
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

    var overrideActionButtonBehavior: OverrideableBuyButtonBehavior? {
        if selectedPaymentMethodType == .stripe(.USBankAccount) {
            if let paymentOption = paymentOption,
               case .new = paymentOption {
                return nil // already have PaymentOption
            } else {
                return .LinkUSBankAccount
            }
        }
        return nil
    }

    var overrideCallToAction: ConfirmButton.CallToActionType? {
        return overrideActionButtonBehavior != nil
            ? ConfirmButton.CallToActionType.customWithLock(title: String.Localized.continue)
            : nil
    }
    var overrideCallToActionShouldEnable: Bool {
        guard let overrideBuyButtonBehavior = overrideActionButtonBehavior else {
            return false
        }
        switch overrideBuyButtonBehavior {
        case .LinkUSBankAccount:
            return usBankAccountFormElement?.canLinkAccount ?? false
        }
    }

    var bottomNoticeAttributedString: NSAttributedString? {
        if selectedPaymentMethodType == .stripe(.USBankAccount) {
            if let usBankPaymentMethodElement = paymentMethodFormElement as? USBankAccountPaymentMethodElement {
                return usBankPaymentMethodElement.mandateString
            }
        }
        return nil
    }

    private lazy var paymentMethodFormElement: PaymentMethodElement = {
        if selectedPaymentMethodType == .stripe(.USBankAccount),
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
        let view = DynamicHeightContainerView(pinnedDirection: .bottom)
        view.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        view.addPinnedSubview(paymentMethodDetailsView)
        view.updateHeight()
        return view
    }()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(
        configuration: CustomerSheet.Configuration,
        paymentMethodTypes: [PaymentSheet.PaymentMethodType],
        delegate: CustomerAddPaymentMethodViewControllerDelegate
    ) {
        self.configuration = configuration
        self.delegate = delegate
        self.paymentMethodTypes = paymentMethodTypes
        super.init(nibName: nil, bundle: nil)
        self.view.backgroundColor = configuration.appearance.colors.background
    }

    // MARK: - UIViewController
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        STPAnalyticsClient.sharedClient.logCSAddPaymentMethodScreenPresented()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

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
        if paymentMethodTypes == [.stripe(.card)] {
            paymentMethodTypesView.isHidden = true
        } else {
            paymentMethodTypesView.isHidden = false
        }
        updateUI()
    }

    func shouldPreventDismissal() -> Bool {
        guard let usBankAccountPaymentMethodElement = self.paymentMethodFormElement as? USBankAccountPaymentMethodElement else {
            return false
        }
        let customerHasLinkedBankAccount = usBankAccountPaymentMethodElement.getLinkedBank() != nil
        return customerHasLinkedBankAccount
    }

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
    private func updateFormElement() {
        if selectedPaymentMethodType == .stripe(.USBankAccount),
           let usBankAccountFormElement = usBankAccountFormElement {
            paymentMethodFormElement = usBankAccountFormElement
        } else {
            paymentMethodFormElement = makeElement(for: selectedPaymentMethodType)
        }
        updateUI()
        sendEventToSubviews(.viewDidAppear, from: view)
    }
    private func makeElement(for type: PaymentSheet.PaymentMethodType) -> PaymentMethodElement {
        let formElement = PaymentSheetFormFactory(
            configuration: .customerSheet(configuration),
            paymentMethod: type,
            previousCustomerInput: nil,
            addressSpecProvider: .shared,
            offerSaveToLinkWhenSupported: false,
            linkAccount: nil,
            supportsLinkCard: false,
            isPaymentIntent: false,
            currency: nil,
            amount: nil,
            countryCode: nil,
            saveMode: .merchantRequired)
            .make()
        formElement.delegate = self
        return formElement
    }
}

extension CustomerAddPaymentMethodViewController {
    func didTapCallToActionButton(behavior: OverrideableBuyButtonBehavior,
                                  clientSecret: String,
                                  from viewController: UIViewController) {
        switch behavior {
        case .LinkUSBankAccount:
            handleCollectBankAccount(from: viewController, clientSecret: clientSecret)
        }
    }
    func handleCollectBankAccount(from viewController: UIViewController, clientSecret: String) {
        guard
            let usBankAccountPaymentMethodElement = self.paymentMethodFormElement as? USBankAccountPaymentMethodElement,
            let name = usBankAccountPaymentMethodElement.name,
            let email = usBankAccountPaymentMethodElement.email
        else {
            assertionFailure()
            return
        }

        let params = STPCollectBankAccountParams.collectUSBankAccountParams(
            with: name,
            email: email
        )
        let client = STPBankAccountCollector()
        let errorText = STPLocalizedString(
            "Something went wrong when linking your account.\nPlease try again later.",
            "Error message when an error case happens when linking your account"
        )
        let genericError = PaymentSheetError.unknown(debugDescription: errorText)

        let financialConnectionsCompletion: (FinancialConnectionsSDKResult?, LinkAccountSession?, NSError?) -> Void = {
            result,
            _,
            error in
            if let error = error {
                let errorToUse = PaymentSheetError.unknown(debugDescription: error.nonGenericDescription)
                self.delegate?.updateErrorLabel(for: errorToUse)
                return
            }
            guard let financialConnectionsResult = result else {
                self.delegate?.updateErrorLabel(for: genericError)
                return
            }

            switch financialConnectionsResult {
            case .cancelled:
                break
            case .completed(let linkedBank):
                usBankAccountPaymentMethodElement.setLinkedBank(linkedBank)
            case .failed:
                self.delegate?.updateErrorLabel(for: genericError)
            }
        }

        client.collectBankAccountForSetup(
            clientSecret: clientSecret,
            returnURL: configuration.returnURL,
            onEvent: nil,
            params: params,
            from: viewController,
            financialConnectionsCompletion: financialConnectionsCompletion
        )
    }
}
extension CustomerAddPaymentMethodViewController: ElementDelegate {
    func continueToNextField(element: Element) {
        delegate?.didUpdate(self)
    }

    func didUpdate(element: Element) {
        delegate?.didUpdate(self)
        animateHeightChange()
    }
}

extension CustomerAddPaymentMethodViewController: PaymentMethodTypeCollectionViewDelegate {
    func didUpdateSelection(_ paymentMethodTypeCollectionView: PaymentMethodTypeCollectionView) {
        updateFormElement()
        delegate?.didUpdate(self)
    }
}

extension CustomerAddPaymentMethodViewController: PresentingViewControllerDelegate {
    func presentViewController(viewController: UIViewController, completion: (() -> Void)?) {
        self.present(viewController, animated: true, completion: completion)
    }
}
