//
//  PayWithLinkViewController-InstantDebitsOnly.swift
//  StripePaymentSheet
//
//  Created by Vardges Avetisyan on 6/8/23.
//

import PassKit
import SafariServices
import UIKit
import Foundation

@_spi(STP) import StripeApplePay
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
final class InstantDebitsOnlyViewController: UIViewController, BottomSheetContentViewController, STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return self
    }

    lazy var navigationBar: SheetNavigationBar = {
        let navigationBar = SheetNavigationBar(isTestMode: false,
                                               appearance: PaymentSheet.Appearance.default)
//        navigationBar.delegate = self
        return navigationBar
    }()
    var requiresFullScreen: Bool

    func didTapOrSwipeToDismiss() {

    }


    private lazy var instantDebitMandateView = LinkInstantDebitMandateView(delegate: self)
    private lazy var connectionsAuthManager: InstantDebitsOnlyAuthenticationSessionManager = {
        return InstantDebitsOnlyAuthenticationSessionManager(window: view.window)
    }()
    private lazy var confirmButton = ConfirmButton.makeLinkButton(
        callToAction: .custom(title: "Confirm?"),
        compact: false
    ) { [weak self] in
        self?.confirmIntent()
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
    private let clientSecret: String
    private let hostedURL: URL
    private let configuration: PaymentSheet.Configuration

    init(
        apiClient: STPAPIClient,
        clientSecret: String,
        hostedURL: URL,
        configuration: PaymentSheet.Configuration
    ) {
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.hostedURL = hostedURL
        self.requiresFullScreen = true
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateUI(animated: false)
//        let content = UIView()
//        content.translatesAutoresizingMaskIntoConstraints = false
//        content.backgroundColor = .green
//        view.addSubview(content)
//        NSLayoutConstraint.activate([
//            content.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
//            content.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
//            content.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
//            content.heightAnchor.constraint(equalToConstant: 300),
//            view.heightAnchor.constraint(equalToConstant: 400),
//
//        ])
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
        view.heightAnchor.constraint(equalToConstant: 400).isActive = true
        containerView.alpha = 0.0
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


    func confirmIntent() {

//        let params = STPPaymentIntentParams(clientSecret: self.clientSecret, paymentMethodType: .link)
//        let paymentMethodParams = STPPaymentMethodParams(type: .link)
//        paymentMethodParams.link?.paymentDetailsID = self.paymentDetailsId
//
//        apiClient.createPaymentMethod(with: paymentMethodParams) { paymentMethod, error in
//            if let error = error {
//                print(error.localizedDescription)
//                return
//            }
//
//            guard let paymentMethod = paymentMethod else {
//                print("NIL PAYMENT METHOD")
//                return
//            }
//
//
//
//
//        }

        let paymentIntentParams = STPPaymentIntentParams(clientSecret: self.clientSecret, paymentMethodType: .link)

//        DO A RAW CONFIRM API CALL NO PARAMS FANCY JUST RAW /v1/paymentIntents/ID/confirm and see what happens.

//        paymentIntentParams.paymentMethodParams = paymentMethodParams
        paymentIntentParams.paymentMethodId = self.paymentMethodID
        paymentIntentParams.mandateData = STPMandateDataParams.makeWithInferredValues()
        paymentIntentParams.
        self.apiClient.confirmPaymentIntent(with: paymentIntentParams, expand: nil) { intent, error in
            if let error = error {
                print(error as Any)
                return
            }

            guard let intent = intent else {
                return
            }

            print(intent.nextAction as Any)
        }

        



        // TO(vav): figure this out
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
        self.presentingViewController?.dismiss(animated: true)
    }

    private var paymentMethodID: String?

    private func startInstantDebitsOnlyWebFlow() {
//        confirmButton.update(state: .processing)
//            pickerView.setAddPaymentMethodButtonEnabled(false)
//        let urlString = "https://vardges-bankcon-auth-srv.tunnel.stripe.me/instant-debits-only#apiKey=\(apiClient.publishableKey!)&clientSecret=\(clientSecret)&customer=cus123&businessName=Startup+Co&unifiedInstantDebitsFlow=true&returnUrl=stripe-auth://redirect"
        print(self.clientSecret)
        connectionsAuthManager.start(hostedURL: self.hostedURL, configuredReturnedURL: URL(string: "stripe-auth://redirect")!).observe { result in
            self.containerView.alpha = 1.0
            switch result {
            case .success(let successResult):
                switch successResult {
                case .success(let paymentMethodID):
                    self.paymentMethodID = paymentMethodID

                case.canceled:
                    self.presentingViewController?.dismiss(animated: true)
                }
            case .failure(_):
                print("asd")
            }
        }
//        Task {
//            do {
//                let paymentDetails = try await connectionsAuthManager.start(clientSecret: "_FIX_SHOULD_BE_INTENT_CLIENT_SECRET_linkAccountSession.clientSecret")
//                await MainActor.run {
//                    print(paymentDetails)
//                }
//            } catch {
//                await MainActor.run {
//                    switch error {
//                    case LinkFinancialConnectionsAuthManager.Error.canceled:
//                        break
//                    default:
//                        self.updateErrorLabel(for: error)
//                    }
//                }
//            }
//            self.updateUI(animated: false)
//        }
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

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension InstantDebitsOnlyViewController: LinkInstantDebitMandateViewDelegate {

    func instantDebitMandateView(_ mandateView: LinkInstantDebitMandateView, didTapOnLinkWithURL url: URL) {
        let safariVC = SFSafariViewController(url: url)
        safariVC.dismissButtonStyle = .close
        safariVC.modalPresentationStyle = .overFullScreen
        present(safariVC, animated: true)
    }

}
