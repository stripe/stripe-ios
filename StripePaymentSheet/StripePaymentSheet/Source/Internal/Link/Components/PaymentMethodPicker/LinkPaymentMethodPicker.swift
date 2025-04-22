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
    func paymentMethodPickerDidChange(_ picker: LinkPaymentMethodPicker)

    func paymentMethodPicker(
        _ picker: LinkPaymentMethodPicker,
        showMenuForItemAt index: Int,
        sourceRect: CGRect
    )

    func paymentDetailsPickerDidTapOnAddPayment(_ picker: LinkPaymentMethodPicker)
}

protocol LinkPaymentMethodPickerDataSource: AnyObject {

    /// Returns the total number of payment methods.
    /// - Returns: Payment method count
    func numberOfPaymentMethods(in picker: LinkPaymentMethodPicker) -> Int

    /// Returns the payment method at the specific index.
    /// - Returns: Payment method.
    func paymentPicker(
        _ picker: LinkPaymentMethodPicker,
        paymentMethodAt index: Int
    ) -> ConsumerPaymentDetails

}

/// For internal SDK use only
@objc(STP_Internal_LinkPaymentMethodPicker)
final class LinkPaymentMethodPicker: UIView {
    weak var delegate: LinkPaymentMethodPickerDelegate?
    weak var dataSource: LinkPaymentMethodPickerDataSource?

    var selectedIndex: Int = 0 {
        didSet {
            updateHeaderView()
        }
    }

    var supportedPaymentMethodTypes = Set(ConsumerPaymentDetails.DetailsType.allCases) {
        didSet {
            // TODO(tillh-stripe) Update this as soon as adding bank accounts is supported
            addPaymentMethodButton.isHidden = !supportedPaymentMethodTypes.contains(.card)
        }
    }

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

    private var needsDataReload: Bool = true

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            headerView,
            listView,
        ])

        stackView.axis = .vertical
        stackView.clipsToBounds = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let headerView = Header()

    private lazy var listView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            addPaymentMethodButton
        ])

        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.clipsToBounds = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    #if !os(visionOS)
    private let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
    #endif

    private let addPaymentMethodButton = AddButton()

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
        layer.borderWidth = 1
        layer.borderColor = UIColor.linkControlBorder.cgColor
        tintColor = .linkBrand
        backgroundColor = .linkControlBackground

        addPaymentMethodButton.tintColor = .linkBrand500

        headerView.addTarget(self, action: #selector(onHeaderTapped(_:)), for: .touchUpInside)
        headerView.layer.zPosition = 1

        listView.isHidden = true
        listView.layer.zPosition = 0

        addPaymentMethodButton.addTarget(self, action: #selector(onAddPaymentButtonTapped(_:)), for: .touchUpInside)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        reloadDataIfNeeded()
    }

#if !os(visionOS)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        layer.borderColor = UIColor.linkControlBorder.cgColor
    }
#endif

    func setExpanded(_ expanded: Bool, animated: Bool) {
        headerView.isExpanded = expanded

        // Prevent double header animation
        if headerView.isExpanded {
            // TODO(link): revise layout margin placement and remove conditional
            setNeedsLayout()
            layoutIfNeeded()
        } else {
            headerView.layoutIfNeeded()
        }

        if headerView.isExpanded {
            stackView.showArrangedSubview(at: 1, animated: animated)
        } else {
            stackView.hideArrangedSubview(at: 1, animated: animated)
        }
    }

    private func updateHeaderView() {
        headerView.selectedPaymentMethod = selectedPaymentMethod
    }

}

private extension LinkPaymentMethodPicker {

    @objc func onHeaderTapped(_ sender: Header) {
        setExpanded(!sender.isExpanded, animated: true)
#if !os(visionOS)
        impactFeedbackGenerator.impactOccurred()
#endif
    }

    @objc func onAddPaymentButtonTapped(_ sender: AddButton) {
        delegate?.paymentDetailsPickerDidTapOnAddPayment(self)
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
        cell.isSupported = supportedPaymentMethodTypes.contains(paymentMethod.type)
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

    func setAddPaymentMethodButtonEnabled(_ enabled: Bool) {
        addPaymentMethodButton.isEnabled = enabled
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

        headerView.selectedPaymentMethod = selectedPaymentMethod
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
            let count = self.dataSource?.numberOfPaymentMethods(in: self) ?? 0

            if index < self.selectedIndex {
                self.selectedIndex = max(self.selectedIndex - 1, 0)
            }

            self.selectedIndex = max(min(self.selectedIndex, count - 1), 0)

            self.reloadData()
            self.delegate?.paymentMethodPickerDidChange(self)
            self.isUserInteractionEnabled = true
        }
    }

}

// MARK: - Cell delegate

extension LinkPaymentMethodPicker: LinkPaymentMethodPickerCellDelegate {

    func savedPaymentPickerCellDidSelect(_ savedCardView: Cell) {
        if let newIndex = index(for: savedCardView) {
            let oldIndex = selectedIndex
            selectedIndex = newIndex

            reloadCell(at: oldIndex)
            reloadCell(at: newIndex)

#if !os(visionOS)
            selectionFeedbackGenerator.selectionChanged()
#endif

            delegate?.paymentMethodPickerDidChange(self)
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

}
