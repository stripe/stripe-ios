//
//  STPAddCardViewController.swift
//  Stripe
//
//  Created by Jack Flintermann on 3/23/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import UIKit

/// This view controller contains a credit card entry form that the user can fill out. On submission, it will use the Stripe API to convert the user's card details to a Stripe token. It renders a right bar button item that submits the form, so it must be shown inside a `UINavigationController`.
public class STPAddCardViewController: STPCoreTableViewController, STPAddressViewModelDelegate,
  STPCardScannerDelegate, STPPaymentCardTextFieldDelegate, UITableViewDelegate,
  UITableViewDataSource
{

  /// A convenience initializer; equivalent to calling `init(configuration: STPPaymentConfiguration.shared, theme: STPTheme.defaultTheme)`.
  @objc
  public convenience init() {
    self.init(configuration: STPPaymentConfiguration.shared, theme: STPTheme.defaultTheme)
  }

  /// Initializes a new `STPAddCardViewController` with the provided configuration and theme. Don't forget to set the `delegate` property after initialization.
  /// - Parameters:
  ///   - configuration: The configuration to use (this determines the Stripe publishable key to use, the required billing address fields, whether or not to use SMS autofill, etc). - seealso: STPPaymentConfiguration
  ///   - theme:         The theme to use to inform the view controller's visual appearance. - seealso: STPTheme
  @objc(initWithConfiguration:theme:)
  public init(configuration: STPPaymentConfiguration, theme: STPTheme) {
    addressViewModel = STPAddressViewModel(
      requiredBillingFields: configuration.requiredBillingAddressFields,
      availableCountries: configuration.availableCountries)
    super.init(theme: theme)
    commonInit(with: configuration)
  }

  /// The view controller's delegate. This must be set before showing the view controller in order for it to work properly. - seealso: STPAddCardViewControllerDelegate
  @objc public weak var delegate: STPAddCardViewControllerDelegate?
  /// You can set this property to pre-fill any information you've already collected from your user. - seealso: STPUserInformation.h
  @objc public var prefilledInformation: STPUserInformation?

  private var _customFooterView: UIView?
  /// Provide this view controller with a footer view.
  /// When the footer view needs to be resized, it will be sent a
  /// `sizeThatFits:` call. The view should respond correctly to this method in order
  /// to be sized and positioned properly.
  @objc public var customFooterView: UIView? {
    get {
      _customFooterView
    }
    set(footerView) {
      _customFooterView = footerView
      _configureFooterView()
    }
  }

  func _configureFooterView() {
    if isViewLoaded, let footerView = _customFooterView {
      let size = footerView.sizeThatFits(
        CGSize(width: view.bounds.size.width, height: CGFloat.greatestFiniteMagnitude))
      footerView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)

      tableView?.tableFooterView = footerView
    }
  }

  /// The API Client to use to make requests.
  /// Defaults to `STPAPIClient.shared`
  @objc public var apiClient: STPAPIClient = STPAPIClient.shared

  /// Use init: or initWithConfiguration:theme:
  required init(theme: STPTheme?) {
    let configuration = STPPaymentConfiguration.shared
    addressViewModel = STPAddressViewModel(
      requiredBillingFields: configuration.requiredBillingAddressFields,
      availableCountries: configuration.availableCountries)
    super.init(theme: theme)
  }

  /// Use init: or initWithConfiguration:theme:
  required init(
    nibName nibNameOrNil: String?,
    bundle nibBundleOrNil: Bundle?
  ) {
    let configuration = STPPaymentConfiguration.shared
    addressViewModel = STPAddressViewModel(
      requiredBillingFields: configuration.requiredBillingAddressFields,
      availableCountries: configuration.availableCountries)
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  /// Use init: or initWithConfiguration:theme:
  required init?(coder aDecoder: NSCoder) {
    let configuration = STPPaymentConfiguration.shared
    addressViewModel = STPAddressViewModel(
      requiredBillingFields: configuration.requiredBillingAddressFields,
      availableCountries: configuration.availableCountries)
    super.init(coder: aDecoder)
  }

  private var _alwaysEnableDoneButton = false
  @objc var alwaysEnableDoneButton: Bool {
    get {
      _alwaysEnableDoneButton
    }
    set(alwaysEnableDoneButton) {
      if alwaysEnableDoneButton != _alwaysEnableDoneButton {
        _alwaysEnableDoneButton = alwaysEnableDoneButton
        updateDoneButton()
      }
    }
  }
  private var configuration: STPPaymentConfiguration?
  @objc var shippingAddress: STPAddress?
  private var hasUsedShippingAddress = false
  private weak var cardImageView: UIImageView?
  private var doneItem: UIBarButtonItem?
  private var cardHeaderView: STPSectionHeaderView?
  @available(iOS 13, *)
  private lazy var cardScanner: STPCardScanner? = nil
  private var scannerCell: STPCardScannerTableViewCell?

  private var _isScanning = false
  private var isScanning: Bool {
    get {
      _isScanning
    }
    set(isScanning) {
      if _isScanning == isScanning {
        return
      }
      _isScanning = isScanning

      cardHeaderView?.button?.isEnabled = !isScanning
      let indexPath = IndexPath(
        row: 0, section: STPPaymentCardSection.stpPaymentCardScannerSection.rawValue)
      tableView?.beginUpdates()
      if isScanning {
        tableView?.insertRows(at: [indexPath], with: .automatic)
      } else {
        tableView?.deleteRows(at: [indexPath], with: .automatic)
      }
      tableView?.endUpdates()
      if isScanning {
        tableView?.scrollToRow(at: indexPath, at: .middle, animated: true)
      }
      updateInputAccessoryVisiblity()
    }
  }
  private var addressHeaderView: STPSectionHeaderView?
  var paymentCell: STPPaymentCardTextFieldCell?

  private var _loading = false
  @objc var loading: Bool {
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
        cardHeaderView?.buttonHidden = true
      } else {
        stp_navigationItemProxy?.setRightBarButton(doneItem, animated: true)
        cardHeaderView?.buttonHidden = false
      }
      var cells = addressViewModel.addressCells as [UITableViewCell]

      if let paymentCell = paymentCell {
        cells.append(paymentCell)
      }
      for cell in cells {
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
  private weak var lookupActivityIndicator: STPPaymentActivityIndicatorView?
  var addressViewModel: STPAddressViewModel
  private var inputAccessoryToolbar: UIToolbar?
  private var lookupSucceeded = false
  private var scannerCompleteAnimationTimer: Timer?

  @objc(commonInitWithConfiguration:) func commonInit(with configuration: STPPaymentConfiguration) {
    STPAnalyticsClient.sharedClient.addClass(
      toProductUsageIfNecessary: STPAddCardViewController.self)

    self.configuration = configuration
    shippingAddress = nil
    hasUsedShippingAddress = false
    addressViewModel.delegate = self
    title = STPLocalizedString("Add a Card", "Title for Add a Card view")

    if #available(iOS 13.0, *) {
      cardScanner = STPCardScanner()
    }
  }

  /// :nodoc:
  @objc
  public func tableView(
    _ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath
  ) -> CGFloat {
    return 44.0
  }

  @objc override func createAndSetupViews() {
    super.createAndSetupViews()

    let doneItem = UIBarButtonItem(
      barButtonSystemItem: .done, target: self, action: #selector(nextPressed(_:)))
    self.doneItem = doneItem
    stp_navigationItemProxy?.rightBarButtonItem = doneItem
    updateDoneButton()

    stp_navigationItemProxy?.leftBarButtonItem?.accessibilityIdentifier =
      "AddCardViewControllerNavBarCancelButtonIdentifier"
    stp_navigationItemProxy?.rightBarButtonItem?.accessibilityIdentifier =
      "AddCardViewControllerNavBarDoneButtonIdentifier"

    let cardImageView = UIImageView(image: STPImageLibrary.largeCardFrontImage())
    cardImageView.contentMode = .center
    cardImageView.frame = CGRect(
      x: 0, y: 0, width: view.bounds.size.width, height: cardImageView.bounds.size.height + (57 * 2)
    )
    self.cardImageView = cardImageView
    tableView?.tableHeaderView = cardImageView

    let paymentCell = STPPaymentCardTextFieldCell(
      style: .default, reuseIdentifier: "STPAddCardViewControllerPaymentCardTextFieldCell")
    paymentCell.paymentField?.delegate = self
    if configuration?.requiredBillingAddressFields == .postalCode {
      // If postal code collection is enabled, move the postal code field into the card entry field.
      // Otherwise, this will be picked up by the billing address fields below.
      paymentCell.paymentField?.postalCodeEntryEnabled = true
    }
    self.paymentCell = paymentCell

    activityIndicator = STPPaymentActivityIndicatorView(
      frame: CGRect(x: 0, y: 0, width: 20.0, height: 20.0))

    inputAccessoryToolbar = UIToolbar.stp_inputAccessoryToolbar(
      withTarget: self, action: #selector(paymentFieldNextTapped))
    inputAccessoryToolbar?.stp_setEnabled(false)
    updateInputAccessoryVisiblity()
    tableView?.dataSource = self
    tableView?.delegate = self
    tableView?.reloadData()
    if let address = prefilledInformation?.billingAddress {
      addressViewModel.address = address
    }

    let addressHeaderView = STPSectionHeaderView()
    addressHeaderView.theme = theme
    addressHeaderView.title = STPLocalizedString(
      "Billing Address", "Title for billing address entry section")
    switch configuration?.shippingType {
    case .shipping:
      addressHeaderView.button?.setTitle(
        STPLocalizedString("Use Shipping", "Button to fill billing address from shipping address."),
        for: .normal)
    case .delivery:
      addressHeaderView.button?.setTitle(
        STPLocalizedString("Use Delivery", "Button to fill billing address from delivery address."),
        for: .normal)
    default:
      break
    }
    addressHeaderView.button?.addTarget(
      self,
      action: #selector(useShippingAddress(_:)),
      for: .touchUpInside)
    let requiredFields = configuration?.requiredBillingAddressFields ?? .none
    let needsAddress = requiredFields != .none && !addressViewModel.isValid
    let buttonVisible =
      needsAddress && shippingAddress?.containsContent(for: requiredFields) != nil
      && !hasUsedShippingAddress
    addressHeaderView.buttonHidden = !buttonVisible
    addressHeaderView.setNeedsLayout()
    self.addressHeaderView = addressHeaderView
    let cardHeaderView = STPSectionHeaderView()
    cardHeaderView.theme = theme
    cardHeaderView.title = STPLocalizedString("Card", "Title for credit card number entry field")
    cardHeaderView.buttonHidden = true
    self.cardHeaderView = cardHeaderView

    // re-set the custom footer view if it was added before we loaded
    _configureFooterView()

    view.addGestureRecognizer(
      UITapGestureRecognizer(target: self, action: #selector(endEditing)))

    setUpCardScanningIfAvailable()

    STPAnalyticsClient.sharedClient.clearAdditionalInfo()
  }

  /// :nodoc:
  @objc
  public override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    // Resetting it re-calculates the size based on new view width
    // UITableView requires us to call setter again to actually pick up frame
    // change on footers
    if tableView?.tableFooterView != nil {
      customFooterView = tableView?.tableFooterView
    }
  }

  func setUpCardScanningIfAvailable() {
    if #available(iOS 13.0, *) {
      if !STPCardScanner.cardScanningAvailable() || configuration?.cardScanningEnabled == nil {
        return
      }
      let scannerCell = STPCardScannerTableViewCell()
      self.scannerCell = scannerCell

      let cardScanner = STPCardScanner(delegate: self)
      cardScanner.cameraView = scannerCell.cameraView
      self.cardScanner = cardScanner

      cardHeaderView?.buttonHidden = false
      cardHeaderView?.button?.setTitle(
        STPLocalizedString("Scan Card", "Text for button to scan a credit card"), for: .normal)
      cardHeaderView?.button?.addTarget(self, action: #selector(scanCard), for: .touchUpInside)
      cardHeaderView?.setNeedsLayout()
    }
  }

  @objc func scanCard() {
    if #available(iOS 13.0, *) {
      view.endEditing(true)
      isScanning = true
      cardScanner?.start()
    }
  }

  @objc func endEditing() {
    view.endEditing(false)
  }

  /// :nodoc:
  @objc
  public override func updateAppearance() {
    super.updateAppearance()

    view.backgroundColor = theme.primaryBackgroundColor

    let navBarTheme = navigationController?.navigationBar.stp_theme ?? theme
    doneItem?.stp_setTheme(navBarTheme)
    tableView?.allowsSelection = false

    cardImageView?.tintColor = theme.accentColor
    activityIndicator?.tintColor = theme.accentColor

    paymentCell?.theme = theme
    cardHeaderView?.theme = theme
    addressHeaderView?.theme = theme
    for cell in addressViewModel.addressCells {
      cell.theme = theme
    }
    setNeedsStatusBarAppearanceUpdate()
  }

  /// :nodoc:
  @objc
  public override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    stp_beginObservingKeyboardAndInsettingScrollView(
      tableView, onChange: nil)
    firstEmptyField()?.becomeFirstResponder()
  }

  func firstEmptyField() -> UIResponder? {

    if paymentCell?.isEmpty != nil {
      return paymentCell!
    }

    for cell in addressViewModel.addressCells {
      if cell.contents?.count ?? 0 == 0 {
        return cell
      }
    }
    return nil
  }

  /// :nodoc:
  @objc
  public override func handleCancelTapped(_ sender: Any?) {
    delegate?.addCardViewControllerDidCancel(self)
  }

  @objc func nextPressed(_ sender: Any?) {
    loading = true
    guard let cardParams = paymentCell?.paymentField?.cardParams else {
      return
    }
    // Create and return a Payment Method
    let billingDetails = STPPaymentMethodBillingDetails()
    if configuration?.requiredBillingAddressFields == .postalCode {
      let address = STPAddress()
      address.postalCode = paymentCell?.paymentField?.postalCode
      billingDetails.address = STPPaymentMethodAddress(address: address)
    } else {
      billingDetails.address = STPPaymentMethodAddress(address: addressViewModel.address)
      billingDetails.email = addressViewModel.address.email
      billingDetails.name = addressViewModel.address.name
      billingDetails.phone = addressViewModel.address.phone
    }
    let paymentMethodParams = STPPaymentMethodParams(
      card: cardParams,
      billingDetails: billingDetails,
      metadata: nil)
    apiClient.createPaymentMethod(with: paymentMethodParams) {
      paymentMethod, createPaymentMethodError in
      if let createPaymentMethodError = createPaymentMethodError {
        self.handleError(createPaymentMethodError)
      } else {
        if let paymentMethod = paymentMethod {
          self.delegate?.addCardViewController(self, didCreatePaymentMethod: paymentMethod) {
            attachToCustomerError in
            stpDispatchToMainThreadIfNecessary({
              if let attachToCustomerError = attachToCustomerError {
                self.handleError(attachToCustomerError)
              } else {
                self.loading = false
              }
            })
          }
        }
      }
    }
  }

  func handleError(_ error: Error) {
    loading = false
    firstEmptyField()?.becomeFirstResponder()

    let alertController = UIAlertController(
      title: error.localizedDescription,
      message: (error as NSError).localizedFailureReason,
      preferredStyle: .alert)

    alertController.addAction(
      UIAlertAction(
        title: STPLocalizedString("OK", nil),
        style: .cancel,
        handler: nil))

    present(alertController, animated: true)
  }

  func updateDoneButton() {
    stp_navigationItemProxy?.rightBarButtonItem?.isEnabled =
      (paymentCell?.paymentField?.isValid ?? false && addressViewModel.isValid)
      || alwaysEnableDoneButton
  }

  func updateInputAccessoryVisiblity() {
    // The inputAccessoryToolbar switches from the paymentCell to the first address field.
    // It should only be shown when there *is* an address field. This compensates for the lack
    // of a 'Return' key on the number pad used for paymentCell entry
    let hasAddressCells = (addressViewModel.addressCells.count) > 0
    paymentCell?.inputAccessoryView = hasAddressCells ? inputAccessoryToolbar : nil
  }

  // MARK: - STPPaymentCardTextField
  @objc
  public func paymentCardTextFieldDidChange(_ textField: STPPaymentCardTextField) {
    inputAccessoryToolbar?.stp_setEnabled(textField.isValid)
    updateDoneButton()
  }

  @objc func paymentFieldNextTapped() {
    (addressViewModel.addressCells.stp_boundSafeObject(at: 0) as? UIView)?
      .becomeFirstResponder()
  }

  @objc
  public func paymentCardTextFieldWillEndEditing(forReturn textField: STPPaymentCardTextField) {
    paymentFieldNextTapped()
  }

  @objc
  public func paymentCardTextFieldDidBeginEditingCVC(_ textField: STPPaymentCardTextField) {
    let isAmex = STPCardValidator.brand(forNumber: textField.cardNumber ?? "") == .amex
    var newImage: UIImage?
    var animationTransition: UIView.AnimationOptions

    if isAmex {
      newImage = STPImageLibrary.largeCardAmexCVCImage()
      animationTransition = .transitionCrossDissolve
    } else {
      newImage = STPImageLibrary.largeCardBackImage()
      animationTransition = .transitionFlipFromRight
    }

    if let cardImageView = cardImageView {
      UIView.transition(
        with: cardImageView,
        duration: 0.2,
        options: animationTransition,
        animations: {
          self.cardImageView?.image = newImage
        })
    }
  }

  @objc
  public func paymentCardTextFieldDidEndEditingCVC(_ textField: STPPaymentCardTextField) {
    let isAmex = STPCardValidator.brand(forNumber: textField.cardNumber ?? "") == .amex
    let animationTransition: UIView.AnimationOptions =
      isAmex ? .transitionCrossDissolve : .transitionFlipFromLeft

    if let cardImageView = cardImageView {
      UIView.transition(
        with: cardImageView,
        duration: 0.2,
        options: animationTransition,
        animations: {
          self.cardImageView?.image = STPImageLibrary.largeCardFrontImage()
        })
    }
  }

  @objc
  public func paymentCardTextFieldDidBeginEditing(_ textField: STPPaymentCardTextField) {
    if #available(iOS 13.0, *) {
      cardScanner?.stop()
    }
  }

  // MARK: - STPAddressViewModelDelegate
  func addressViewModel(_ addressViewModel: STPAddressViewModel, addedCellAt index: Int) {
    let indexPath = IndexPath(
      row: index, section: STPPaymentCardSection.stpPaymentCardBillingAddressSection.rawValue)
    tableView?.insertRows(at: [indexPath], with: .automatic)
    updateInputAccessoryVisiblity()
  }

  func addressViewModel(_ addressViewModel: STPAddressViewModel, removedCellAt index: Int) {
    let indexPath = IndexPath(
      row: Int(index), section: STPPaymentCardSection.stpPaymentCardBillingAddressSection.rawValue)
    tableView?.deleteRows(at: [indexPath], with: .automatic)
    updateInputAccessoryVisiblity()
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

  // MARK: - UITableView
  /// :nodoc:
  @objc
  public func numberOfSections(in tableView: UITableView) -> Int {
    return 3
  }

  /// :nodoc:
  @objc
  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == STPPaymentCardSection.stpPaymentCardNumberSection.rawValue {
      return 1
    } else if section == STPPaymentCardSection.stpPaymentCardScannerSection.rawValue {
      return isScanning ? 1 : 0
    } else if section == STPPaymentCardSection.stpPaymentCardBillingAddressSection.rawValue {
      return addressViewModel.addressCells.count
    }
    return 0
  }

  /// :nodoc:
  @objc
  public func tableView(
    _ tableView: UITableView,
    cellForRowAt indexPath: IndexPath
  ) -> UITableViewCell {
    var cell: UITableViewCell?
    switch indexPath.section {
    case STPPaymentCardSection.stpPaymentCardNumberSection.rawValue:
      cell = paymentCell
    case STPPaymentCardSection.stpPaymentCardScannerSection.rawValue:
      cell = scannerCell
    case STPPaymentCardSection.stpPaymentCardBillingAddressSection.rawValue:
      cell =
        addressViewModel.addressCells.stp_boundSafeObject(at: indexPath.row)
        as? UITableViewCell
    default:
      return UITableViewCell()  // won't be called; exists to make the static analyzer happy
    }
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
    let bottomRow =
      self.tableView(tableView, numberOfRowsInSection: indexPath.section) - 1 == indexPath.row
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
    if self.tableView(tableView, numberOfRowsInSection: section) == 0 {
      return 0.01
    }
    return 27.0
  }

  /// :nodoc:
  @objc
  public override func tableView(
    _ tableView: UITableView, heightForHeaderInSection section: Int
  ) -> CGFloat {
    let fittingSize = CGSize(width: view.bounds.size.width, height: CGFloat.greatestFiniteMagnitude)
    let numberOfRows = self.tableView(tableView, numberOfRowsInSection: section)
    if section == STPPaymentCardSection.stpPaymentCardNumberSection.rawValue {
      return cardHeaderView?.sizeThatFits(fittingSize).height ?? 0.0
    } else if section == STPPaymentCardSection.stpPaymentCardBillingAddressSection.rawValue
      && numberOfRows != 0
    {
      return addressHeaderView?.sizeThatFits(fittingSize).height ?? 0.0
    } else if section == STPPaymentCardSection.stpPaymentCardScannerSection.rawValue {
      return 0.01
    } else if numberOfRows != 0 {
      return tableView.sectionHeaderHeight
    }
    return 0.01
  }

  /// :nodoc:
  @objc
  public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int)
    -> UIView?
  {
    if self.tableView(tableView, numberOfRowsInSection: section) == 0 {
      return UIView()
    } else {
      if section == STPPaymentCardSection.stpPaymentCardNumberSection.rawValue {
        return cardHeaderView
      } else if section == STPPaymentCardSection.stpPaymentCardBillingAddressSection.rawValue {
        return addressHeaderView
      }
    }
    return nil
  }

  /// :nodoc:
  @objc
  public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int)
    -> UIView?
  {
    return UIView()
  }

  @objc func useShippingAddress(_ sender: UIButton) {
    tableView?.beginUpdates()
    addressViewModel.address = shippingAddress ?? STPAddress()
    hasUsedShippingAddress = true
    firstEmptyField()?.becomeFirstResponder()
    UIView.animate(
      withDuration: 0.2,
      animations: {
        self.addressHeaderView?.buttonHidden = true
      })
    tableView?.endUpdates()
  }

  // MARK: - STPCardScanner
  /// :nodoc:
  @objc
  public override func viewWillTransition(
    to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator
  ) {
    super.viewWillTransition(to: size, with: coordinator)
    if #available(iOS 13.0, *) {
      let orientation = UIDevice.current.orientation
      if orientation.isPortrait || orientation.isLandscape {
        cardScanner?.deviceOrientation = orientation
      }
      if isScanning {
        let indexPath = IndexPath(
          row: 0, section: STPPaymentCardSection.stpPaymentCardScannerSection.rawValue)
        DispatchQueue.main.async(execute: {
          self.tableView?.scrollToRow(at: indexPath, at: .middle, animated: true)
        })
      }
    }
  }

  static let cardScannerKSTPCardScanAnimationTime: TimeInterval = 0.04

  @available(iOS 13, *)
  func cardScanner(
    _ scanner: STPCardScanner, didFinishWith cardParams: STPPaymentMethodCardParams?, error: Error?
  ) {
    if let error = error {
      handleError(error)
    }
    if let cardParams = cardParams {
      view.isUserInteractionEnabled = false
      paymentCell?.paymentField?.inputView = UIView() as? UIInputView
      var i = 0
      scannerCompleteAnimationTimer = Timer.scheduledTimer(
        withTimeInterval: STPAddCardViewController.cardScannerKSTPCardScanAnimationTime,
        repeats: true,
        block: { timer in
          i += 1
          let newParams = STPPaymentMethodCardParams()
          guard let number = cardParams.number else {
            timer.invalidate()
            self.view.isUserInteractionEnabled = false
            return
          }
          if i < number.count {
            newParams.number = String(number[...number.index(number.startIndex, offsetBy: i)])
          } else {
            newParams.number = number
          }
          self.paymentCell?.paymentField?.cardParams = newParams
          if i > number.count {
            self.paymentCell?.paymentField?.cardParams = cardParams
            self.isScanning = false
            self.paymentCell?.paymentField?.inputView = nil
            // Force the inputView to reload by asking the text field to resign/become first responder:
            _ = self.paymentCell?.paymentField?.resignFirstResponder()
            _ = self.paymentCell?.paymentField?.becomeFirstResponder()
            timer.invalidate()
            self.view.isUserInteractionEnabled = true
          }
        })
    } else {
      isScanning = false
    }
  }

}

/// An `STPAddCardViewControllerDelegate` is notified when an `STPAddCardViewController`
/// successfully creates a card token or is cancelled. It has internal error-handling
/// logic, so there's no error case to deal with.
@objc public protocol STPAddCardViewControllerDelegate: NSObjectProtocol {
  /// Called when the user cancels adding a card. You should dismiss (or pop) the
  /// view controller at this point.
  /// - Parameter addCardViewController: the view controller that has been cancelled
  func addCardViewControllerDidCancel(_ addCardViewController: STPAddCardViewController)

  /// This is called when the user successfully adds a card and Stripe returns a
  /// Payment Method.
  /// You should send the PaymentMethod to your backend to store it on a customer, and then
  /// call the provided `completion` block when that call is finished. If an error
  /// occurs while talking to your backend, call `completion(error)`, otherwise,
  /// dismiss (or pop) the view controller.
  /// - Parameters:
  ///   - addCardViewController: the view controller that successfully created a token
  ///   - paymentMethod:         the Payment Method that was created. - seealso: STPPaymentMethod
  ///   - completion:            call this callback when you're done sending the token to your backend
  @objc func addCardViewController(
    _ addCardViewController: STPAddCardViewController,
    didCreatePaymentMethod paymentMethod: STPPaymentMethod,
    completion: @escaping STPErrorBlock
  )

  // MARK: - Deprecated

  /// This method is deprecated as of v16.0.0 (https://github.com/stripe/stripe-ios/blob/master/MIGRATING.md#migrating-from-versions--1600).
  /// To use this class, migrate your integration from Charges to PaymentIntents. See https://stripe.com/docs/payments/payment-intents/migration/charges#read
  @available(*, deprecated, message: "Use addCardViewController(_:didCreatePaymentMethod:completion:) instead and migrate your integration to PaymentIntents. See https://stripe.com/docs/payments/payment-intents/migration/charges#read",  renamed: "addCardViewController(_:didCreatePaymentMethod:completion:)")
  @objc optional func addCardViewController(
    _ addCardViewController: STPAddCardViewController,
    didCreateToken token: STPToken,
    completion: STPErrorBlock
  )
  /// This method is deprecated as of v16.0.0 (https://github.com/stripe/stripe-ios/blob/master/MIGRATING.md#migrating-from-versions--1600).
  /// To use this class, migrate your integration from Charges to PaymentIntents. See https://stripe.com/docs/payments/payment-intents/migration/charges#read
  @available(*, deprecated, message: "Use addCardViewController(_:didCreatePaymentMethod:completion:) instead and migrate your integration to PaymentIntents. See https://stripe.com/docs/payments/payment-intents/migration/charges#read",  renamed: "addCardViewController(_:didCreatePaymentMethod:completion:)")
  @objc optional func addCardViewController(
    _ addCardViewController: STPAddCardViewController,
    didCreateSource source: STPSource,
    completion: STPErrorBlock
  )
}

private let STPPaymentCardCellReuseIdentifier = "STPPaymentCardCellReuseIdentifier"
enum STPPaymentCardSection: Int {
  case stpPaymentCardNumberSection = 0
  case stpPaymentCardScannerSection = 1
  case stpPaymentCardBillingAddressSection = 2
}
