//
//  PayWithLinkViewController-InstantDebitsOnly.swift
//  StripePaymentSheet
//
//  Created by Vardges Avetisyan on 6/8/23.
//

import PassKit
import SafariServices
import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

final class InstantDebitsOnlyViewController: UIViewController {


    private lazy var instantDebitMandateView = LinkInstantDebitMandateView(delegate: self)
    private lazy var connectionsAuthManager: LinkFinancialConnectionsAuthManager = {
        return LinkFinancialConnectionsAuthManager(apiClient: apiClient, window: view.window)
    }()
    private lazy var confirmButton = ConfirmButton.makeLinkButton(
        callToAction: .custom(title: "Confirm?"),
        compact: false
    ) { [weak self] in
        self?.confirm()
    }

    private lazy var cancelButton: Button = {
        let button = Button(
            configuration: .linkSecondary(),
            title: String.Localized.cancel
        )
        button.addTarget(self, action: #selector(cancelButtonTapped(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var separator = SeparatorLabel(text: String.Localized.or)


    private lazy var paymentPickerContainerView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            instantDebitMandateView,
        ])
        stackView.axis = .vertical
        stackView.spacing = LinkUI.contentSpacing
        return stackView
    }()

    private lazy var errorLabel: UILabel = {
        let label = ElementsUI.makeErrorLabel(theme: LinkUI.appearance.asElementsTheme)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private lazy var containerView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            paymentPickerContainerView,
            errorLabel,
            confirmButton,
        ])
        stackView.axis = .vertical
        stackView.spacing = LinkUI.contentSpacing
        stackView.setCustomSpacing(LinkUI.extraLargeContentSpacing, after: paymentPickerContainerView)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = LinkUI.contentMargins
        return stackView
    }()

    private let feedbackGenerator = UINotificationFeedbackGenerator()
    private let apiClient: STPAPIClient

    init(
        apiClient: STPAPIClient
    ) {
        self.apiClient = apiClient
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateUI(animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        startInstantDebitsOnlyWebFlow()
    }

    func setupUI() {
        containerView.addArrangedSubview(cancelButton)

        let scrollView = LinkKeyboardAvoidingScrollView(contentView: containerView)
        scrollView.keyboardDismissMode = .interactive

        view.addAndPinSubview(scrollView)
    }

    func updateUI(animated: Bool) {

        paymentPickerContainerView.toggleArrangedSubview(
            instantDebitMandateView,
            shouldShow: true,
            animated: animated
        )

        // TODO(vav): state should be dynamic
        confirmButton.update(
            state: .enabled,
            callToAction: .custom(title: "Confirm?")
        )
    }

    func updateErrorLabel(for error: Error?) {
        errorLabel.text = error?.nonGenericDescription
        containerView.toggleArrangedSubview(errorLabel, shouldShow: error != nil, animated: true)
    }

    func confirm() {
        // TODO(vav): figure this out
        //            guard let paymentDetails = viewModel.selectedPaymentMethod else {
        //                assertionFailure("`confirm()` called without a selected payment method")
        //                return
        //            }
        //
        //            let confirmWithPaymentDetails: (ConsumerPaymentDetails) -> Void = { [self] paymentDetails in
        //                confirm(for: context.intent, with: paymentDetails)
        //            }
        //
        //            confirmWithPaymentDetails(paymentDetails)
    }

    func confirm(for intent: Intent, with paymentDetails: ConsumerPaymentDetails) {
        // TODO(vav): figure this out
        //            view.endEditing(true)
        //
        //            feedbackGenerator.prepare()
        //            updateErrorLabel(for: nil)
        //            confirmButton.update(state: .processing)
        //
        //            coordinator?.confirm(with: linkAccount, paymentDetails: paymentDetails) { [weak self] result in
        //                switch result {
        //                case .completed:
        //                    self?.feedbackGenerator.notificationOccurred(.success)
        //                    self?.confirmButton.update(state: .succeeded, animated: true) {
        //                        self?.coordinator?.finish(withResult: result)
        //                    }
        //                case .canceled:
        //                    self?.confirmButton.update(state: .enabled)
        //                case .failed(let error):
        //                    self?.feedbackGenerator.notificationOccurred(.error)
        //                    self?.updateErrorLabel(for: error)
        //                    self?.confirmButton.update(state: .enabled)
        //                }
        //            }
    }

    @objc
    func cancelButtonTapped(_ sender: Button) {
//            coordinator?.cancel()
    }


    private func startInstantDebitsOnlyWebFlow() {
        confirmButton.update(state: .processing)
//            pickerView.setAddPaymentMethodButtonEnabled(false)

        Task {
            do {
                let paymentDetails = try await connectionsAuthManager.start(clientSecret: "_FIX_SHOULD_BE_INTENT_CLIENT_SECRET_linkAccountSession.clientSecret")
                await MainActor.run {
                    print(paymentDetails)
                }
            } catch {
                await MainActor.run {
                    switch error {
                    case LinkFinancialConnectionsAuthManager.Error.canceled:
                        break
                    default:
                        self.updateErrorLabel(for: error)
                    }
                }
            }
            self.updateUI(animated: false)
        }
    }

}

// MARK: - PayWithLinkWalletViewModelDelegate

//extension PayWithLinkViewController.WalletViewController: PayWithLinkWalletViewModelDelegate {
//
//    func viewModelDidChange(_ viewModel: PayWithLinkViewController.WalletViewModel) {
//        updateUI(animated: true)
//    }
//}

// MARK: - LinkInstantDebitMandateViewDelegate

extension InstantDebitsOnlyViewController: LinkInstantDebitMandateViewDelegate {

func instantDebitMandateView(_ mandateView: LinkInstantDebitMandateView, didTapOnLinkWithURL url: URL) {
    let safariVC = SFSafariViewController(url: url)
    safariVC.dismissButtonStyle = .close
    safariVC.modalPresentationStyle = .overFullScreen
    present(safariVC, animated: true)
}

}
