//
//  STPCoreTableViewController.swift
//  Stripe
//
//  Created by Brian Dorfman on 1/6/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

/// This is the base class for all Stripe scroll view controllers. It is intended
/// for use only by Stripe classes, you should not subclass it yourself in your app.
/// It inherits from STPCoreScrollViewController and changes the type of the
/// created scroll view to UITableView, as well as other shared table view logic.
public class STPCoreTableViewController: STPCoreScrollViewController {
  /// This points to the same object as `STPCoreScrollViewController`'s `scrollView`
  /// property but with the type cast to `UITableView`

  @objc public var tableView: UITableView? {
    return (scrollView as? UITableView)
  }

  override func createScrollView() -> UIScrollView {
    let tableView = UITableView(frame: CGRect.zero, style: .grouped)
    tableView.sectionHeaderHeight = 30

    return tableView
  }

  /// :nodoc:
  @objc
  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    tableView?.reloadData()
  }

  @objc override func updateAppearance() {
    super.updateAppearance()
    tableView?.separatorStyle = .none  // handle this with fake separator views for flexibility
  }

  /// :nodoc:
  @objc
  public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int)
    -> CGFloat
  {
    return 0.01
  }
}
