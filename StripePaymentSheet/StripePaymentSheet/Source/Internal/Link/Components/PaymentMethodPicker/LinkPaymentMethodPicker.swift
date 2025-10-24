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

    func paymentMethodPicker(_ picker: LinkPaymentMethodPicker, didSelectIndex index: Int)

    func paymentMethodPicker(
        _ picker: LinkPaymentMethodPicker,
        menuActionsForItemAt index: Int
    ) -> [PayWithLinkViewController.WalletViewController.Action]

    func paymentMethodPicker(
        _ picker: LinkPaymentMethodPicker,
        showMenuForItemAt index: Int,
        sourceRect: CGRect
    )

    func paymentDetailsPickerDidTapOnAddPayment(
        _ picker: LinkPaymentMethodPicker,
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
    func numberOfPaymentMethods(in picker: LinkPaymentMethodPicker) -> Int

    /// Returns the payment method at the specific index.
    /// - Returns: Payment method.
    func paymentPicker(
        _ picker: LinkPaymentMethodPicker,
        paymentMethodAt index: Int
    ) -> ConsumerPaymentDetails

    func isPaymentMethodSupported(_ paymentMethod: ConsumerPaymentDetails?) -> Bool

    var selectedIndex: Int { get }
}

/// For internal SDK use only
@objc(STP_Internal_LinkPaymentMethodPicker)
final class LinkPaymentMethodPicker: UIView {
    weak var delegate: LinkPaymentMethodPickerDelegate?
    weak var dataSource: LinkPaymentMethodPickerDataSource? {
        didSet {
            emailView.accountEmail = dataSource?.accountEmail
        }
    }

    var selectedIndex: Int {
        dataSource?.selectedIndex ?? 0
    }

    var collapsable: Bool {
        guard let dataSource else { return false }
        return selectedPaymentMethod.map { dataSource.isPaymentMethodSupported($0) } ?? false
    }

    var supportedPaymentMethodTypes = Set(ConsumerPaymentDetails.DetailsType.allCases)

    var selectedPaymentMethod: ConsumerPaymentDetails? {
        let count = dataSource?.numberOfPaymentMethods(in: self) ?? 0

        guard selectedIndex >= 0 && selectedIndex < count else {
            return nil
        }

        return dataSource?.paymentPicker(self, paymentMethodAt: selectedIndex)
    }

    var billingDetailsCollectionConfiguration: PaymentSheet.BillingDetailsCollectionConfiguration? {
        didSet {
            reloadData()
        }
    }

    var billingDetails: PaymentSheet.BillingDetails? {
        didSet {
            reloadData()
        }
    }

    var linkAppearance: LinkAppearance? {
        didSet {
            updateTintColors()
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
        let paymentLabel = Header.Strings.payment
        let paymentLabelSize = sizeOf(string: paymentLabel)

        return max(emailLabelSize.width, paymentLabelSize.width)
    }()

    private var needsDataReload: Bool = true

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            emailView,
            separatorView,
            headerView,
            listView,
        ])

        stackView.axis = .vertical
        stackView.clipsToBounds = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let emailView: EmailView
    private let separatorView = LinkSeparatorView()
    private let headerView = Header()

    private lazy var listView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            addPaymentMethodButton
        ])

        stackView.axis = .vertical
        stackView.clipsToBounds = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    #if !os(visionOS)
    private let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
    #endif

    private let addPaymentMethodButton = AddButton()

    init(linkConfiguration: LinkConfiguration? = nil) {
        self.emailView = EmailView(linkConfiguration: linkConfiguration)
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

        if let cornerRadius = LinkUI.appearance.cornerRadius {
            layer.cornerRadius = cornerRadius
        } else {
            ios26_applyDefaultCornerConfiguration()
        }

        layer.borderColor = UIColor.linkBorderDefault.cgColor
        updateTintColors()
        backgroundColor = .linkSurfaceSecondary

        headerView.addTarget(self, action: #selector(onHeaderTapped(_:)), for: .touchUpInside)
        headerView.layer.zPosition = 1

        listView.isHidden = true
        listView.layer.zPosition = 0

        addPaymentMethodButton.addTarget(self, action: #selector(onAddPaymentButtonTapped(_:)), for: .touchUpInside)
        emailView.menuButton.addTarget(self, action: #selector(didTapOnAccountMenuItem), for: .touchUpInside)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        reloadDataIfNeeded()
    }

#if !os(visionOS)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        layer.borderColor = UIColor.linkBorderDefault.cgColor
    }
#endif

    func setExpanded(_ expanded: Bool, animated: Bool) {
        headerView.isExpanded = collapsable ? expanded : true

        // Prevent double header animation
        if headerView.isExpanded {
            // TODO(link): revise layout margin placement and remove conditional
            setNeedsLayout()
            layoutIfNeeded()
        } else {
            headerView.layoutIfNeeded()
        }

        guard let listViewIndex = stackView.arrangedSubviews.firstIndex(of: listView) else { return }
        if headerView.isExpanded {
            stackView.showArrangedSubview(at: listViewIndex, animated: animated)
        } else {
            stackView.hideArrangedSubview(at: listViewIndex, animated: animated)
        }
    }

    private func updateTintColors() {
        let linkAppearancePrimaryColor = linkAppearance?.colors?.primary
        tintColor = linkAppearancePrimaryColor ?? .linkIconBrand
        addPaymentMethodButton.tintColor = linkAppearancePrimaryColor ?? .linkTextBrand
    }
}

private extension LinkPaymentMethodPicker {

    @objc func onHeaderTapped(_ sender: Header) {
        guard collapsable || !sender.isExpanded else { return }
        setExpanded(!sender.isExpanded, animated: true)
#if !os(visionOS)
        impactFeedbackGenerator.impactOccurred()
#endif
    }

    @objc func onAddPaymentButtonTapped(_ sender: AddButton) {
        let sourceRect = sender.convert(sender.bounds, to: self)
        delegate?.paymentDetailsPickerDidTapOnAddPayment(self, sourceRect: sourceRect)
    }

    @objc func didTapOnAccountMenuItem(_ sender: UIButton) {
        let sourceRect = sender.convert(sender.bounds, to: self)
        delegate?.didTapOnAccountMenuItem(self, sourceRect: sourceRect)
    }

}

// MARK: - Data Loading

extension LinkPaymentMethodPicker {

    func reloadData() {
        needsDataReload = false

        addMissingPaymentMethodCells()

        let count = dataSource?.numberOfPaymentMethods(in: self) ?? 0
        if count == 0 {
            headerView.isHidden = true
            listView.isHidden = false
        }

        for index in 0..<count {
            reloadCell(at: index)
        }
    }

    func reloadCell(at index: Int) {
        guard let cell = listView.arrangedSubviews[index] as? Cell else {
            stpAssertionFailure("Cell not found at index: \(index)")
            return
        }

        guard let dataSource = dataSource else {
            stpAssertionFailure("Data source not configured.")
            return
        }

        let paymentMethod = dataSource.paymentPicker(self, paymentMethodAt: index)

        cell.paymentMethod = paymentMethod
        cell.isSelected = selectedIndex == index
        cell.isSupported = dataSource.isPaymentMethodSupported(paymentMethod)
    }

    func showLoader(at index: Int) {
        guard let cell = listView.arrangedSubviews[index] as? Cell else {
            stpAssertionFailure("Cell not found at index: \(index)")
            return
        }

        cell.isLoading = true
    }

    func hideLoader(at index: Int) {
        guard let cell = listView.arrangedSubviews[index] as? Cell else {
            stpAssertionFailure("Cell not found at index: \(index)")
            return
        }

        cell.isLoading = false
    }

    func setAddButtonIsLoading(_ isLoading: Bool) {
        addPaymentMethodButton.isLoading = isLoading
    }

    private func reloadDataIfNeeded() {
        if needsDataReload {
            reloadData()
        }
    }

    private func addMissingPaymentMethodCells() {
        let count = dataSource?.numberOfPaymentMethods(in: self) ?? 0

        while count > listView.arrangedSubviews.count - 1 {
            let cell = Cell()
            cell.delegate = self

            let index = listView.arrangedSubviews.count - 1
            listView.insertArrangedSubview(cell, at: index)
        }

        for (index, subview) in listView.arrangedSubviews.enumerated() {
            subview.layer.zPosition = CGFloat(-index)
        }

        headerView.setSelectedPaymentMethod(selectedPaymentMethod: selectedPaymentMethod, supported: dataSource?.isPaymentMethodSupported(selectedPaymentMethod) ?? false)
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

    func index(for cell: Cell) -> Int? {
        return listView.arrangedSubviews.firstIndex(of: cell)
    }

    func removePaymentMethod(at index: Int, animated: Bool) {
        isUserInteractionEnabled = false

        listView.removeArrangedSubview(at: index, animated: true) {
            self.isUserInteractionEnabled = true
            self.reloadData()
        }
    }

}

// MARK: - Cell delegate

extension LinkPaymentMethodPicker: LinkPaymentMethodPickerCellDelegate {

    func savedPaymentPickerCellDidSelect(_ savedCardView: Cell) {
        if let newIndex = index(for: savedCardView), savedCardView.isSupported {
#if !os(visionOS)
            selectionFeedbackGenerator.selectionChanged()
#endif

            delegate?.paymentMethodPicker(self, didSelectIndex: newIndex)
        }
    }

    func savedPaymentPickerCell(_ cell: Cell, didTapMenuButton button: UIButton) {
        guard let index = index(for: cell) else {
            stpAssertionFailure("Index not found")
            return
        }

        let sourceRect = button.convert(button.bounds, to: self)

        delegate?.paymentMethodPicker(self, showMenuForItemAt: index, sourceRect: sourceRect)
    }

    func savedPaymentPickerCellMenuActions(for cell: Cell) -> [PayWithLinkViewController.WalletViewController.Action]? {
        guard let index = index(for: cell) else { return nil }
        return delegate?.paymentMethodPicker(self, menuActionsForItemAt: index)
    }
}
