//
//  STPShippingAddressViewController.swift
//  Stripe
//
//  Created by Ben Guo on 8/29/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import PassKit
import UIKit

/// This view controller contains a shipping address collection form. It renders a right bar button item that submits the form, so it must be shown inside a `UINavigationController`. Depending on your configuration's shippingType, the view controller may present a shipping method selection form after the user enters an address.
public class STPShippingAddressViewController : STPCoreTableViewController
{

  /// A convenience initializer; equivalent to calling `init(configuration: STPPaymentConfiguration.shared theme: STPTheme.defaultTheme currency:"" shippingAddress:nil selectedShippingMethod:nil prefilledInformation:nil)`.
  @objc
  public convenience init() {
    self.init(
      configuration: STPPaymentConfiguration.shared, theme: STPTheme.defaultTheme, currency: "",
      shippingAddress: nil, selectedShippingMethod: nil, prefilledInformation: nil)
  }

  /// Initializes a new `STPShippingAddressViewController` with the given payment context and sets the payment context as its delegate.
  /// - Parameter paymentContext: The payment context to use.
  @objc(initWithPaymentContext:)
  public convenience init(paymentContext: STPPaymentContext) {
    STPAnalyticsClient.sharedClient.addClass(
      toProductUsageIfNecessary: STPShippingAddressViewController.self)

    var billingAddress: STPAddress?
    weak var paymentOption = paymentContext.selectedPaymentOption
    if paymentOption is STPCard {
      let card = paymentOption as? STPCard
      billingAddress = card?.address
    } else if paymentOption is STPPaymentMethod {
      let paymentMethod = paymentOption as? STPPaymentMethod
      if let billingDetails1 = paymentMethod?.billingDetails {
        billingAddress = STPAddress(paymentMethodBillingDetails: billingDetails1)
      }
    }
    var prefilledInformation: STPUserInformation?
    if paymentContext.prefilledInformation != nil {
      prefilledInformation = paymentContext.prefilledInformation
    } else {
      prefilledInformation = STPUserInformation()
    }
    prefilledInformation?.billingAddress = billingAddress
    self.init(
      configuration: paymentContext.configuration,
      theme: paymentContext.theme,
      currency: paymentContext.paymentCurrency,
      shippingAddress: paymentContext.shippingAddress,
      selectedShippingMethod: paymentContext.selectedShippingMethod,
      prefilledInformation: prefilledInformation)

    self.delegate = paymentContext
  }

  /// Initializes a new `STPShippingAddressCardViewController` with the provided parameters.
  /// - Parameters:
  ///   - configuration:             The configuration to use (this determines the required shipping address fields and shipping type). - seealso: STPPaymentConfiguration
  ///   - theme:                     The theme to use to inform the view controller's visual appearance. - seealso: STPTheme
  ///   - currency:                  The currency to use when displaying amounts for shipping methods. The default is USD.
  ///   - shippingAddress:           If set, the shipping address view controller will be pre-filled with this address. - seealso: STPAddress
  ///   - selectedShippingMethod:    If set, the shipping methods view controller will use this method as the selected shipping method. If `selectedShippingMethod` is nil, the first shipping method in the array of methods returned by your delegate will be selected.
  ///   - prefilledInformation:      If set, the shipping address view controller will be pre-filled with this information. - seealso: STPUserInformation
  @objc(
    initWithConfiguration:theme:currency:shippingAddress:selectedShippingMethod:
    prefilledInformation:
  )
  public init(
    configuration: STPPaymentConfiguration,
    theme: STPTheme,
    currency: String?,
    shippingAddress: STPAddress?,
    selectedShippingMethod: PKShippingMethod?,
    prefilledInformation: STPUserInformation?
  ) {
    STPAnalyticsClient.sharedClient.addClass(
      toProductUsageIfNecessary: STPShippingAddressViewController.self)
    addressViewModel = STPAddressViewModel(
      requiredBillingFields: configuration.requiredBillingAddressFields,
      availableCountries: configuration.availableCountries)
    super.init(theme: theme)
    assert(
      (configuration.requiredShippingAddressFields?.count ?? 0) > 0,
      "`requiredShippingAddressFields` must not be empty when initializing an STPShippingAddressViewController."
    )
    self.configuration = configuration
    self.currency = currency
    self.selectedShippingMethod = selectedShippingMethod
    billingAddress = prefilledInformation?.billingAddress
    hasUsedBillingAddress = false
    addressViewModel = STPAddressViewModel(
      requiredShippingFields: configuration.requiredShippingAddressFields ?? [],
      availableCountries: configuration.availableCountries)
    addressViewModel.delegate = self
    if let shippingAddress = shippingAddress {
      addressViewModel.address = shippingAddress
    } else if prefilledInformation?.shippingAddress != nil {
      addressViewModel.address = prefilledInformation?.shippingAddress ?? STPAddress()
    }
    title = title(for: self.configuration?.shippingType ?? .shipping)
  }

  /// The view controller's delegate. This must be set before showing the view controller in order for it to work properly. - seealso: STPShippingAddressViewControllerDelegate
  @objc public weak var delegate: STPShippingAddressViewControllerDelegate?

  /// If you're pushing `STPShippingAddressViewController` onto an existing `UINavigationController`'s stack, you should use this method to dismiss it, since it may have pushed an additional shipping method view controller onto the navigation controller's stack.
  /// - Parameter completion: The callback to run after the view controller is dismissed. You may specify nil for this parameter.
  @objc(dismissWithCompletion:)
  public func dismiss(withCompletion completion: STPVoidBlock?) {
    if stp_isAtRootOfNavigationController() {
      presentingViewController?.dismiss(animated: true, completion: completion ?? {})
    } else {
      var previous = navigationController?.viewControllers.first
      for viewController in navigationController?.viewControllers ?? [] {
        if viewController == self {
          break
        }
        previous = viewController
      }
      navigationController?.stp_pop(to: previous, animated: true, completion: completion ?? {})
    }
  }

  /// Use one of the initializers declared in this interface.
  @available(*, unavailable, message: "Use one of the initializers declared in this interface instead.")
  @objc public required init(theme: STPTheme?) {
    let configuration = STPPaymentConfiguration.shared
    addressViewModel = STPAddressViewModel(
      requiredBillingFields: configuration.requiredBillingAddressFields,
      availableCountries: configuration.availableCountries)

    super.init(theme: theme)
  }

  /// Use one of the initializers declared in this interface.
  @available(*, unavailable, message: "Use one of the initializers declared in this interface instead.")
  @objc public required init(
    nibName nibNameOrNil: String?,
    bundle nibBundleOrNil: Bundle?
  ) {
    let configuration = STPPaymentConfiguration.shared
    addressViewModel = STPAddressViewModel(
      requiredBillingFields: configuration.requiredBillingAddressFields,
      availableCountries: configuration.availableCountries)
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  /// Use one of the initializers declared in this interface.
  @available(*, unavailable, message: "Use one of the initializers declared in this interface instead.")
  required init?(coder aDecoder: NSCoder) {
    let configuration = STPPaymentConfiguration.shared
    addressViewModel = STPAddressViewModel(
      requiredBillingFields: configuration.requiredBillingAddressFields,
      availableCountries: configuration.availableCountries)
    super.init(coder: aDecoder)
  }

  private var configuration: STPPaymentConfiguration?
  private var currency: String?
  private var selectedShippingMethod: PKShippingMethod?
  private weak var imageView: UIImageView?
  private var nextItem: UIBarButtonItem?

  private var _loading = false
  private var loading: Bool {
    get {
      _loading
    }
    set(loading) {
      if loading == _loading {
        return
      }
      _loading = loading
      stp_navigationItemProxy?.setHidesBackButton(loading, animated: true)
      stp_navigationItemProxy?.leftBarButtonItem?.isEnabled = !loading
      activityIndicator?.animating = loading
      if loading {
        tableView?.endEditing(true)
        var loadingItem: UIBarButtonItem?
        if let activityIndicator = activityIndicator {
          loadingItem = UIBarButtonItem(customView: activityIndicator)
        }
        stp_navigationItemProxy?.setRightBarButton(loadingItem, animated: true)
      } else {
        stp_navigationItemProxy?.setRightBarButton(nextItem, animated: true)
      }
      for cell in addressViewModel.addressCells {
        cell.isUserInteractionEnabled = !loading
        UIView.animate(
          withDuration: 0.1,
          animations: {
            cell.alpha = loading ? 0.7 : 1.0
          })
      }
    }
  }
  private var activityIndicator: STPPaymentActivityIndicatorView?
  internal var addressViewModel: STPAddressViewModel
  private var billingAddress: STPAddress?
  private var hasUsedBillingAddress = false
  private var addressHeaderView: STPSectionHeaderView?

  override func createAndSetupViews() {
    super.createAndSetupViews()

    var nextItem: UIBarButtonItem?
    switch configuration?.shippingType {
    case .shipping:
      nextItem = UIBarButtonItem(
        title: STPLocalizedString("Next", "Button to move to the next text entry field"),
        style: .done,
        target: self,
        action: #selector(next(_:)))
    case .delivery, .none, .some:
      nextItem = UIBarButtonItem(
        barButtonSystemItem: .done,
        target: self,
        action: #selector(next(_:)))
    }
    self.nextItem = nextItem
    stp_navigationItemProxy?.rightBarButtonItem = nextItem
    stp_navigationItemProxy?.rightBarButtonItem?.isEnabled = false
    stp_navigationItemProxy?.rightBarButtonItem?.accessibilityIdentifier =
      "ShippingViewControllerNextButtonIdentifier"

    let imageView = UIImageView(image: STPImageLibrary.largeShippingImage())
    imageView.contentMode = .center
    imageView.frame = CGRect(
      x: 0, y: 0, width: view.bounds.size.width, height: imageView.bounds.size.height + (57 * 2))
    self.imageView = imageView
    tableView?.tableHeaderView = imageView

    activityIndicator = STPPaymentActivityIndicatorView(
      frame: CGRect(x: 0, y: 0, width: 20.0, height: 20.0))

    tableView?.dataSource = self
    tableView?.delegate = self
    tableView?.reloadData()
    view.addGestureRecognizer(
      UITapGestureRecognizer(target: self, action: #selector(NSMutableAttributedString.endEditing)))

    let headerView = STPSectionHeaderView()
    headerView.theme = theme
    if let shippingType1 = configuration?.shippingType {
      headerView.title = headerTitle(for: shippingType1)
    }
    headerView.button?.setTitle(
      STPLocalizedString("Use Billing", "Button to fill shipping address from billing address."),
      for: .normal)
    headerView.button?.addTarget(
      self,
      action: #selector(useBillingAddress(_:)),
      for: .touchUpInside)
    headerView.button?.accessibilityIdentifier = "ShippingAddressViewControllerUseBillingButton"
    var buttonVisible = false
    if let requiredFields = configuration?.requiredShippingAddressFields {
      let needsAddress = requiredFields.contains(.postalAddress) && !(addressViewModel.isValid)
      buttonVisible =
        needsAddress
        && billingAddress?.containsContent(forShippingAddressFields: requiredFields) ?? false
        && !hasUsedBillingAddress
    }
    headerView.button?.alpha = buttonVisible ? 1 : 0
    headerView.setNeedsLayout()
    addressHeaderView = headerView

    updateDoneButton()
  }

  @objc func endEditing() {
    view.endEditing(false)
  }

  @objc override func updateAppearance() {
    super.updateAppearance()
    let navBarTheme = navigationController?.navigationBar.stp_theme ?? theme
    nextItem?.stp_setTheme(navBarTheme)

    tableView?.allowsSelection = false

    imageView?.tintColor = theme.accentColor
    activityIndicator?.tintColor = theme.accentColor
    for cell in addressViewModel.addressCells {
      cell.theme = theme
    }
    addressHeaderView?.theme = theme
  }

  /// :nodoc:
  @objc
  public override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    stp_beginObservingKeyboardAndInsettingScrollView(
      tableView,
      onChange: nil)
    firstEmptyField()?.becomeFirstResponder()
  }

  func firstEmptyField() -> UIResponder? {
    for cell in addressViewModel.addressCells {
      if (cell.contents?.count ?? 0) == 0 {
        return cell
      }
    }
    return nil
  }

  @objc override func handleCancelTapped(_ sender: Any?) {
    delegate?.shippingAddressViewControllerDidCancel(self)
  }

  @objc func next(_ sender: Any?) {
    let address = addressViewModel.address
    switch configuration?.shippingType {
    case .shipping:
      loading = true
      delegate?.shippingAddressViewController(self, didEnter: address) {
        status, shippingValidationError, shippingMethods, selectedShippingMethod in
        self.loading = false
        if status == .valid {
          if (shippingMethods?.count ?? 0) > 0 {
            var nextViewController: STPShippingMethodsViewController?
            if let shippingMethods = shippingMethods,
              let selectedShippingMethod = selectedShippingMethod
            {
              nextViewController = STPShippingMethodsViewController(
                shippingMethods: shippingMethods,
                selectedShippingMethod: selectedShippingMethod,
                currency: self.currency ?? "",
                theme: self.theme)
            }
            nextViewController?.delegate = self
            if let nextViewController = nextViewController {
              self.navigationController?.pushViewController(nextViewController, animated: true)
            }
          } else {
            self.delegate?.shippingAddressViewController(
              self,
              didFinishWith: address,
              shippingMethod: nil)
          }
        } else {
          self.handleShippingValidationError(shippingValidationError)
        }
      }
    case .delivery, .none, .some:
      delegate?.shippingAddressViewController(
        self,
        didFinishWith: address,
        shippingMethod: nil)
    }
  }

  func updateDoneButton() {
    stp_navigationItemProxy?.rightBarButtonItem?.isEnabled = addressViewModel.isValid
  }

  func handleShippingValidationError(_ error: Error?) {
    firstEmptyField()?.becomeFirstResponder()
    var title = STPLocalizedString("Invalid Shipping Address", "Shipping form error message")
    var message: String?
    if let error = error {
      title = error.localizedDescription
      message = (error as NSError).localizedFailureReason
    }
    let alertController = UIAlertController(
      title: title,
      message: message,
      preferredStyle: .alert)
    alertController.addAction(
      UIAlertAction(
        title: STPLocalizedString("OK", "ok button"),
        style: .cancel,
        handler: nil))
    present(alertController, animated: true)
  }

  
  /// :nodoc:
  @objc
  public override func tableView(
    _ tableView: UITableView, heightForHeaderInSection section: Int
  ) -> CGFloat {
    let size = addressHeaderView?.sizeThatFits(
      CGSize(width: view.bounds.size.width, height: CGFloat.greatestFiniteMagnitude))
    return size?.height ?? 0.0
  }
  
  @objc func useBillingAddress(_ sender: UIButton) {
    guard let billingAddress = billingAddress else {
      return
    }
    tableView?.beginUpdates()
    addressViewModel.address = billingAddress
    hasUsedBillingAddress = true
    firstEmptyField()?.becomeFirstResponder()
    UIView.animate(
      withDuration: 0.2,
      animations: {
        self.addressHeaderView?.buttonHidden = true
      })
    tableView?.endUpdates()
  }

  func title(for type: STPShippingType) -> String {
    if let shippingAddressFields = configuration?.requiredShippingAddressFields,
      shippingAddressFields.contains(.postalAddress)
    {
      switch type {
      case .shipping:
        return STPLocalizedString("Shipping", "Title for shipping info form")
      case .delivery:
        return STPLocalizedString("Delivery", "Title for delivery info form")
      }
    } else {
      return STPLocalizedString("Contact", "Title for contact info form")
    }
  }

  func headerTitle(for type: STPShippingType) -> String {
    if let shippingAddressFields = configuration?.requiredShippingAddressFields,
      shippingAddressFields.contains(.postalAddress)
    {
      switch type {
      case .shipping:
        return STPLocalizedString("Shipping Address", "Title for shipping address entry section")
      case .delivery:
        return STPLocalizedString("Delivery Address", "Title for delivery address entry section")
      }
    } else {
      return STPLocalizedString("Contact", "Title for contact info form")
    }
  }
}

/// An `STPShippingAddressViewControllerDelegate` is notified when an `STPShippingAddressViewController` receives an address, completes with an address, or is cancelled.
@objc public protocol STPShippingAddressViewControllerDelegate: NSObjectProtocol {
  /// Called when the user cancels entering a shipping address. You should dismiss (or pop) the view controller at this point.
  /// - Parameter addressViewController: the view controller that has been cancelled
  func shippingAddressViewControllerDidCancel(
    _ addressViewController: STPShippingAddressViewController)
  /// This is called when the user enters a shipping address and taps next. You
  /// should validate the address and determine what shipping methods are available,
  /// and call the `completion` block when finished. If an error occurrs, call
  /// the `completion` block with the error. Otherwise, call the `completion`
  /// block with a nil error and an array of available shipping methods. If you don't
  /// need to collect a shipping method, you may pass an empty array or nil.
  /// - Parameters:
  ///   - addressViewController: the view controller where the address was entered
  ///   - address:               the address that was entered. - seealso: STPAddress
  ///   - completion:            call this callback when you're done validating the address and determining available shipping methods.

  @objc(shippingAddressViewController:didEnterAddress:completion:)
  func shippingAddressViewController(
    _ addressViewController: STPShippingAddressViewController,
    didEnter address: STPAddress,
    completion: @escaping STPShippingMethodsCompletionBlock
  )
  /// This is called when the user selects a shipping method. If no shipping methods are given, or if the shipping type doesn't require a shipping method, this will be called after the user has a shipping address and your validation has succeeded. After updating your app with the user's shipping info, you should dismiss (or pop) the view controller. Note that if `shippingMethod` is non-nil, there will be an additional shipping methods view controller on the navigation controller's stack.
  /// - Parameters:
  ///   - addressViewController: the view controller where the address was entered
  ///   - address:               the address that was entered. - seealso: STPAddress
  ///   - method:        the shipping method that was selected.
  @objc(shippingAddressViewController:didFinishWithAddress:shippingMethod:)
  func shippingAddressViewController(
    _ addressViewController: STPShippingAddressViewController,
    didFinishWith address: STPAddress,
    shippingMethod method: PKShippingMethod?
  )
}

extension STPShippingAddressViewController :
STPAddressViewModelDelegate, UITableViewDelegate, UITableViewDataSource,
STPShippingMethodsViewControllerDelegate {
  
  // MARK: - UITableView
  /// :nodoc:
  @objc
  public func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  /// :nodoc:
  @objc
  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return addressViewModel.addressCells.count
  }

  /// :nodoc:
  @objc
  public func tableView(
    _ tableView: UITableView,
    cellForRowAt indexPath: IndexPath
  ) -> UITableViewCell {
    let cell =
      addressViewModel.addressCells.stp_boundSafeObject(at: indexPath.row)
      as? UITableViewCell
    cell?.backgroundColor = theme.secondaryBackgroundColor
    cell?.contentView.backgroundColor = UIColor.clear
    return cell!
  }

  /// :nodoc:
  @objc
  public func tableView(
    _ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath
  ) {
    let topRow = indexPath.row == 0
    let bottomRow = tableView.numberOfRows(inSection: indexPath.section) - 1 == indexPath.row
    cell.stp_setBorderColor(theme.tertiaryBackgroundColor)
    cell.stp_setTopBorderHidden(!topRow)
    cell.stp_setBottomBorderHidden(!bottomRow)
    cell.stp_setFakeSeparatorColor(theme.quaternaryBackgroundColor)
    cell.stp_setFakeSeparatorLeftInset(15.0)
  }

  /// :nodoc:
  @objc
  public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int)
    -> CGFloat
  {
    return 0.01
  }

  /// :nodoc:
  @objc
  public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int)
    -> UIView?
  {
    return UIView()
  }

  /// :nodoc:
  @objc
  public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int)
    -> UIView?
  {
    return addressHeaderView
  }

  // MARK: - STPShippingMethodsViewControllerDelegate
  func shippingMethodsViewController(
    _ methodsViewController: STPShippingMethodsViewController,
    didFinishWith method: PKShippingMethod
  ) {
    delegate?.shippingAddressViewController(
      self,
      didFinishWith: addressViewModel.address,
      shippingMethod: method)
  }
  
  // MARK: - STPAddressViewModelDelegate
  func addressViewModel(_ addressViewModel: STPAddressViewModel, addedCellAt index: Int) {
    let indexPath = IndexPath(row: index, section: 0)
    tableView?.insertRows(at: [indexPath], with: .automatic)
  }

  func addressViewModel(_ addressViewModel: STPAddressViewModel, removedCellAt index: Int) {
    let indexPath = IndexPath(row: index, section: 0)
    tableView?.deleteRows(at: [indexPath], with: .automatic)
  }

  func addressViewModelDidChange(_ addressViewModel: STPAddressViewModel) {
    updateDoneButton()
  }

  func addressViewModelWillUpdate(_ addressViewModel: STPAddressViewModel) {
    tableView?.beginUpdates()
  }

  func addressViewModelDidUpdate(_ addressViewModel: STPAddressViewModel) {
    tableView?.endUpdates()
  }
}
