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

    let onCompletion: ((PreConfirmationViewController, IntentConfirmParams?) -> Void)
    let onCancel: ((PreConfirmationViewController) -> Void)

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
    private lazy var paymentContainerView: DynamicHeightContainerView = {
        return DynamicHeightContainerView()
    }()
    private lazy var confirmButton: ConfirmButton = {
        let button = ConfirmButton(
            callToAction: .custom(title: confirmButtonCTA),
            appearance: configuration.appearance,
            didTap: { [weak self] in
                self?.didTapConfirmButton()
            }
        )
        return button
    }()
    private lazy var confirmButtonCTA: String = {
        return STPLocalizedString(
           "Confirm",
           "A button used to confirm the CVC/CVV"
       )
    }()

    private let cvcReconfirmationViewController: CVCReconfirmationViewController
    private let cardBrand: STPCardBrand

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(
        paymentMethod: STPPaymentMethod,
        intent: Intent,
        configuration: PaymentSheet.Configuration,
        onCompletion: @escaping ((PreConfirmationViewController, IntentConfirmParams?) -> Void),
        onCancel: @escaping((PreConfirmationViewController) -> Void)
    ) {
        self.paymentMethod = paymentMethod
        self.configuration = configuration
        self.onCompletion = onCompletion
        self.onCancel = onCancel
        let brand = paymentMethod.card?.brand ?? .unknown
        self.cardBrand = brand
        self.cvcReconfirmationViewController = CVCReconfirmationViewController(intent: intent,
                                                                               paymentMethod: paymentMethod,
                                                                               configuration: configuration)

        super.init(nibName: nil, bundle: nil)

        self.cvcReconfirmationViewController.delegate = self

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = configuration.appearance.colors.background
        // One stack view contains all our subviews
        let stackView = UIStackView(arrangedSubviews: [
            headerLabel,
            paymentContainerView,
            confirmButton,
        ])
        stackView.bringSubviewToFront(headerLabel)
        stackView.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.spacing = 10
        stackView.axis = .vertical
        stackView.setCustomSpacing(16, after: headerLabel)
        stackView.setCustomSpacing(32, after: paymentContainerView)
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
                equalTo: view.bottomAnchor, constant: -PaymentSheetUI.defaultSheetMargins.bottom - 15),
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

        let headerLabelText = self.cardBrand == .amex
        ? STPLocalizedString("Confirm your CVV",
                             "Title for prompting for a card's CVV on confirming the payment")
        : STPLocalizedString("Confirm your CVC",
                             "Title for prompting for a card's CVC on confirming the payment")
        self.headerLabel.text = headerLabelText

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
                             callToAction: .custom(title: confirmButtonCTA), animated: true)
    }

    // MARK: - Private Methods

    private func configureNavBar() {
        navigationBar.setStyle(.close(showAdditionalButton: false))
    }

    @objc
    private func didTapConfirmButton() {
        updateUI()
        // TODO: Analytics
        onCompletion(self, cvcReconfirmationViewController.paymentOptionIntentConfirmParams)
    }
}

extension PreConfirmationViewController: CVCReconfirmationViewControllerDelegate {
    func didUpdate(_ controller: CVCReconfirmationViewController) {
        updateUI()
    }

}
extension PreConfirmationViewController: BottomSheetContentViewController {
    var requiresFullScreen: Bool {
        return false
    }

    func didTapOrSwipeToDismiss() {
        // Users may be attempting to double tap "done", and may actually dismiss the sheet.
        // Therefore, do not dismiss sheet if customer taps the scrim
    }
    func didFinishAnimatingHeight() {
        // no-op
    }
}

extension PreConfirmationViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        onCancel(self)
    }
    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        // No-op
    }

}
