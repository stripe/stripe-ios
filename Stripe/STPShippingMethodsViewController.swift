//
//  STPShippingMethodsViewController.swift
//  Stripe
//
//  Created by Ben Guo on 8/29/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import PassKit
import UIKit

class STPShippingMethodsViewController: STPCoreTableViewController, UITableViewDataSource,
  UITableViewDelegate
{
  init(
    shippingMethods methods: [PKShippingMethod],
    selectedShippingMethod selectedMethod: PKShippingMethod,
    currency: String,
    theme: STPTheme
  ) {
    super.init(theme: theme)
    shippingMethods = methods
    if (methods.firstIndex(of: selectedMethod) ?? NSNotFound) != NSNotFound {
      selectedShippingMethod = selectedMethod
    } else {
      selectedShippingMethod = methods.stp_boundSafeObject(at: 0) as? PKShippingMethod
    }

    self.currency = currency
    title = STPLocalizedString("Shipping", "Title for shipping info form")
  }

  weak var delegate: STPShippingMethodsViewControllerDelegate?
  private var shippingMethods: [PKShippingMethod]?
  private var selectedShippingMethod: PKShippingMethod?
  private var currency: String?
  private weak var imageView: UIImageView?
  private var doneItem: UIBarButtonItem?
  private var headerView: STPSectionHeaderView?

  override func createAndSetupViews() {
    super.createAndSetupViews()

    tableView?.register(
      STPShippingMethodTableViewCell.self,
      forCellReuseIdentifier: STPShippingMethodCellReuseIdentifier)

    let doneItem = UIBarButtonItem(
      barButtonSystemItem: .done, target: self, action: #selector(done(_:)))
    self.doneItem = doneItem
    stp_navigationItemProxy?.rightBarButtonItem = doneItem
    stp_navigationItemProxy?.rightBarButtonItem?.accessibilityIdentifier =
      "ShippingMethodsViewControllerDoneButtonIdentifier"

    let imageView = UIImageView(image: STPImageLibrary.largeShippingImage())
    imageView.contentMode = .center
    imageView.frame = CGRect(
      x: 0, y: 0, width: view.bounds.size.width, height: imageView.bounds.size.height + (57 * 2))
    self.imageView = imageView

    tableView?.tableHeaderView = imageView
    tableView?.dataSource = self
    tableView?.delegate = self
    tableView?.reloadData()

    let headerView = STPSectionHeaderView()
    headerView.theme = theme
    headerView.buttonHidden = true
    headerView.title = STPLocalizedString("Shipping Method", "Label for shipping method form")
    headerView.setNeedsLayout()
    self.headerView = headerView
  }

  @objc override func updateAppearance() {
    super.updateAppearance()

    let navBarTheme = navigationController?.navigationBar.stp_theme ?? theme
    doneItem?.stp_setTheme(navBarTheme)

    imageView?.tintColor = theme.accentColor
    for cell in tableView?.visibleCells ?? [] {
      let shippingCell = cell as? STPShippingMethodTableViewCell
      shippingCell?.theme = theme
    }
  }

  @objc func done(_ sender: Any?) {
    if let selectedShippingMethod = selectedShippingMethod {
      delegate?.shippingMethodsViewController(self, didFinishWith: selectedShippingMethod)
    }
  }

  override func useSystemBackButton() -> Bool {
    return true
  }

  // MARK: - UITableView
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return shippingMethods?.count ?? 0
  }

  func tableView(
    _ tableView: UITableView,
    cellForRowAt indexPath: IndexPath
  ) -> UITableViewCell {
    let cell =
      tableView.dequeueReusableCell(
        withIdentifier: STPShippingMethodCellReuseIdentifier, for: indexPath)
      as? STPShippingMethodTableViewCell
    let method =
      shippingMethods?.stp_boundSafeObject(at: indexPath.row) as? PKShippingMethod
    cell?.theme = theme
    if let method = method {
      cell?.setShippingMethod(method, currency: currency ?? "")
    }
    cell?.isSelected = method?.identifier == selectedShippingMethod?.identifier
    return cell!
  }

  func tableView(
    _ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath
  ) {
    let topRow = indexPath.row == 0
    let bottomRow =
      self.tableView(tableView, numberOfRowsInSection: indexPath.section) - 1 == indexPath.row
    cell.stp_setBorderColor(theme.tertiaryBackgroundColor)
    cell.stp_setTopBorderHidden(!topRow)
    cell.stp_setBottomBorderHidden(!bottomRow)
    cell.stp_setFakeSeparatorColor(theme.quaternaryBackgroundColor)
    cell.stp_setFakeSeparatorLeftInset(15.0)
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 57
  }

  func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    return 27.0
  }

  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int)
    -> CGFloat
  {
    let size = headerView?.sizeThatFits(
      CGSize(width: view.bounds.size.width, height: CGFloat.greatestFiniteMagnitude))
    return size?.height ?? 0.0
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    return headerView
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    selectedShippingMethod =
      shippingMethods?.stp_boundSafeObject(at: indexPath.row) as? PKShippingMethod
    tableView.reloadSections(
      NSIndexSet(index: indexPath.section) as IndexSet,
      with: .fade)
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  required init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    fatalError("init(nibName:bundle:) has not been implemented")
  }

  required init(theme: STPTheme?) {
    fatalError("init(theme:) has not been implemented")
  }
}

@objc protocol STPShippingMethodsViewControllerDelegate: NSObjectProtocol {
  func shippingMethodsViewController(
    _ methodsViewController: STPShippingMethodsViewController,
    didFinishWith method: PKShippingMethod
  )
}

private let STPShippingMethodCellReuseIdentifier = "STPShippingMethodCellReuseIdentifier"
