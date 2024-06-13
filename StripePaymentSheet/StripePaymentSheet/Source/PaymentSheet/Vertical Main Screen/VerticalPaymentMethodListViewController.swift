//
//  VerticalPaymentMethodListViewController.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 5/20/24.
//

@_spi(STP) import StripeUICore
import UIKit

/// A simple container VC for the VerticalPaymentMethodListView, which displays payment options in a vertical list.
class VerticalPaymentMethodListViewController: UIViewController {
    private let listView: VerticalPaymentMethodListView
    /// Returns the number of row buttons in the vertical list
    var rowCount: Int {
        return listView.rowButtons.count
    }
    var currentSelection: VerticalPaymentMethodListSelection? {
        return listView.currentSelection
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(initialSelection: VerticalPaymentMethodListSelection?, savedPaymentMethod: STPPaymentMethod?, paymentMethodTypes: [PaymentSheet.PaymentMethodType], shouldShowApplePay: Bool, shouldShowLink: Bool, savedPaymentMethodAccessoryType: RowButton.RightAccessoryButton.AccessoryType?, overrideHeaderView: UIView?, appearance: PaymentSheet.Appearance, currency: String?, amount: Int?, delegate: VerticalPaymentMethodListViewDelegate) {
        self.listView = VerticalPaymentMethodListView(
            initialSelection: initialSelection,
            savedPaymentMethod: savedPaymentMethod,
            paymentMethodTypes: paymentMethodTypes,
            shouldShowApplePay: shouldShowApplePay,
            shouldShowLink: shouldShowLink,
            savedPaymentMethodAccessoryType: savedPaymentMethodAccessoryType,
            overrideHeaderView: overrideHeaderView,
            appearance: appearance,
            currency: currency,
            amount: amount
        )
        super.init(nibName: nil, bundle: nil)
        self.listView.delegate = delegate
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view = listView
    }
}
