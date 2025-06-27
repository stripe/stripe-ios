//
//  LinkPaymentMethodListView.swift
//  StripePaymentSheet
//
//  Created by Chris Mays on 6/25/25.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

import UIKit

protocol LinkPaymentMethodListDataSource: AnyObject {

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

protocol LinkPaymentMethodListDelegate: AnyObject {
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

    func paymentListDidExpand()
}

class LinkPaymentMethodListView: LinkCollapsingListView {
    private var needsDataReload: Bool = true

    private let addPaymentMethodButton = LinkCollapsingListView.AddButton(text:  String.Localized.add_a_payment_method)

    weak var dataSource: LinkPaymentMethodListDataSource?

    weak var delegate: LinkPaymentMethodListDelegate?

    var selectedIndex: Int {
        dataSource?.selectedIndex ?? 0
    }

    lazy var paymentMethodHeader: Header = Header()

    override var headerView: LinkCollapsingListView.Header {
        paymentMethodHeader
    }

    override var collapsable: Bool {
        guard let dataSource else { return false }
        return selectedPaymentMethod.map { dataSource.isPaymentMethodSupported($0) } ?? false
    }

    var selectedPaymentMethod: ConsumerPaymentDetails? {
        let count = dataSource?.numberOfPaymentMethods() ?? 0

        guard selectedIndex >= 0 && selectedIndex < count else {
            return nil
        }

        return dataSource?.paymentPicker(paymentMethodAt: selectedIndex)
    }

    override func setup() {
        super.setup()
        listView.addArrangedSubview(addPaymentMethodButton)
        addPaymentMethodButton.tintColor = .linkTextBrand
        addPaymentMethodButton.addTarget(self, action: #selector(onAddPaymentButtonTapped(_:)), for: .touchUpInside)
    }

    override func didExpand() {
        delegate?.paymentListDidExpand()
    }

    func reloadData() {
        needsDataReload = false

        addMissingPaymentMethodCells()

        let count = dataSource?.numberOfPaymentMethods() ?? 0
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

        let paymentMethod = dataSource.paymentPicker(paymentMethodAt: index)

        cell.paymentMethod = paymentMethod
        cell.isSelected = selectedIndex == index
        cell.isSupported = dataSource.isPaymentMethodSupported(paymentMethod)
    }

    func showLoaderForPaymentMethod(at index: Int) {
        guard let cell = listView.arrangedSubviews[index] as? Cell else {
            stpAssertionFailure("Cell not found at index: \(index)")
            return
        }

        cell.isLoading = true
    }

    func hideLoaderForPaymentMethod(at index: Int) {
        guard let cell = listView.arrangedSubviews[index] as? Cell else {
            stpAssertionFailure("Cell not found at index: \(index)")
            return
        }

        cell.isLoading = false
    }

    func setAddButtonIsLoading(_ isLoading: Bool) {
        addPaymentMethodButton.isLoading = isLoading
    }

    func reloadDataIfNeeded() {
        if needsDataReload {
            reloadData()
        }
    }

    private func addMissingPaymentMethodCells() {
        let count = dataSource?.numberOfPaymentMethods() ?? 0

        while count > listView.arrangedSubviews.count - 1 {
            let cell = Cell()
            cell.delegate = self

            let index = listView.arrangedSubviews.count - 1
            listView.insertArrangedSubview(cell, at: index)
        }

        for (index, subview) in listView.arrangedSubviews.enumerated() {
            subview.layer.zPosition = CGFloat(-index)
        }

        paymentMethodHeader.setSelectedPaymentMethod(selectedPaymentMethod: selectedPaymentMethod, supported: dataSource?.isPaymentMethodSupported(selectedPaymentMethod) ?? false)
    }

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

    @objc func onAddPaymentButtonTapped(_ sender: AddButton) {
        let sourceRect = sender.convert(sender.bounds, to: self)
        delegate?.paymentDetailsPickerDidTapOnAddPayment(sourceRect: sourceRect)
    }
}

extension LinkPaymentMethodListView: LinkPaymentMethodPickerCellDelegate {

    func savedPaymentPickerCellDidSelect(_ savedCardView: Cell) {
        if let newIndex = index(for: savedCardView), savedCardView.isSupported {
#if !os(visionOS)
            selectionFeedbackGenerator.selectionChanged()
#endif

            delegate?.paymentMethodPicker(didSelectIndex: newIndex)
        }
    }

    func savedPaymentPickerCell(_ cell: Cell, didTapMenuButton button: UIButton) {
        guard let index = index(for: cell) else {
            stpAssertionFailure("Index not found")
            return
        }

        let sourceRect = button.convert(button.bounds, to: self)

        delegate?.paymentMethodPicker(showMenuForItemAt: index, sourceRect: sourceRect)
    }

    func savedPaymentPickerCellMenuActions(for cell: Cell) -> [PayWithLinkViewController.WalletViewController.Action]? {
        guard let index = index(for: cell) else { return nil }
        return delegate?.paymentMethodPicker(menuActionsForItemAt: index)
    }
}
