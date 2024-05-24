//
//  VerticalPaymentMethodListViewController.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 5/20/24.
//

@_spi(STP) import StripeUICore
import UIKit

protocol VerticalPaymentMethodListViewControllerDelegate: AnyObject {
    /// - Returns: Whether or not the payment method row button should appear selected.
    func didTapPaymentMethod(_ selection: VerticalPaymentMethodListSelection) -> Bool
    // TODO: didSelectEdit/ViewMore
}

/// A simple container VC for the VerticalPaymentMethodListView, which displays payment options in a vertical list.
class VerticalPaymentMethodListViewController: UIViewController {
    weak var delegate: VerticalPaymentMethodListViewControllerDelegate?
    let listView: VerticalPaymentMethodListView
    /// Returns the number of row buttons in the vertical list
    var rowCount: Int {
        return listView.rowButtons.count
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(savedPaymentMethod: STPPaymentMethod?, paymentMethodTypes: [PaymentSheet.PaymentMethodType], shouldShowApplePay: Bool, shouldShowLink: Bool, appearance: PaymentSheet.Appearance, delegate: VerticalPaymentMethodListViewControllerDelegate) {
        self.delegate = delegate
        self.listView = VerticalPaymentMethodListView(
            savedPaymentMethod: savedPaymentMethod,
            paymentMethodTypes: paymentMethodTypes,
            shouldShowApplePay: shouldShowApplePay,
            shouldShowLink: shouldShowLink,
            appearance: appearance
        )
        super.init(nibName: nil, bundle: nil)
        self.listView.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view = listView
    }
}

extension VerticalPaymentMethodListViewController: VerticalPaymentMethodListViewDelegate {
    func didTapPaymentMethod(_ selection: VerticalPaymentMethodListSelection) -> Bool {
        return delegate?.didTapPaymentMethod(selection) ?? false
    }
}
