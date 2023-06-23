//
//  PayWithLinkViewController-InstantDebitsOnly.swift
//  StripePaymentSheet
//
//  Created by Vardges Avetisyan on 6/8/23.
//

import Foundation
import PassKit
import SafariServices
import UIKit

@_spi(STP) import StripeApplePay
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
protocol InstantDebitsOnlyViewControllerDelegate: AnyObject {

    func instantDebitsOnlyViewControllerDidProducePaymentMethod(_ controller: InstantDebitsOnlyViewController, with paymentMethodId: String)

    func instantDebitsOnlyViewControllerDidCancel(_ controller: InstantDebitsOnlyViewController)

    func instantDebitsOnlyViewControllerDidFail(_ controller: InstantDebitsOnlyViewController, error: Error)

    func instantDebitsOnlyViewControllerDidComplete(_ controller: InstantDebitsOnlyViewController)
}

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
final class InstantDebitsOnlyViewController: UIViewController {

    lazy var navigationBar: SheetNavigationBar = {
        let navigationBar = SheetNavigationBar(isTestMode: configuration.apiClient.isTestmode,
                                               appearance: PaymentSheet.Appearance.default)
        navigationBar.delegate = self
        return navigationBar
    }()
    var requiresFullScreen: Bool

    weak var delegate: InstantDebitsOnlyViewControllerDelegate?
    private lazy var bankInfoView = LinkBankAccountInfoView(frame: .zero)
    private var paymentMethodId: String?

    private lazy var instantDebitMandateView = LinkInstantDebitMandateView(delegate: self)
    private lazy var connectionsAuthManager: InstantDebitsOnlyAuthenticationSessionManager = {
        return InstantDebitsOnlyAuthenticationSessionManager(window: view.window)
    }()

    private lazy var confirmButton = ConfirmButton.makeLinkButton(
        callToAction: .custom(title: String.Localized.continue),
        compact: false
    ) { [weak self] in
        guard let self = self else { return }
        self.delegate?.instantDebitsOnlyViewControllerDidComplete(self)
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

    private lazy var mandateContainerView: UIStackView = {
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
            bankInfoView,
            mandateContainerView,
            errorLabel,
            confirmButton,
        ])
        stackView.axis = .vertical
        stackView.spacing = LinkUI.contentSpacing
        stackView.setCustomSpacing(LinkUI.extraLargeContentSpacing, after: mandateContainerView)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = LinkUI.contentMargins
        return stackView
    }()

    private lazy var dynamicHeightContainer: DynamicHeightContainerView = {
        let view = DynamicHeightContainerView(pinnedDirection: .bottom)
        return view
    }()

    private let manifest: Manifest
    private let configuration: PaymentSheet.Configuration

    init(
        manifest: Manifest,
        configuration: PaymentSheet.Configuration
    ) {
        self.manifest = manifest
        self.requiresFullScreen = false
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
    }

    func setupUI() {
        containerView.addArrangedSubview(cancelButton)

        dynamicHeightContainer.addPinnedSubview(containerView)
        dynamicHeightContainer.updateHeight()

        view.addAndPinSubview(dynamicHeightContainer)
        containerView.alpha = 0.0

        containerView.toggleArrangedSubview(bankInfoView, shouldShow: false, animated: false)
    }

    func updateUI(animated: Bool) {
        mandateContainerView.toggleArrangedSubview(
            instantDebitMandateView,
            shouldShow: true,
            animated: animated
        )
    }

    func setBankAccountInfo(details: InstantDebitsOnlyAuthenticationSessionManager.RedactedPaymentDetails) {
        if details.bankIconCode == nil && details.bankName == nil && details.last4 == nil {
            return
        }
        bankInfoView.setBankAccountInfo(iconCode: details.bankIconCode, bankName: details.bankName, last4: details.last4)
        containerView.toggleArrangedSubview(bankInfoView, shouldShow: true, animated: false)
    }

    func updateErrorLabel(for error: Error?) {
        errorLabel.text = error?.nonGenericDescription
        containerView.toggleArrangedSubview(errorLabel, shouldShow: error != nil, animated: true)
    }

    @objc
    func cancelButtonTapped(_ sender: Button) {
        delegate?.instantDebitsOnlyViewControllerDidCancel(self)
    }

    func startInstantDebitsOnlyWebFlow() {
        paymentMethodId = nil
        confirmButton.update(state: .processing)
        connectionsAuthManager.start(manifest: manifest).observe { [weak self] result in
            guard let self = self else { return }
            self.containerView.alpha = 1.0
            switch result {
            case .success(let successResult):
                switch successResult {
                case .success(let details):
                    self.paymentMethodId = details.paymentMethodID
                    self.confirmButton.update(state: .enabled)
                    self.delegate?.instantDebitsOnlyViewControllerDidProducePaymentMethod(self, with: details.paymentMethodID)
                    self.setBankAccountInfo(details: details)
                case.canceled:
                    self.confirmButton.update(state: .disabled)
                    self.delegate?.instantDebitsOnlyViewControllerDidCancel(self)
                }
            case .failure(let error):
                self.confirmButton.update(state: .disabled)
                self.delegate?.instantDebitsOnlyViewControllerDidFail(self, error: error)
            }
        }
    }
}

// MARK: - BottomSheetContentViewController

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension InstantDebitsOnlyViewController: BottomSheetContentViewController {

    var isDismissable: Bool {
        return paymentMethodId == nil
    }

    var allowsDragToDismiss: Bool {
        return isDismissable
    }

    func didTapOrSwipeToDismiss() {
        if isDismissable {
            delegate?.instantDebitsOnlyViewControllerDidCancel(self)
        }
    }
}

// MARK: - SheetNavigationBarDelegate

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension InstantDebitsOnlyViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        delegate?.instantDebitsOnlyViewControllerDidCancel(self)
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        // no-op
    }
}

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
