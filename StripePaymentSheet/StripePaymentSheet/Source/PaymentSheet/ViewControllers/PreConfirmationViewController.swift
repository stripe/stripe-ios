//
//  PreConfirmationViewController.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

/// For internal SDK use only
class PreConfirmationViewController: UIViewController {

    let onCompletion: ((IntentConfirmParams?) -> Void)
    let onDismiss: ((PreConfirmationViewController) -> Void)

    let configuration: PaymentSheet.Configuration
    let paymentMethod: STPPaymentMethod
    lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(isTestMode: configuration.apiClient.isTestmode,
                                        appearance: configuration.appearance)
        navBar.delegate = self
        return navBar
    }()

    private lazy var headerLabel: UILabel = {
        return PaymentSheetUI.makeHeaderLabel(appearance: configuration.appearance)
    }()

    private lazy var selectedCardInformationView: UIView = {
        return PaymentMethodInformationView(paymentMethod: paymentMethod, appearance: configuration.appearance)
    }()

    private lazy var paymentContainerView: DynamicHeightContainerView = {
        return DynamicHeightContainerView()
    }()

    private lazy var confirmButton: ConfirmButton = {
        let button = ConfirmButton(
            callToAction: .customWithLock(title: String.Localized.continue),
            appearance: configuration.appearance,
            didTap: { [weak self] in
                self?.didTapAddButton()
            }
        )
        return button
    }()

    private let cvcReconfirmationViewController: CVCReconfirmationViewController


    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(
        paymentMethod: STPPaymentMethod,
        intent: Intent,
        configuration: PaymentSheet.Configuration,
        onCompletion: @escaping ((IntentConfirmParams?) -> Void),
        onDismiss: @escaping((PreConfirmationViewController) -> Void)
    ) {
        self.paymentMethod = paymentMethod
        self.configuration = configuration
        self.onCompletion = onCompletion
        self.onDismiss = onDismiss
        let brand = paymentMethod.card?.brand ?? .unknown
        self.cvcReconfirmationViewController = CVCReconfirmationViewController(brand: brand,
                                                                               intent: intent,
                                                                               configuration: configuration)

        super.init(nibName: nil, bundle: nil)

        self.cvcReconfirmationViewController.delegate = self

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // One stack view contains all our subviews
        let stackView = UIStackView(arrangedSubviews: [
            headerLabel,
            selectedCardInformationView,
            paymentContainerView,
            confirmButton,
        ])
        stackView.bringSubviewToFront(headerLabel)
        stackView.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.spacing = 10
        stackView.axis = .vertical
        [stackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        // Get our margins in order
        view.directionalLayoutMargins = PaymentSheetUI.defaultSheetMargins
        // Hack: Payment container needs to extend to the edges, so we'll 'cancel out' the layout margins with negative padding
        paymentContainerView.directionalLayoutMargins = .insets(
            leading: -PaymentSheetUI.defaultSheetMargins.leading,
            trailing: -PaymentSheetUI.defaultSheetMargins.trailing
        )

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor, constant: -PaymentSheetUI.defaultSheetMargins.bottom),
        ])

        updateUI()
    }

    private func updateUI() {

        configureNavBar()

        let targetViewController = cvcReconfirmationViewController
        switchContentIfNecessary(
            to: targetViewController,
            containerView: paymentContainerView
        )

        updateButton()
        headerLabel.text = STPLocalizedString("For security, please re-enter your card's security code",
                                              "Title for prompting for a card's CVC/CVC on confirming the payment")

    }
    func updateButton() {
        if confirmButton.isHidden {
            confirmButton.alpha = 0
            confirmButton.setHiddenIfNecessary(false)
            UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
                self.confirmButton.alpha = 1
                self.view.layoutIfNeeded()
            }
        }
        let confirmationButtonEnabled = cvcReconfirmationViewController.paymentOptionIntentConfirmParams != nil

        confirmButton.update(state: confirmationButtonEnabled ? .enabled : .disabled,
                             callToAction: .customWithLock(title: String.Localized.continue), animated: true)
    }

    // MARK: - Private Methods

    private func configureNavBar() {
        navigationBar.setStyle(.close(showAdditionalButton: false))
    }

    @objc
    private func didTapAddButton() {
        //TODO Analytics
        onCompletion(cvcReconfirmationViewController.paymentOptionIntentConfirmParams)
        didDismiss()
    }

    private func didDismiss() {
        onDismiss(self)
    }
}

extension PreConfirmationViewController: CVCReconfirmationViewControllerDelegate {
    func didUpdate(_ controller: CVCReconfirmationViewController) {
//        error = nil -- if we have errors.
        updateUI()
    }

}
extension PreConfirmationViewController: BottomSheetContentViewController {
    var requiresFullScreen: Bool {
        return false
    }

    func didTapOrSwipeToDismiss() {
        didDismiss()
    }

}

extension PreConfirmationViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        didDismiss()
    }
    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        //todo
    }

}
