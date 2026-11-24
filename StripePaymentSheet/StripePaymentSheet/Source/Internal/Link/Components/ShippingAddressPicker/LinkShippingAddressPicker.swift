//
//  LinkShippingAddressPicker.swift
//  StripePaymentSheet
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripeUICore

protocol LinkShippingAddressPickerDelegate: AnyObject {

    func shippingAddressPicker(_ picker: LinkShippingAddressPicker, didSelectIndex index: Int)

    func shippingAddressPicker(
        _ picker: LinkShippingAddressPicker,
        menuActionsForItemAt index: Int
    ) -> [PayWithLinkViewController.WalletViewController.Action]

    func shippingAddressPicker(
        _ picker: LinkShippingAddressPicker,
        showMenuForItemAt index: Int,
        sourceRect: CGRect
    )

    func shippingAddressPickerDidTapOnAddShippingAddress(_ picker: LinkShippingAddressPicker)
}

protocol LinkShippingAddressPickerDataSource: AnyObject {

    func numberOfShippingAddresses(in picker: LinkShippingAddressPicker) -> Int

    func shippingAddress(at index: Int) -> ShippingAddressesResponse.ShippingAddress

    /// Whether the shipping address can be used, e.g. because the merchant ships to its country.
    func isShippingAddressSupported(at index: Int) -> Bool

    /// The index of the selected shipping address, or `nil` if none is selected.
    var selectedShippingAddressIndex: Int? { get }
}

/// An accordion listing the shipping addresses saved to the Link account.
/// Embedded in `LinkPaymentMethodPicker`, which provides the surrounding card.
/// For internal SDK use only
@objc(STP_Internal_LinkShippingAddressPicker)
final class LinkShippingAddressPicker: UIView {
    weak var delegate: LinkShippingAddressPickerDelegate?
    weak var dataSource: LinkShippingAddressPickerDataSource?

    var linkAppearance: LinkAppearance? {
        didSet {
            updateTintColors()
        }
    }

    var selectedShippingAddress: ShippingAddressesResponse.ShippingAddress? {
        guard let dataSource, let selectedIndex = dataSource.selectedShippingAddressIndex,
              selectedIndex >= 0 && selectedIndex < dataSource.numberOfShippingAddresses(in: self) else {
            return nil
        }
        return dataSource.shippingAddress(at: selectedIndex)
    }

    /// The picker can only collapse once a shipping address is selected.
    var collapsable: Bool {
        selectedShippingAddress != nil
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
            addShippingAddressButton
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

    private let addShippingAddressButton = LinkPaymentMethodPicker.AddButton(
        title: STPLocalizedString(
            "Add shipping address",
            "Title for a button that when tapped lets the user add a new shipping address."
        )
    )

    init() {
        super.init(frame: .zero)
        addAndPinSubview(stackView)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        clipsToBounds = true
        accessibilityIdentifier = "Stripe.Link.ShippingAddressPicker"
        updateTintColors()

        headerView.addTarget(self, action: #selector(onHeaderTapped(_:)), for: .touchUpInside)
        headerView.layer.zPosition = 1

        listView.isHidden = true
        listView.layer.zPosition = 0

        addShippingAddressButton.addTarget(self, action: #selector(onAddShippingAddressButtonTapped), for: .touchUpInside)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        reloadDataIfNeeded()
    }

    func setExpanded(_ expanded: Bool, animated: Bool) {
        headerView.isExpanded = collapsable ? expanded : true

        // Prevent double header animation
        if headerView.isExpanded {
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
        tintColor = linkAppearancePrimaryColor ?? .linkAccent
        addShippingAddressButton.tintColor = linkAppearancePrimaryColor ?? .linkTextPrimary
    }
}

private extension LinkShippingAddressPicker {

    @objc func onHeaderTapped(_ sender: Header) {
        guard collapsable || !sender.isExpanded else { return }
        setExpanded(!sender.isExpanded, animated: true)
#if !os(visionOS)
        impactFeedbackGenerator.impactOccurred()
#endif
    }

    @objc func onAddShippingAddressButtonTapped() {
        delegate?.shippingAddressPickerDidTapOnAddShippingAddress(self)
    }

}

// MARK: - Data Loading

extension LinkShippingAddressPicker {

    func reloadData() {
        needsDataReload = false

        addMissingCells()

        let count = dataSource?.numberOfShippingAddresses(in: self) ?? 0
        headerView.isHidden = count == 0
        if !collapsable {
            // Without a selection, there's nothing to show in the collapsed state.
            headerView.isExpanded = true
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

        guard let dataSource else {
            stpAssertionFailure("Data source not configured.")
            return
        }

        cell.shippingAddress = dataSource.shippingAddress(at: index)
        cell.isSelected = dataSource.selectedShippingAddressIndex == index
        cell.isSupported = dataSource.isShippingAddressSupported(at: index)
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

    func removeShippingAddress(at index: Int, animated: Bool) {
        isUserInteractionEnabled = false

        listView.removeArrangedSubview(at: index, animated: animated) {
            self.isUserInteractionEnabled = true
            self.reloadData()
        }
    }

    private func reloadDataIfNeeded() {
        if needsDataReload {
            reloadData()
        }
    }

    private func addMissingCells() {
        let count = dataSource?.numberOfShippingAddresses(in: self) ?? 0

        while count > listView.arrangedSubviews.count - 1 {
            let cell = Cell()
            cell.delegate = self

            let index = listView.arrangedSubviews.count - 1
            listView.insertArrangedSubview(cell, at: index)
        }

        for (index, subview) in listView.arrangedSubviews.enumerated() {
            subview.layer.zPosition = CGFloat(-index)
        }

        headerView.setSelectedShippingAddress(selectedShippingAddress)
    }

    private func index(for cell: Cell) -> Int? {
        return listView.arrangedSubviews.firstIndex(of: cell)
    }
}

// MARK: - Cell delegate

extension LinkShippingAddressPicker: LinkShippingAddressPickerCellDelegate {

    func shippingAddressPickerCellDidSelect(_ cell: Cell) {
        guard let index = index(for: cell) else {
            stpAssertionFailure("Index not found")
            return
        }
        guard cell.isSupported else {
            return
        }

#if !os(visionOS)
        selectionFeedbackGenerator.selectionChanged()
#endif
        delegate?.shippingAddressPicker(self, didSelectIndex: index)
    }

    func shippingAddressPickerCell(_ cell: Cell, didTapMenuButton button: UIButton) {
        guard let index = index(for: cell) else {
            stpAssertionFailure("Index not found")
            return
        }

        let sourceRect = button.convert(button.bounds, to: self)
        delegate?.shippingAddressPicker(self, showMenuForItemAt: index, sourceRect: sourceRect)
    }

    func shippingAddressPickerCellMenuActions(for cell: Cell) -> [PayWithLinkViewController.WalletViewController.Action]? {
        guard let index = index(for: cell) else { return nil }
        return delegate?.shippingAddressPicker(self, menuActionsForItemAt: index)
    }
}
