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
//protocol PreConfirmationViewControllerDelegate: AnyObject {
//    func preConfirmationViewControllerShouldClose(_ preConfirmationViewController: PreConfirmationViewController)
//}

/// For internal SDK use only
//@objc(STP_Internal_PaymentSheetFlowControllerViewController)
class PreConfirmationViewController: UIViewController {

    let completion: ((IntentConfirmParams?) -> Void)
    let onDismiss: ((PreConfirmationViewController) -> Void)

    let configuration: PaymentSheet.Configuration
    lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(isTestMode: configuration.apiClient.isTestmode,
                                        appearance: configuration.appearance)
        navBar.delegate = self
        return navBar
    }()
//    weak var delegate: PreConfirmationViewControllerDelegate?


    private lazy var paymentContainerView: DynamicHeightContainerView = {
        return DynamicHeightContainerView()
    }()
    private lazy var headerLabel: UILabel = {
        return PaymentSheetUI.makeHeaderLabel(appearance: configuration.appearance)
    }()

    private let cvcReconfirmationViewController: CVCReconfirmationViewController

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
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(
        intent: Intent,
        configuration: PaymentSheet.Configuration,
        completion: @escaping ((IntentConfirmParams?) -> Void),
        onDismiss: @escaping((PreConfirmationViewController) -> Void)
    ) {
        self.configuration = configuration
        self.completion = completion
        self.onDismiss = onDismiss
        self.cvcReconfirmationViewController = CVCReconfirmationViewController(intent: intent,
                                                                               configuration: configuration)

        super.init(nibName: nil, bundle: nil)

        self.cvcReconfirmationViewController.delegate = self

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // One stack view contains all our subviews
        let stackView = UIStackView(arrangedSubviews: [
            headerLabel,
            paymentContainerView,
//            errorLabel,
            confirmButton,
//            bottomNoticeTextField,
        ])
        stackView.bringSubviewToFront(headerLabel)
        stackView.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.spacing = PaymentSheetUI.defaultPadding
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
        let targetViewController = cvcReconfirmationViewController
        switchContentIfNecessary(
            to: targetViewController,
            containerView: paymentContainerView
        )

        updateButton()

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


    @objc
    private func didTapAddButton() {
        //TODO Analytics
        completion(cvcReconfirmationViewController.paymentOptionIntentConfirmParams)
        didDismiss()
    }

    func didDismiss() {
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
//        if isDismissable {
//            didDismiss()
//        }
    }

}

extension PreConfirmationViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        //todo
    }
    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        //todo
    }

}
