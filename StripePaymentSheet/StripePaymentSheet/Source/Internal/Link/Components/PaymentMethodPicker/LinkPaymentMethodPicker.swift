//
//  LinkPaymentMethodPicker.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 10/25/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

protocol LinkPaymentMethodPickerDelegate: AnyObject {

    func paymentMethodPicker(didSelectIndex index: Int)

    func paymentMethodPicker(
        menuActionsForItemAt index: Int
    ) -> [PayWithLinkViewController.WalletViewController.Action]

    func paymentMethodPicker(
        showMenuForItemAt index: Int,
        sourceRect: CGRect
    )

    func paymentDetailsPickerDidTapOnAddPayment(
        sourceRect: CGRect
    )

    func didTapOnAccountMenuItem(
        _ picker: LinkPaymentMethodPicker,
        sourceRect: CGRect
    )
}

protocol LinkPaymentMethodPickerDataSource: AnyObject {
    var accountEmail: String { get }

    /// Returns the total number of payment methods.
    /// - Returns: Payment method count
    func numberOfPaymentMethods() -> Int

    /// Returns the payment method at the specific index.
    /// - Returns: Payment method.
    func paymentPicker(
        paymentMethodAt index: Int
    ) -> ConsumerPaymentDetails

    func isPaymentMethodSupported(_ paymentMethod: ConsumerPaymentDetails?) -> Bool

    var selectedIndex: Int { get }
}

/// For internal SDK use only
@objc(STP_Internal_LinkPaymentMethodPicker)
final class LinkPaymentMethodPicker: UIView {
    weak var delegate: LinkPaymentMethodPickerDelegate? {
        didSet {
            paymentMethodListView.delegate = delegate
        }
    }
    weak var dataSource: LinkPaymentMethodPickerDataSource? {
        didSet {
            emailView.accountEmail = dataSource?.accountEmail
            paymentMethodListView.dataSource = dataSource
        }
    }

    var supportedPaymentMethodTypes = Set(ConsumerPaymentDetails.DetailsType.allCases)

    var billingDetailsCollectionConfiguration: PaymentSheet.BillingDetailsCollectionConfiguration? {
        didSet {
            reloadPaymentMethods()
        }
    }

    func setExpanded(_ expanded: Bool, animated: Bool) {
        paymentMethodListView.setExpanded(expanded, animated: animated)
    }

    var billingDetails: PaymentSheet.BillingDetails? {
        didSet {
            reloadPaymentMethods()
        }
    }

    /// Calculates the maximum width required for the header labels.
    static let widthForHeaderLabels: CGFloat = {
        let font = LinkUI.font(forTextStyle: .bodyEmphasized)
        func sizeOf(string: String) -> CGSize {
            (string as NSString).size(withAttributes: [.font: font])
        }

        // LinkPaymentMethodPicker.EmailView.emailLabel
        let emailLabel = String.Localized.email
        let emailLabelSize = sizeOf(string: emailLabel)

        // LinkPaymentMethodPicker.Header.payWithLabel
        let paymentLabel = LinkPaymentMethodListView.Header.Strings.payment
        let paymentLabelSize = sizeOf(string: paymentLabel)

        return max(emailLabelSize.width, paymentLabelSize.width)
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            emailView,
            separatorView,
            paymentMethodListView,
        ])

        stackView.axis = .vertical
        stackView.clipsToBounds = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let emailView = EmailView()
    private let separatorView = LinkSeparatorView()

    private lazy var paymentMethodListView = LinkPaymentMethodListView()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addAndPinSubview(stackView)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        clipsToBounds = true
        accessibilityIdentifier = "Stripe.Link.PaymentMethodPicker"

        layer.cornerRadius = 16
        layer.borderColor = UIColor.linkBorderDefault.cgColor
        tintColor = .linkIconBrand
        backgroundColor = .linkSurfaceSecondary

        paymentMethodListView.layer.zPosition = 0

        emailView.menuButton.addTarget(self, action: #selector(didTapOnAccountMenuItem), for: .touchUpInside)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        paymentMethodListView.reloadDataIfNeeded()
    }

#if !os(visionOS)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        layer.borderColor = UIColor.linkBorderDefault.cgColor
    }
#endif

}

private extension LinkPaymentMethodPicker {
    @objc func didTapOnAccountMenuItem(_ sender: UIView) {
        let sourceRect = sender.convert(sender.bounds, to: self)
        delegate?.didTapOnAccountMenuItem(self, sourceRect: sourceRect)
    }

}

// MARK: - Data Loading

extension LinkPaymentMethodPicker {

    func reloadPaymentMethods() {
        paymentMethodListView.reloadData()
    }

    func showLoaderForPaymentMethod(at index: Int) {
        paymentMethodListView.showLoaderForPaymentMethod(at: index)
    }

    func hideLoaderForPaymentMethod(at index: Int) {
        paymentMethodListView.hideLoaderForPaymentMethod(at: index)
    }

    func setAddButtonIsLoading(_ isLoading: Bool) {
        paymentMethodListView.setAddButtonIsLoading(isLoading)
    }
}

extension ConsumerPaymentDetails {

    /// Returns whether the `ConsumerPaymentDetails` contains all the billing details fields requested by the provided `billingDetailsConfig`.
    /// We use the `consumerSession` to populate any missing fields from the Link account.
    func supports(
        _ billingDetailsConfig: PaymentSheet.BillingDetailsCollectionConfiguration,
        in consumerSession: ConsumerSession?
    ) -> Bool {
        if billingDetailsConfig.name == .always && billingAddress?.name == nil {
            // No name available, so that needs to be collected
            return false
        }

        if billingDetailsConfig.address == .full && (billingAddress == nil || billingAddress?.isIncomplete == true) {
            // No or incomplete address available, so that needs to be collected
            return false
        }

        if billingDetailsConfig.phone == .always && consumerSession?.unredactedPhoneNumber == nil {
            // No phone number available in the account, so that needs to be collected
            return false
        }

        // We don't need to check email, because we're guaranteed to have the account email

        return true
    }

    /// Creates a new `ConsumerPaymentDetails` with any missing fields populated by the provided `billingDetails`. The required fields
    /// are determined by the provided `billingDetailsConfig`.
    func update(
        with billingDetails: PaymentSheet.BillingDetails,
        basedOn billingDetailsConfig: PaymentSheet.BillingDetailsCollectionConfiguration
    ) -> ConsumerPaymentDetails {
        var billingEmailAddress = self.billingEmailAddress
        var billingAddress = self.billingAddress

        if billingDetailsConfig.address == .full && (billingAddress == nil || billingAddress?.isIncomplete == true) {
            // No address available, so we add any default provided by the merchant if it's compatible
            if billingAddress?.canBeOverridden(with: billingDetails.address) == true {
                billingAddress = BillingAddress(from: billingDetails)
            }
        }

        if billingDetailsConfig.name == .always && billingAddress?.name == nil {
            // No name available, so we add any default provided by the merchant
            billingAddress = billingAddress?.withName(billingDetails.name) ?? BillingAddress(name: billingDetails.name)
        }

        if billingDetailsConfig.email == .always && billingEmailAddress == nil {
            // No email available, so we add any default provided by the merchant
            billingEmailAddress = billingDetails.email
        }

        return .init(
            stripeID: stripeID,
            details: details,
            billingAddress: billingAddress,
            billingEmailAddress: billingEmailAddress,
            nickname: nickname,
            isDefault: isDefault
        )
    }
}

private extension BillingAddress {
    var isIncomplete: Bool {
        return line1 == nil || city == nil || postalCode == nil || countryCode == nil
    }

    init(from billingDetails: PaymentSheet.BillingDetails) {
        self.init(
            line1: billingDetails.address.line1,
            line2: billingDetails.address.line2,
            city: billingDetails.address.city,
            state: billingDetails.address.state,
            postalCode: billingDetails.address.postalCode,
            countryCode: billingDetails.address.country
        )
    }

    func canBeOverridden(with address: PaymentSheet.Address) -> Bool {
        return postalCode == address.postalCode && countryCode == address.country
    }

    func update(with billingDetails: PaymentSheet.BillingDetails) -> BillingAddress {
        return .init(
            line1: line1 ?? billingDetails.address.line1,
            line2: line2 ?? billingDetails.address.line2,
            city: city ?? billingDetails.address.city,
            state: state ?? billingDetails.address.state,
            postalCode: postalCode ?? billingDetails.address.postalCode,
            countryCode: countryCode ?? billingDetails.address.country
        )
    }

    func withName(_ name: String?) -> BillingAddress {
        return .init(
            name: name,
            line1: line1,
            line2: line2,
            city: city,
            state: state,
            postalCode: postalCode,
            countryCode: countryCode
        )
    }
}

private extension PaymentSheet.Address {
    var isIncomplete: Bool {
        return line1 == nil || city == nil || postalCode == nil || country == nil
    }
}

extension LinkPaymentMethodPicker {
    func removePaymentMethod(at index: Int, animated: Bool) {
        paymentMethodListView.removePaymentMethod(at: index, animated: animated)
    }
}
