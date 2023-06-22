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

//
//  Button+Link.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 12/1/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

extension Button.Configuration {

    static func linkPrimary() -> Self {
        var configuration: Button.Configuration = .primary()
        configuration.font = LinkUI.font(forTextStyle: .bodyEmphasized)
        configuration.insets = LinkUI.buttonMargins
        configuration.cornerRadius = LinkUI.cornerRadius

        // Colors
        configuration.foregroundColor = .linkPrimaryButtonForeground
        configuration.backgroundColor = .linkBrand
        configuration.disabledBackgroundColor = .linkBrand

        configuration.colorTransforms.disabledForeground = .setAlpha(amount: 0.5)
        configuration.colorTransforms.highlightedForeground = .darken(amount: 0.2)

        return configuration
    }

    static func linkSecondary() -> Self {
        var configuration: Button.Configuration = .linkPrimary()

        // Colors
        configuration.foregroundColor = .linkSecondaryButtonForeground
        configuration.backgroundColor = .linkSecondaryButtonBackground
        configuration.disabledBackgroundColor = .linkSecondaryButtonBackground

        return configuration
    }

    static func linkPlain() -> Self {
        var configuration: Button.Configuration = .plain()
        configuration.font = LinkUI.font(forTextStyle: .body)
        configuration.foregroundColor = .linkBrandDark
        configuration.disabledForegroundColor = nil
        configuration.colorTransforms.highlightedForeground = .setAlpha(amount: 0.4)
        configuration.colorTransforms.disabledForeground = .setAlpha(amount: 0.3)
        return configuration
    }

    static func linkBordered() -> Self {
        var configuration: Button.Configuration = .plain()
        configuration.font = LinkUI.font(forTextStyle: .detailEmphasized)
        configuration.insets = .insets(top: 4, leading: 12, bottom: 4, trailing: 12)
        configuration.borderWidth = 1
        configuration.cornerRadius = LinkUI.mediumCornerRadius

        // Colors
        configuration.foregroundColor = .label
        configuration.backgroundColor = .clear
        configuration.borderColor = .linkControlBorder

        configuration.colorTransforms.highlightedForeground = .setAlpha(amount: 0.5)
        configuration.colorTransforms.highlightedBorder = .setAlpha(amount: 0.5)

        return configuration
    }

}

//
//  LinkKeyboardAvoidingScrollView.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 1/11/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

/// A UIScrollView subclass that actively prevents its content from being covered by the software keyboard.
/// For internal SDK use only
@objc(STP_Internal_LinkKeyboardAvoidingScrollView)
final class LinkKeyboardAvoidingScrollView: UIScrollView {

    init() {
        super.init(frame: .zero)

        NotificationCenter.default.addObserver(self,
            selector: #selector(keyboardFrameChanged(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil)
    }

    /// Creates a new keyboard-avoiding scrollview with the given view configured as content view.
    ///
    /// This initializer adds the content view as a subview and installs the appropriate set of constraints.
    ///
    /// - Parameter contentView: The view to be used as content view.
    convenience init(contentView: UIView) {
        self.init()

        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: widthAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Event Handling
private extension LinkKeyboardAvoidingScrollView {

    @objc func keyboardFrameChanged(_ notification: Notification) {
        let userInfo = notification.userInfo

        guard let keyboardFrame = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }

        let absoluteFrame = convert(bounds, to: window)
        let intersection = absoluteFrame.intersection(keyboardFrame)

        UIView.animateAlongsideKeyboard(notification) {
            self.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: intersection.height, right: 0)
            self.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: intersection.height, right: 0)
        }
    }

}

struct Manifest: Decodable {
    let hostedAuthURL: URL
    let successURL: URL
    let cancelURL: URL

    enum CodingKeys: String, CodingKey {
        case hostedAuthURL = "hosted_auth_url"
        case successURL = "success_url"
        case cancelURL = "cancel_url"
    }
}

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
protocol InstantDebitsOnlyViewControllerDelegate: AnyObject {

    func instantDebitsOnlyViewControllerDidProducePaymentMethod(_ controller: InstantDebitsOnlyViewController, with paymentMethodId: String)

    func instantDebitsOnlyViewControllerDidCancel(_ controller: InstantDebitsOnlyViewController)

    func instantDebitsOnlyViewControllerDidFail(_ controller: InstantDebitsOnlyViewController, error: Error)

    func instantDebitsOnlyViewControllerDidComplete(
        _ controller: InstantDebitsOnlyViewController
    )
}

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
final class InstantDebitsOnlyViewController: UIViewController, BottomSheetContentViewController, SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        delegate?.instantDebitsOnlyViewControllerDidCancel(self)
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {}

    lazy var navigationBar: SheetNavigationBar = {
        let navigationBar = SheetNavigationBar(isTestMode: configuration.apiClient.isTestmode,
                                               appearance: PaymentSheet.Appearance.default)
        navigationBar.delegate = self
        return navigationBar
    }()
    var requiresFullScreen: Bool

    func didTapOrSwipeToDismiss() {
        let alertController = UIAlertController(
            title: title,
            message: "Are you sure you'd like to cancel?",
            preferredStyle: .alert
        )
        alertController.addAction(
            UIAlertAction(
                title: "Go back",
                style: .default
            )
        )
        alertController.addAction(
            UIAlertAction(
                title: "Yes",
                style: .destructive
            ) { _ in
                self.delegate?.instantDebitsOnlyViewControllerDidCancel(self)
            }
        )
        present(alertController, animated: true)
    }

    weak var delegate: InstantDebitsOnlyViewControllerDelegate?
    private lazy var instantDebitMandateView = LinkInstantDebitMandateView(delegate: self)
    private lazy var connectionsAuthManager: InstantDebitsOnlyAuthenticationSessionManager = {
        return InstantDebitsOnlyAuthenticationSessionManager(window: view.window)
    }()
    private lazy var confirmButton = ConfirmButton.makeLinkButton(
        callToAction: .custom(title: "Authorize"),
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

    private let feedbackGenerator = UINotificationFeedbackGenerator()
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

        let scrollView = LinkKeyboardAvoidingScrollView(contentView: containerView)
        scrollView.keyboardDismissMode = .interactive

        view.addAndPinSubview(scrollView)
        view.heightAnchor.constraint(equalToConstant: 244).isActive = true
        containerView.alpha = 0.0
    }

    func updateUI(animated: Bool) {
        mandateContainerView.toggleArrangedSubview(
            instantDebitMandateView,
            shouldShow: true,
            animated: animated
        )
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
        confirmButton.update(state: .processing)
        connectionsAuthManager.start(manifest: manifest).observe { [weak self] result in
            guard let self = self else { return }
            self.containerView.alpha = 1.0
            switch result {
            case .success(let successResult):
                switch successResult {
                case .success(let paymentMethodID):
                    self.confirmButton.update(state: .enabled)
                    self.delegate?.instantDebitsOnlyViewControllerDidProducePaymentMethod(self, with: paymentMethodID)
                case.canceled:
                    self.confirmButton.update(state: .disabled)
                    self.delegate?.instantDebitsOnlyViewControllerDidCancel(self)
                }
            case .failure(let error):
                self.confirmButton.update(state: .disabled)
                print(error.localizedDescription)
                self.delegate?.instantDebitsOnlyViewControllerDidFail(self, error: error)
            }
        }
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
