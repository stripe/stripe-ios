//
//  UITableView+Extensions.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 12/2/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

extension UITableView {
    /**
    Sets `tableHeaderView` of the table view by first changing the header frame size to system compressed size.

     This prevents various layout issues where we try to set a header before we have a size setup on table view.
     */
    func setTableHeaderViewWithCompressedFrameSize(_ header: UIView) {
        header.frame.size = header.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        self.tableHeaderView = header
    }

    /**
    Sets `tableFooterView` of the table view by first changing the footer frame size to system compressed size.

     This prevents various layout issues where we try to set a footer before we have a size setup on table view.
     */
    func setTableFooterViewWithCompressedFrameSize(_ footer: UIView) {
        footer.frame.size = footer.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        self.tableFooterView = footer
    }
}
