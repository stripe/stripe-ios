//
//  STPPaymentOptionsInternalViewController.swift
//  Stripe
//
//  Created by Jack Flintermann on 6/9/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

@objc protocol STPPaymentOptionsInternalViewControllerDelegate: AnyObject {
  func internalViewControllerDidSelect(_ paymentOption: STPPaymentOption?)
  func internalViewControllerDidDelete(_ paymentOption: STPPaymentOption?)
  func internalViewControllerDidCreatePaymentOption(
    _ paymentOption: STPPaymentOption?, completion: @escaping STPErrorBlock)
  func internalViewControllerDidCancel()
}

class STPPaymentOptionsInternalViewController: STPCoreTableViewController, UITableViewDataSource,
  UITableViewDelegate, STPAddCardViewControllerDelegate, STPBankSelectionViewControllerDelegate
{
  init(
    configuration: STPPaymentConfiguration,
    customerContext: STPCustomerContext?,
    apiClient: STPAPIClient,
    theme: STPTheme,
    prefilledInformation: STPUserInformation?,
    shippingAddress: STPAddress?,
    paymentOptionTuple tuple: STPPaymentOptionTuple,
    delegate: STPPaymentOptionsInternalViewControllerDelegate?
  ) {
    super.init(theme: theme)
    self.configuration = configuration
    // This parameter may be a custom API adapter, and not a CustomerContext.
    apiAdapter = customerContext
    self.apiClient = apiClient
    self.prefilledInformation = prefilledInformation
    self.shippingAddress = shippingAddress
    paymentOptions = tuple.paymentOptions
    selectedPaymentOption = tuple.selectedPaymentOption
    self.delegate = delegate

    title = STPLocalizedString("Payment Method", "Title for Payment Method screen")
  }

  func update(with tuple: STPPaymentOptionTuple) {
    if let selectedPaymentOption = selectedPaymentOption,
      selectedPaymentOption.isEqual(tuple.selectedPaymentOption)
    {
      return
    }

    paymentOptions = tuple.paymentOptions
    selectedPaymentOption = tuple.selectedPaymentOption

    // Reload card list section
    let sections = NSMutableIndexSet(index: PaymentOptionSectionCardList)
    tableView?.reloadSections(sections as IndexSet, with: .automatic)
  }

  private var _customFooterView: UIView?
  var customFooterView: UIView? {
    get {
      _customFooterView
    }
    set(footerView) {
      _customFooterView = footerView
      _didSetCustomFooterView()
    }
  }
  func _didSetCustomFooterView() {
    if isViewLoaded {
      if let size = _customFooterView?.sizeThatFits(
        CGSize(width: view.bounds.size.width, height: CGFloat.greatestFiniteMagnitude))
      {
        _customFooterView?.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
      }

      tableView?.tableFooterView = _customFooterView
    }
  }

  var addCardViewControllerCustomFooterView: UIView?
  private var configuration: STPPaymentConfiguration?
  private var apiAdapter: STPBackendAPIAdapter?
  private var prefilledInformation: STPUserInformation?
  private var shippingAddress: STPAddress?
  private var paymentOptions: [STPPaymentOption]?
  private var apiClient: STPAPIClient?
  private var selectedPaymentOption: STPPaymentOption?
  private weak var delegate: STPPaymentOptionsInternalViewControllerDelegate?
  private var cardImageView: UIImageView?

  override func createAndSetupViews() {
    super.createAndSetupViews()

    // Table view
    tableView?.register(
      STPPaymentOptionTableViewCell.self, forCellReuseIdentifier: PaymentOptionCellReuseIdentifier)

    tableView?.dataSource = self
    tableView?.delegate = self
    tableView?.reloadData()

    // Table header view
    let cardImageView = UIImageView(image: STPImageLibrary.largeCardFrontImage())
    cardImageView.contentMode = .center
    cardImageView.frame = CGRect(
      x: 0.0, y: 0.0, width: view.bounds.size.width,
      height: cardImageView.bounds.size.height + (57.0 * 2.0))
    cardImageView.image = STPImageLibrary.largeCardFrontImage()
    cardImageView.tintColor = theme.accentColor
    self.cardImageView = cardImageView

    tableView?.tableHeaderView = cardImageView

    // Table view editing state
    tableView?.setEditing(false, animated: false)
    reloadRightBarButtonItem(withTableViewIsEditing: tableView?.isEditing ?? false, animated: false)

    stp_navigationItemProxy?.leftBarButtonItem?.accessibilityIdentifier =
      "PaymentOptionsViewControllerCancelButtonIdentifier"
    // re-set the custom footer view if it was added before we loaded
    _didSetCustomFooterView()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    // Resetting it re-calculates the size based on new view width
    // UITableView requires us to call setter again to actually pick up frame
    // change on footers
    if tableView?.tableFooterView != nil {
      customFooterView = tableView?.tableFooterView
    }
  }

  func reloadRightBarButtonItem(withTableViewIsEditing tableViewIsEditing: Bool, animated: Bool) {
    var barButtonItem: UIBarButtonItem?

    if !tableViewIsEditing {
      if isAnyPaymentOptionDetachable() {
        // Show edit button
        barButtonItem = UIBarButtonItem(
          barButtonSystemItem: .edit, target: self, action: #selector(handleEditButtonTapped(_:)))
      } else {
        // Show no button
        barButtonItem = nil
      }
    } else {
      // Show done button
      barButtonItem = UIBarButtonItem(
        barButtonSystemItem: .done, target: self, action: #selector(handleDoneButtonTapped(_:)))
    }

    stp_navigationItemProxy?.setRightBarButton(barButtonItem, animated: animated)
  }

  func isAnyPaymentOptionDetachable() -> Bool {
    for paymentOption in cardPaymentOptions() {
      if isPaymentOptionDetachable(paymentOption) {
        return true
      }
    }

    return false
  }

  func isPaymentOptionDetachable(_ paymentOption: STPPaymentOption?) -> Bool {
    if !(configuration?.canDeletePaymentOptions ?? false) {
      // Feature is disabled
      return false
    }

    if apiAdapter == nil {
      // Cannot detach payment methods without customer context
      return false
    }

    if !(apiAdapter?.responds(
      to: #selector(STPCustomerContext.detachPaymentMethod(fromCustomer:completion:))) ?? false)
    {
      // Cannot detach payment methods if customerContext is an apiAdapter
      // that doesn't implement detachPaymentMethod
      return false
    }

    if paymentOption == nil {
      // Cannot detach non-existent payment method
      return false
    }

    if !(paymentOption is STPPaymentMethod) {
      // Cannot detach non-payment method
      return false
    }

    // Payment method can be deleted from customer
    return true
  }

  func cardPaymentOptions() -> [STPPaymentOption] {
    guard let paymentOptions = paymentOptions else {
      return []
    }

    return paymentOptions.filter({ (o) -> Bool in
      if o is STPPaymentMethodParams {
        let paymentMethodParams = o as? STPPaymentMethodParams
        if paymentMethodParams?.type != .card {
          return false
        }
      }
      return true
    })
  }

  func apmPaymentOptions() -> [STPPaymentOption] {
    guard let paymentOptions = paymentOptions else {
      return []
    }
    return paymentOptions.filter({ (o) -> Bool in
      if (o) is STPPaymentMethodParams {
        let paymentMethodParams = o as? STPPaymentMethodParams
        if paymentMethodParams?.type == .FPX {
          // Add other APMs as we gain support for them in Basic Integration
          return true
        }
      }
      return false
    })
  }

  // MARK: - Button Handlers
  @objc override func handleCancelTapped(_ sender: Any?) {
    delegate?.internalViewControllerDidCancel()
  }

  @objc func handleEditButtonTapped(_ sender: Any?) {
    tableView?.setEditing(true, animated: true)
    reloadRightBarButtonItem(withTableViewIsEditing: tableView?.isEditing ?? false, animated: true)
  }

  @objc func handleDoneButtonTapped(_ sender: Any?) {
    _endTableViewEditing()
    reloadRightBarButtonItem(withTableViewIsEditing: tableView?.isEditing ?? false, animated: true)
  }

  func _endTableViewEditing() {
    tableView?.setEditing(false, animated: true)
  }

  // MARK: - UITableViewDataSource
  func numberOfSections(in tableView: UITableView) -> Int {
    if apmPaymentOptions().count > 0 {
      return 3
    } else {
      return 2
    }
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == PaymentOptionSectionCardList {
      return cardPaymentOptions().count
    }

    if section == PaymentOptionSectionAddCard {
      return 1
    }

    if section == PaymentOptionSectionAPM {
      return apmPaymentOptions().count
    }

    return 0
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell =
      tableView.dequeueReusableCell(
        withIdentifier: PaymentOptionCellReuseIdentifier, for: indexPath)
      as? STPPaymentOptionTableViewCell

    if indexPath.section == PaymentOptionSectionCardList {
      weak var paymentOption =
        cardPaymentOptions().stp_boundSafeObject(at: indexPath.row)
        as? STPPaymentOption
      let selected = paymentOption!.isEqual(selectedPaymentOption)

      cell?.configure(with: paymentOption!, theme: theme, selected: selected)
    } else if indexPath.section == PaymentOptionSectionAddCard {
      cell?.configureForNewCardRow(with: theme)
      cell?.accessibilityIdentifier = "PaymentOptionsTableViewAddNewCardButtonIdentifier"
    } else if indexPath.section == PaymentOptionSectionAPM {
      weak var paymentOption =
        apmPaymentOptions().stp_boundSafeObject(at: indexPath.row) as? STPPaymentOption
      if paymentOption is STPPaymentMethodParams {
        let paymentMethodParams = paymentOption as? STPPaymentMethodParams
        if paymentMethodParams?.type == .FPX {
          cell?.configureForFPXRow(with: theme)
          cell?.accessibilityIdentifier = "PaymentOptionsTableViewFPXButtonIdentifier"
        }
      }
    }

    return cell!
  }

  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    if indexPath.section == PaymentOptionSectionCardList {
      weak var paymentOption =
        cardPaymentOptions().stp_boundSafeObject(at: indexPath.row)
        as? STPPaymentOption

      if isPaymentOptionDetachable(paymentOption) {
        return true
      }
    }

    return false
  }

  func tableView(
    _ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
    forRowAt indexPath: IndexPath
  ) {
    if indexPath.section == PaymentOptionSectionCardList {
      if editingStyle != .delete {
        // Showed the user a non-delete option when we shouldn't have
        tableView.reloadData()
        return
      }

      if !(indexPath.row < cardPaymentOptions().count) {
        // Data source and table view out of sync for some reason
        tableView.reloadData()
        return
      }

      weak var paymentOptionToDelete =
        cardPaymentOptions().stp_boundSafeObject(at: indexPath.row)
        as? STPPaymentOption

      if !isPaymentOptionDetachable(paymentOptionToDelete) {
        // Showed the user a delete option for a payment method when we shouldn't have
        tableView.reloadData()
        return
      }

      let paymentMethod = paymentOptionToDelete as? STPPaymentMethod

      // Kickoff request to delete payment method from customer
      if let paymentMethod = paymentMethod {
        apiAdapter?.detachPaymentMethod?(fromCustomer: paymentMethod, completion: nil)
      }

      // Optimistically remove payment method from data source
      var paymentOptions = self.paymentOptions
      paymentOptions?.removeAll { $0 as AnyObject === paymentOptionToDelete as AnyObject }
      self.paymentOptions = paymentOptions

      // Perform deletion animation for single row
      tableView.deleteRows(at: [indexPath], with: .automatic)

      var tableViewIsEditing = tableView.isEditing
      if !isAnyPaymentOptionDetachable() {
        // we deleted the last available payment option, stop editing
        // (but delay to next runloop because calling tableView setEditing:animated:
        // in this function is not allowed)
        DispatchQueue.main.async(execute: {
          self._endTableViewEditing()
        })
        // manually set the value passed to reloadRightBarButtonItemWithTableViewIsEditing
        // below
        tableViewIsEditing = false
      }

      // Reload right bar button item text
      reloadRightBarButtonItem(withTableViewIsEditing: tableViewIsEditing, animated: true)

      // Notify delegate
      delegate?.internalViewControllerDidDelete(paymentOptionToDelete)
    }
  }

  // MARK: - UITableViewDelegate
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.section == PaymentOptionSectionCardList {
      // Update data source
      weak var paymentOption =
        cardPaymentOptions().stp_boundSafeObject(at: indexPath.row)
        as? STPPaymentOption
      selectedPaymentOption = paymentOption

      // Perform selection animation
      tableView.reloadSections(
        NSIndexSet(index: PaymentOptionSectionCardList) as IndexSet, with: .fade)

      // Notify delegate
      delegate?.internalViewControllerDidSelect(paymentOption)
    } else if indexPath.section == PaymentOptionSectionAddCard {
      var paymentCardViewController: STPAddCardViewController?
      if let configuration = configuration {
        paymentCardViewController = STPAddCardViewController(
          configuration: configuration, theme: theme)
      }
      paymentCardViewController?.apiClient = apiClient
      paymentCardViewController?.delegate = self
      paymentCardViewController?.prefilledInformation = prefilledInformation
      paymentCardViewController?.shippingAddress = shippingAddress
      paymentCardViewController?.customFooterView = addCardViewControllerCustomFooterView

      if let paymentCardViewController = paymentCardViewController {
        navigationController?.pushViewController(paymentCardViewController, animated: true)
      }
    } else if indexPath.section == PaymentOptionSectionAPM {
      weak var paymentOption =
        apmPaymentOptions().stp_boundSafeObject(at: indexPath.row) as? STPPaymentOption
      if paymentOption is STPPaymentMethodParams {
        if let paymentMethodParams = paymentOption as? STPPaymentMethodParams,
          paymentMethodParams.type == .FPX
        {
          var bankSelectionViewController: STPBankSelectionViewController?
          if let configuration = configuration {
            bankSelectionViewController = STPBankSelectionViewController(
              bankMethod: .FPX, configuration: configuration, theme: theme)
          }
          bankSelectionViewController?.apiClient = apiClient
          bankSelectionViewController?.delegate = self

          if let bankSelectionViewController = bankSelectionViewController {
            navigationController?.pushViewController(bankSelectionViewController, animated: true)
          }
        }
      }
    }

    tableView.deselectRow(at: indexPath, animated: true)
  }

  func tableView(
    _ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath
  ) {
    let isTopRow = indexPath.row == 0
    let isBottomRow =
      self.tableView(tableView, numberOfRowsInSection: indexPath.section) - 1 == indexPath.row

    cell.stp_setBorderColor(theme.tertiaryBackgroundColor)
    cell.stp_setTopBorderHidden(!isTopRow)
    cell.stp_setBottomBorderHidden(!isBottomRow)
    cell.stp_setFakeSeparatorColor(theme.quaternaryBackgroundColor)
    cell.stp_setFakeSeparatorLeftInset(15.0)
  }

  func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    if self.tableView(tableView, numberOfRowsInSection: section) == 0 {
      return 0.01
    }

    return 27.0
  }

  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int)
    -> CGFloat
  {
    return 0.01
  }

  func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath)
    -> UITableViewCell.EditingStyle
  {
    if indexPath.section == PaymentOptionSectionCardList {
      return .delete
    }

    return .none
  }

  func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
    reloadRightBarButtonItem(withTableViewIsEditing: true, animated: true)
  }

  func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
    reloadRightBarButtonItem(withTableViewIsEditing: tableView.isEditing, animated: true)
  }

  // MARK: - STPAddCardViewControllerDelegate
  func addCardViewControllerDidCancel(_ addCardViewController: STPAddCardViewController) {
    navigationController?.popViewController(animated: true)
  }

  @objc func addCardViewController(
    _ addCardViewController: STPAddCardViewController,
    didCreatePaymentMethod paymentMethod: STPPaymentMethod, completion: @escaping STPErrorBlock
  ) {
    delegate?.internalViewControllerDidCreatePaymentOption(paymentMethod, completion: completion)
  }

  @objc func bankSelectionViewController(
    _ bankViewController: STPBankSelectionViewController,
    didCreatePaymentMethodParams paymentMethodParams: STPPaymentMethodParams
  ) {
    delegate?.internalViewControllerDidCreatePaymentOption(paymentMethodParams) { _ in
    }
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

private let PaymentOptionCellReuseIdentifier = "PaymentOptionCellReuseIdentifier"
private let PaymentOptionSectionCardList = 0
private let PaymentOptionSectionAddCard = 1
private let PaymentOptionSectionAPM = 2
