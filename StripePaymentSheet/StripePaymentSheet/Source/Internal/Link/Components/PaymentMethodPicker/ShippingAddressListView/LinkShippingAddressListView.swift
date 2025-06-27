//
//  LinkPaymentMethodListView.swift
//  StripePaymentSheet
//
//  Created by Chris Mays on 6/25/25.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

import UIKit

protocol LinkShippingAddressCellDelegate: AnyObject {
    func savedPaymentPickerCellDidSelect(_ cell: LinkShippingAddressListView.Cell)
    func savedPaymentPickerCell(_ cell: LinkShippingAddressListView.Cell, didTapMenuButton button: UIButton)
    func savedPaymentPickerCellMenuActions(
        for cell: LinkShippingAddressListView.Cell
    ) -> [PayWithLinkViewController.WalletViewController.Action]?
}

protocol LinkShippingAddressListDelegate: AnyObject {
    func didTapOnAddShippingAddress(
        sourceRect: CGRect
    )

    func didSelectShippingAddress(atIndex index: Int)

    func showMenuForShippingAddress(
        atIndex index: Int,
        sourceRect: CGRect
    )

    func menuActionForShippingAddress(
        atIndex index: Int
    ) -> [PayWithLinkViewController.WalletViewController.Action]

    func shippingAddressListDidExpand()
}

protocol LinkShippingAddressListDatasource: AnyObject {

    /// Returns the number of shipping addresses
    /// - Returns: Shipping address.
    func numberOfShippingAddresses() -> Int

    /// Returns the shipping address at the specific index.
    /// - Returns: Shipping address.
    func shippingAddress(atIndex index: Int) -> ShippingAddressesResponse.ShippingAddress

    var selectedShippingAddressIndex: Int { get }
}

class LinkShippingAddressListView: LinkCollapsingListView {
    private var needsDataReload: Bool = true

    private let addShippingAddressButton = LinkCollapsingListView.AddButton(text:  "Add shipping address")

    weak var dataSource: LinkShippingAddressListDatasource?

    weak var delegate: LinkShippingAddressListDelegate?

    var selectedIndex: Int {
        dataSource?.selectedShippingAddressIndex ?? 0
    }

    lazy var shippingAddressHeader: Header = Header()

    override var headerView: LinkCollapsingListView.Header {
        shippingAddressHeader
    }

    override var collapsable: Bool {
        return true
    }

    var selectedPaymentMethod: ShippingAddressesResponse.ShippingAddress? {
        let count = dataSource?.numberOfShippingAddresses() ?? 0

        guard selectedIndex >= 0 && selectedIndex < count else {
            return nil
        }

        return dataSource?.shippingAddress(atIndex: selectedIndex)
    }

    override func setup() {
        super.setup()
        listView.addArrangedSubview(addShippingAddressButton)
        addShippingAddressButton.tintColor = .linkTextBrand
        addShippingAddressButton.addTarget(self, action: #selector(addAddShippingAddressTapped(_:)), for: .touchUpInside)
    }

    override func didExpand() {
        delegate?.shippingAddressListDidExpand()
    }

    func reloadData() {
        needsDataReload = false

        addMissingShippingAddressCells()

        let count = dataSource?.numberOfShippingAddresses() ?? 0
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

        let shippingAddress = dataSource.shippingAddress(atIndex: index)

        cell.shippingAddress = shippingAddress
        cell.isSelected = selectedIndex == index
//        cell.isSupported = dataSource.isPaymentMethodSupported(paymentMethod)
    }

    func showLoaderForShippingAddress(at index: Int) {
        guard let cell = listView.arrangedSubviews[index] as? Cell else {
            stpAssertionFailure("Cell not found at index: \(index)")
            return
        }

        cell.isLoading = true
    }

    func hideLoaderForShippingAddress(at index: Int) {
        guard let cell = listView.arrangedSubviews[index] as? Cell else {
            stpAssertionFailure("Cell not found at index: \(index)")
            return
        }

        cell.isLoading = false
    }

    func setAddButtonIsLoading(_ isLoading: Bool) {
        addShippingAddressButton.isLoading = isLoading
    }

    func reloadDataIfNeeded() {
        if needsDataReload {
            reloadData()
        }
    }

    private func addMissingShippingAddressCells() {
        let count = dataSource?.numberOfShippingAddresses() ?? 0

        while count > listView.arrangedSubviews.count - 1 {
            let cell = Cell()
            cell.delegate = self

            let index = listView.arrangedSubviews.count - 1
            listView.insertArrangedSubview(cell, at: index)
        }

        for (index, subview) in listView.arrangedSubviews.enumerated() {
            subview.layer.zPosition = CGFloat(-index)
        }

        shippingAddressHeader.setSelectedShippingAddress(selectedPaymentMethod)
    }

    func index(for cell: Cell) -> Int? {
        return listView.arrangedSubviews.firstIndex(of: cell)
    }

    func remove(at index: Int, animated: Bool) {
        isUserInteractionEnabled = false

        listView.removeArrangedSubview(at: index, animated: true) {
            self.isUserInteractionEnabled = true
            self.reloadData()
        }
    }

    @objc func addAddShippingAddressTapped(_ sender: AddButton) {
        let sourceRect = sender.convert(sender.bounds, to: self)
        delegate?.didTapOnAddShippingAddress(sourceRect: sourceRect)
    }
}

extension LinkShippingAddressListView: LinkShippingAddressCellDelegate {

    func savedPaymentPickerCellDidSelect(_ savedCardView: Cell) {
        if let newIndex = index(for: savedCardView), savedCardView.isSupported {
#if !os(visionOS)
            selectionFeedbackGenerator.selectionChanged()
#endif

            delegate?.didSelectShippingAddress(atIndex: newIndex)
        }
    }

    func savedPaymentPickerCell(_ cell: Cell, didTapMenuButton button: UIButton) {
        guard let index = index(for: cell) else {
            stpAssertionFailure("Index not found")
            return
        }

        let sourceRect = button.convert(button.bounds, to: self)

        delegate?.showMenuForShippingAddress(atIndex: index, sourceRect: sourceRect)
    }

    func savedPaymentPickerCellMenuActions(for cell: Cell) -> [PayWithLinkViewController.WalletViewController.Action]? {
        guard let index = index(for: cell) else { return nil }
        return delegate?.menuActionForShippingAddress(atIndex: index)
    }
}
