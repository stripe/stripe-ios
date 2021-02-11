//
//  STPPaymentCardTextField.swift
//  Stripe
//
//  Created by Jack Flintermann on 7/16/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

import UIKit

/// STPPaymentCardTextField is a text field with similar properties to UITextField,
/// but specialized for collectplaceholing credit/debit card information. It manages
/// multiple UITextFields under the hood to collect this information. It's
/// designed to fit on a single line, and from a design perspective can be used
/// anywhere a UITextField would be appropriate.
@IBDesignable
public class STPPaymentCardTextField: UIControl, UIKeyInput, STPFormTextFieldDelegate {
  /// :nodoc:
  @objc
  public func textField(
    _ textField: UITextField, shouldChangeCharactersIn range: NSRange,
    replacementString string: String
  ) -> Bool {
    if let textField = textField as? STPFormTextField, let delegateProxy = textField.delegateProxy {
      return delegateProxy.textField(
        textField, shouldChangeCharactersIn: range, replacementString: string)
    }
    return true
  }

  private var metadataLoadingIndicator: STPCardLoadingIndicator?

  /// - seealso: STPPaymentCardTextFieldDelegate
  @IBOutlet public weak var delegate: STPPaymentCardTextFieldDelegate?
  /// The font used in each child field. Default is `UIFont.systemFont(ofSize:18)`.
  @objc public var font: UIFont = UIFont.systemFont(ofSize: 18) {
    didSet {
      for field in allFields {
        field.font = font
      }

      sizingField.font = font
      clearSizingCache()

      setNeedsLayout()
    }
  }

  /// The text color to be used when entering valid text. Default is `.label`.
  @objc public var textColor: UIColor = {
    if #available(iOS 13.0, *) {
      return .label
    }
    return .black
  }()
  {
    didSet {
      for field in allFields {
        field.defaultColor = textColor
      }
    }
  }

  /// The text color to be used when the user has entered invalid information,
  /// such as an invalid card number.
  /// Default is `.red`.
  @objc public var textErrorColor: UIColor = {
    if #available(iOS 13.0, *) {
      return .systemRed
    }
    return .red
  }()
  {
    didSet {
      for field in allFields {
        field.errorColor = textErrorColor
      }
    }
  }

  /// The text placeholder color used in each child field.
  /// This will also set the color of the card placeholder icon.
  /// Default is `.systemGray2`.
  @objc public var placeholderColor: UIColor = placeholderGrayColor {
    didSet {
      brandImageView.tintColor = placeholderColor

      for field in allFields {
        field.placeholderColor = placeholderColor
      }
    }
  }

  @IBInspectable private var _numberPlaceholder: String?
  /// The placeholder for the card number field.
  /// Default is "4242424242424242".
  /// If this is set to something that resembles a card number, it will automatically
  /// format it as such (in other words, you don't need to add spaces to this string).
  @IBInspectable public var numberPlaceholder: String? {
    get {
      _numberPlaceholder
    }
    set(numberPlaceholder) {
      _numberPlaceholder = numberPlaceholder
      numberField.placeholder = _numberPlaceholder
    }
  }

  @IBInspectable private var _expirationPlaceholder: String?
  /// The placeholder for the expiration field. Defaults to "MM/YY".
  @IBInspectable public var expirationPlaceholder: String? {
    get {
      _expirationPlaceholder
    }
    set(expirationPlaceholder) {
      _expirationPlaceholder = expirationPlaceholder
      expirationField.placeholder = _expirationPlaceholder
    }
  }

  @IBInspectable private var _cvcPlaceholder: String?
  /// The placeholder for the cvc field. Defaults to "CVC".
  @IBInspectable public var cvcPlaceholder: String? {
    get {
      _cvcPlaceholder
    }
    set(cvcPlaceholder) {
      _cvcPlaceholder = cvcPlaceholder
      cvcField.placeholder = _cvcPlaceholder
    }
  }

  @IBInspectable private var _postalCodePlaceholder: String?
  /// The placeholder for the postal code field. Defaults to "ZIP" for United States
  /// or @"Postal" for all other country codes.
  @IBInspectable public var postalCodePlaceholder: String? {
    get {
      _postalCodePlaceholder
    }
    set(postalCodePlaceholder) {
      _postalCodePlaceholder = postalCodePlaceholder
      updatePostalFieldPlaceholder()
    }
  }
  /// The cursor color for the field.
  /// This is a proxy for the view's tintColor property, exposed for clarity only
  /// (in other words, calling setCursorColor is identical to calling setTintColor).
  @objc public var cursorColor: UIColor {
    get {
      tintColor
    }
    set {
      self.tintColor = newValue
    }
  }

  var _borderColor: UIColor? = placeholderGrayColor
  /// The border color for the field.
  /// Can be nil (in which case no border will be drawn).
  /// Default is .systemGray2.
  @objc public var borderColor: UIColor? {
    get {
      _borderColor
    }
    set {
      _borderColor = newValue
      if let borderColor = newValue {
        self.layer.borderColor = (borderColor.copy() as! UIColor).cgColor
      } else {
        self.layer.borderColor = UIColor.clear.cgColor
      }
    }
  }

  var _borderWidth: CGFloat = 1.0
  /// The width of the field's border.
  /// Default is 1.0.
  @objc public var borderWidth: CGFloat {
    get {
      _borderWidth
    }
    set {
      _borderWidth = newValue
      layer.borderWidth = borderWidth
    }
  }

  var _cornerRadius: CGFloat = 5.0
  /// The corner radius for the field's border.
  /// Default is 5.0.
  @objc public var cornerRadius: CGFloat {
    get {
      _cornerRadius
    }
    set {
      _cornerRadius = cornerRadius
      layer.cornerRadius = newValue
    }
  }

  /// The keyboard appearance for the field.
  /// Default is UIKeyboardAppearanceDefault.
  @objc public var keyboardAppearance: UIKeyboardAppearance = .default {
    didSet {
      for field in allFields {
        field.keyboardAppearance = keyboardAppearance
      }
    }
  }

  private var _inputView: UIView?
  /// This behaves identically to setting the inputView for each child text field.
  @objc public override var inputView: UIView? {
    get {
      _inputView
    }
    set(inputView) {
      _inputView = inputView

      for field in allFields {
        field.inputView = inputView
      }
    }
  }

  private var _inputAccessoryView: UIView?
  /// This behaves identically to setting the inputAccessoryView for each child text field.
  @objc public override var inputAccessoryView: UIView? {
    get {
      _inputAccessoryView
    }
    set(inputAccessoryView) {
      _inputAccessoryView = inputAccessoryView

      for field in allFields {
        field.inputAccessoryView = inputAccessoryView
      }
    }
  }
  /// The curent brand image displayed in the receiver.
  @objc public private(set) var brandImage: UIImage?
  /// Whether or not the form currently contains a valid card number,
  /// expiration date, CVC, and postal code (if required).
  /// - seealso: STPCardValidator

  @objc dynamic public var isValid: Bool {
    return viewModel.isValid
  }
  /// Enable/disable selecting or editing the field. Useful when submitting card details to Stripe.

  @objc public override var isEnabled: Bool {
    get {
      super.isEnabled
    }
    set(enabled) {
      super.isEnabled = enabled
      for textField in allFields {
        textField.isEnabled = enabled
      }
    }
  }
  /// The current card number displayed by the field.
  /// May or may not be valid, unless `isValid` is true, in which case it is guaranteed
  /// to be valid.
  @objc public var cardNumber: String? {
    return viewModel.cardNumber
  }
  /// The current expiration month displayed by the field (1 = January, etc).
  /// May or may not be valid, unless `isValid` is true, in which case it is
  /// guaranteed to be valid.
  @objc public var expirationMonth: Int {
    if let monthString = viewModel.expirationMonth, let month = Int(monthString) {
      return month
    }
    return 0
  }
  /// The current expiration month displayed by the field, as a string. T
  /// This may or may not be a valid entry (i.e. "0") unless `isValid` is true.
  /// It may be also 0-prefixed (i.e. "01" for January).
  @objc public var formattedExpirationMonth: String? {
    return viewModel.expirationMonth
  }
  /// The current expiration year displayed by the field, modulo 100
  /// (e.g. the year 2015 will be represented as 15).
  /// May or may not be valid, unless `isValid` is true, in which case it is
  /// guaranteed to be valid.

  @objc public var expirationYear: Int {
    if let yearString = viewModel.expirationYear, let year = Int(yearString) {
      return year
    }
    return 0
  }
  /// The current expiration year displayed by the field, as a string.
  /// This is a 2-digit year (i.e. "15"), and may or may not be a valid entry
  /// unless `isValid` is true.

  @objc public var formattedExpirationYear: String? {
    return viewModel.expirationYear
  }
  /// The current card CVC displayed by the field.
  /// May or may not be valid, unless `isValid` is true, in which case it
  /// is guaranteed to be valid.

  @objc public var cvc: String? {
    return viewModel.cvc
  }
  
  /// The current card ZIP or postal code displayed by the field.
  @objc public var postalCode: String? {
    get {
      if postalCodeEntryEnabled {
        return viewModel.postalCode
      } else {
        return nil
      }
    }
    set {
      if postalCodeEntryEnabled {
        if (newValue != postalCode) {
          setText(newValue, inField: .postalCode)
        }
      }
    }
  }
  /// Controls if a postal code entry field can be displayed to the user.
  /// Default is YES.
  /// If YES, the type of code entry shown is controlled by the set `countryCode`
  /// value. Some country codes may result in no postal code entry being shown if
  /// those countries do not commonly use postal codes.
  /// If NO, no postal code entry will ever be displayed.
  @objc public var postalCodeEntryEnabled: Bool {
    get {
      return viewModel.postalCodeRequired
    }
    set(postalCodeEntryEnabled) {
      viewModel.postalCodeRequested = postalCodeEntryEnabled
    }
  }
  /// The two-letter ISO country code that corresponds to the user's billing address.
  /// If `postalCodeEntryEnabled` is YES, this controls which type of entry is allowed.
  /// If `postalCodeEntryEnabled` is NO, this property currently has no effect.
  /// If set to nil and postal code entry is enabled, the country from the user's current
  /// locale will be filled in. Otherwise the specific country code set will be used.
  /// By default this will fetch the user's current country code from NSLocale.

  @objc public var countryCode: String? {
    get {
      return viewModel.postalCodeCountryCode
    }
    set(cCode) {
      if (viewModel.postalCodeCountryCode == cCode) {
        return
      }
      let countryCode = (cCode ?? Locale.autoupdatingCurrent.regionCode)
      viewModel.postalCodeCountryCode = countryCode
      updatePostalFieldPlaceholder()

      // This will revalidate and reformat
      setText(postalCode, inField: .postalCode)
    }
  }
  /// Convenience property for creating an `STPPaymentMethodCardParams` from the currently entered information
  /// or programmatically setting the field's contents. For example, if you're using another library
  /// to scan your user's credit card with a camera, you can assemble that data into an `STPPaymentMethodCardParams`
  /// object and set this property to that object to prefill the fields you've collected.
  /// Accessing this property returns a *copied* `cardParams`. The only way to change properties in this
  /// object is to make changes to a `STPPaymentMethodCardParams` you own (retrieved from this text field if desired),
  /// and then set this property to the new value.

  @objc public var cardParams: STPPaymentMethodCardParams {
    get {
      let newParams = internalCardParams.copy() as! STPPaymentMethodCardParams
      newParams.number = cardNumber
      if let monthString = viewModel.expirationMonth, let month = Int(monthString) {
        newParams.expMonth = NSNumber(value: month)
      }
      if let yearString = viewModel.expirationYear, let year = Int(yearString) {
        newParams.expYear = NSNumber(value: year)
      }
      newParams.cvc = cvc
      internalCardParams = newParams
      return internalCardParams
    }
    set(callersCardParams) {
      if (callersCardParams.isEqual(self.cardParams)) {
        // These are identical card params: Don't take any action.
        return
      }
      /*
                 Due to the way this class is written, programmatically setting field text
                 behaves identically to user entering text (and will have the same forwarding
                 on to next responder logic).

                 We have some custom logic here in the main accesible programmatic setter
                 to dance around this a bit. First we save what is the current responder
                 at the time this method was called. Later logic after text setting should be:
                 1. If we were not first responder, we should still not be first responder
                    (but layout might need updating depending on PAN validity)
                 2. If original field is still not valid, it is still first responder
                    (manually reset it back to first responder)
                 3. Otherwise the first subfield with invalid text should now be first responder
                 */
      let originalSubResponder = currentFirstResponderField()

      /*
                 #1031 small footgun hiding here. Use copies to protect from mutations of
                 `internalCardParams` in the `cardParams` property accessor and any mutations
                 the app code might make to their `callersCardParams` object.
                 */
      let desiredCardParams = callersCardParams.copy() as! STPPaymentMethodCardParams
      internalCardParams = desiredCardParams.copy() as! STPPaymentMethodCardParams

      setText(desiredCardParams.number, inField: .number)
      let expirationPresent = desiredCardParams.expMonth != nil && desiredCardParams.expYear != nil
      if expirationPresent {
        let text = String(
          format: "%02lu%02lu", UInt(desiredCardParams.expMonth?.intValue ?? 0),
          UInt(desiredCardParams.expYear?.intValue ?? 0) % 100)
        setText(text, inField: .expiration)
      } else {
        setText("", inField: .expiration)
      }
      setText(desiredCardParams.cvc, inField: .CVC)

      if isFirstResponder {
        var fieldType = STPCardFieldType.number
        if let originalSubResponderTag = originalSubResponder?.tag,
          let lastFieldType = STPCardFieldType(rawValue: originalSubResponderTag)
        {
          fieldType = lastFieldType
        }
        var state: STPCardValidationState = .incomplete

        switch fieldType {
        case .number:
          state =
            viewModel.hasCompleteMetadataForCardNumber
            ? STPCardValidator.validationState(
              forNumber: viewModel.cardNumber ?? "", validatingCardBrand: true) : .incomplete
        case .expiration:
          state = viewModel.validationStateForExpiration()
        case .CVC:
          state = viewModel.validationStateForCVC()
        case .postalCode:
          state = viewModel.validationStateForPostalCode()
        }

        if state == .valid {
          let nextField = _firstInvalidAutoAdvanceField()
          if let nextField = nextField {
            nextField.becomeFirstResponder()
          } else {
            resignFirstResponder()
          }
        } else {
          originalSubResponder?.becomeFirstResponder()
        }
      } else {
        layoutViews(
          toFocus: nil,
          becomeFirstResponder: true,
          animated: false, completion: nil)
      }

      // update the card image, falling back to the number field image if not editing
      if expirationField.isFirstResponder {
        updateImage(for: .expiration)
      } else if cvcField.isFirstResponder {
        updateImage(for: .CVC)
      } else {
        updateImage(for: .number)
      }
      updateCVCPlaceholder()
    }
  }

  /// Causes the text field to begin editing. Presents the keyboard.
  /// - Returns: Whether or not the text field successfully began editing.
  /// - seealso: UIResponder
  @objc @discardableResult public override func becomeFirstResponder() -> Bool {
    let firstResponder = currentFirstResponderField() ?? nextFirstResponderField()
    return firstResponder.becomeFirstResponder()
  }

  /// Causes the text field to stop editing. Dismisses the keyboard.
  /// - Returns: Whether or not the field successfully stopped editing.
  /// - seealso: UIResponder
  @discardableResult public override func resignFirstResponder() -> Bool {
    super.resignFirstResponder()
    let success = currentFirstResponderField()?.resignFirstResponder() ?? false
    layoutViews(
      toFocus: nil,
      becomeFirstResponder: false,
      animated: true, completion: nil)
    updateImage(for: .number)
    return success
  }

  /// Resets all of the contents of all of the fields. If the field is currently being edited, the number field will become selected.
  @objc public func clear() {
    for field in allFields {
      field.text = ""
    }
    viewModel = STPPaymentCardTextFieldViewModel()
    onChange()
    updateImage(for: .number)
    updateCVCPlaceholder()
    weak var weakSelf = self
    layoutViews(
      toFocus: NSNumber(value: STPCardFieldType.postalCode.rawValue),
      becomeFirstResponder: true,
      animated: true
    ) { _ in
      guard let strongSelf = weakSelf else {
        return
      }
      if strongSelf.isFirstResponder {
        strongSelf.numberField.becomeFirstResponder()
      }
    }
  }

  /// Returns the cvc image used for a card brand.
  /// Override this method in a subclass if you would like to provide custom images.
  /// - Parameter cardBrand: The brand of card entered.
  /// - Returns: The cvc image used for a card brand.
  @objc(cvcImageForCardBrand:) public class func cvcImage(for cardBrand: STPCardBrand) -> UIImage? {
    return STPImageLibrary.cvcImage(for: cardBrand)
  }

  /// Returns the brand image used for a card brand.
  /// Override this method in a subclass if you would like to provide custom images.
  /// - Parameter cardBrand: The brand of card entered.
  /// - Returns: The brand image used for a card brand.
  @objc(brandImageForCardBrand:) public class func brandImage(for cardBrand: STPCardBrand)
    -> UIImage?
  {
    return STPImageLibrary.cardBrandImage(for: cardBrand)
  }

  /// Returns the error image used for a card brand.
  /// Override this method in a subclass if you would like to provide custom images.
  /// - Parameter cardBrand: The brand of card entered.
  /// - Returns: The error image used for a card brand.
  @objc(errorImageForCardBrand:) public class func errorImage(for cardBrand: STPCardBrand)
    -> UIImage?
  {
    return STPImageLibrary.errorImage(for: cardBrand)
  }

  /// Returns the rectangle in which the receiver draws its brand image.
  /// - Parameter bounds: The bounding rectangle of the receiver.
  /// - Returns: the rectangle in which the receiver draws its brand image.
  @objc(brandImageRectForBounds:) public func brandImageRect(forBounds bounds: CGRect) -> CGRect {
    let height = CGFloat(min(bounds.size.height, brandImageView.image?.size.height ?? 0))
    // the -1 to y here helps the image actually be centered
    return CGRect(
      x: STPPaymentCardTextFieldDefaultPadding, y: 0.5 * bounds.size.height - 0.5 * height - 1,
      width: brandImageView.image?.size.width ?? 0.0, height: height)
  }

  /// Returns the rectangle in which the receiver draws the text fields.
  /// - Parameter bounds: The bounding rectangle of the receiver.
  /// - Returns: The rectangle in which the receiver draws the text fields.
  @objc(fieldsRectForBounds:) public func fieldsRect(forBounds bounds: CGRect) -> CGRect {
    let brandImageRect = self.brandImageRect(forBounds: bounds)
    return CGRect(
      x: brandImageRect.maxX, y: 0, width: bounds.width - brandImageRect.maxX, height: bounds.height
    )
  }

  @objc internal lazy var brandImageView: UIImageView = UIImageView(
    image: STPPaymentCardTextField.brandImage(for: .unknown))
  @objc internal lazy var fieldsView: UIView = UIView()
  @objc internal lazy var numberField = STPFormTextField()
  @objc internal lazy var expirationField = STPFormTextField()
  @objc internal lazy var cvcField = STPFormTextField()
  @objc internal lazy var postalCodeField = STPFormTextField()

  @objc private lazy var viewModel: STPPaymentCardTextFieldViewModel =
    STPPaymentCardTextFieldViewModel()

  @objc internal var internalCardParams = STPPaymentMethodCardParams()
  @objc internal var allFields: [STPFormTextField] = []
  private lazy var sizingField = STPFormTextField()
  private lazy var sizingLabel = UILabel()
  /*
     These track the input parameters to the brand image setter so that we can
     later perform proper transition animations when new values are set
     */
  private var currentBrandImageFieldType: STPCardFieldType = .number
  private var currentBrandImageBrand: STPCardBrand = .unknown
  /// This is a number-wrapped STPCardFieldType (or nil) that layout uses
  /// to determine how it should move/animate its subviews so that the chosen
  /// text field is fully visible.
  @objc internal var focusedTextFieldForLayout: NSNumber?
  /*
     Creating and measuring the size of attributed strings is expensive so
     cache the values here.
     */
  private var textToWidthCache: [String: NSNumber] = [:]
  private var numberToWidthCache: [String: NSNumber] = [:]
  /// These bits lets us track beginEditing and endEditing for payment text field
  /// as a whole (instead of on a per-subview basis).
  /// DO NOT read this values directly. Use the return value from
  /// `getAndUpdateSubviewEditingTransitionStateFromCall:` which updates them all
  /// and returns you the correct current state for the method you are in.
  /// The state transitons in the should/did begin/end editing callbacks for all
  /// our subfields. If we get a shouldEnd AND a shouldBegin before getting either's
  /// matching didEnd/didBegin, then we are transitioning focus between our subviews
  /// (and so we ourselves should not consider us to have begun or ended editing).
  /// But if we get a should and did called on their own without a matching opposite
  /// pair (shouldBegin/didBegin or shouldEnd/didEnd) then we are transitioning
  /// into/out of our subviews from/to outside of ourselves
  private var isMidSubviewEditingTransitionInternal = false
  private var receivedUnmatchedShouldBeginEditing = false
  private var receivedUnmatchedShouldEndEditing = false

  let STPPaymentCardTextFieldDefaultPadding: CGFloat = 13

  let STPPaymentCardTextFieldDefaultInsets: CGFloat = 13

  let STPPaymentCardTextFieldMinimumPadding: CGFloat = 10

  // MARK: initializers
  /// :nodoc:
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }

  /// :nodoc:
  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  func commonInit() {
    STPAnalyticsClient.sharedClient.addClass(
      toProductUsageIfNecessary: STPPaymentCardTextField.self)

    // We're using ivars here because UIAppearance tracks when setters are
    // called, and won't override properties that have already been customized
    layer.borderColor = _borderColor?.cgColor
    layer.cornerRadius = _cornerRadius
    layer.borderWidth = _borderWidth

    clipsToBounds = true

    sizingField = build()
    sizingField.formDelegate = nil
    sizingLabel = UILabel()

    brandImageView.contentMode = .center
    brandImageView.backgroundColor = UIColor.clear
    brandImageView.tintColor = placeholderColor

    let numberField = build()
    // This does not offer quick-type suggestions (as iOS 11.2), but does pick
    // the best keyboard (maybe other, hidden behavior?)
    numberField.textContentType = .creditCardNumber
    numberField.autoFormattingBehavior = .cardNumbers
    numberField.tag = STPCardFieldType.number.rawValue
    numberField.accessibilityLabel = STPLocalizedString(
      "card number", "accessibility label for text field")
    self.numberField = numberField
    numberPlaceholder = viewModel.defaultPlaceholder()

    let expirationField = build()
    expirationField.autoFormattingBehavior = .expiration
    expirationField.tag = STPCardFieldType.expiration.rawValue
    expirationField.alpha = 0
    expirationField.isAccessibilityElement = false
    expirationField.accessibilityLabel = STPLocalizedString(
      "expiration date", "accessibility label for text field")
    self.expirationField = expirationField
    expirationPlaceholder = STPLocalizedString("MM/YY", "label for text field to enter card expiry")

    let cvcField = build()
    cvcField.tag = STPCardFieldType.CVC.rawValue
    cvcField.alpha = 0
    cvcField.isAccessibilityElement = false
    self.cvcField = cvcField
    cvcPlaceholder = nil
    self.cvcField.accessibilityLabel = defaultCVCPlaceholder()

    let postalCodeField = build()
    postalCodeField.textContentType = .postalCode
    postalCodeField.tag = STPCardFieldType.postalCode.rawValue
    postalCodeField.alpha = 0
    postalCodeField.isAccessibilityElement = false
    postalCodeField.keyboardType = .numbersAndPunctuation
    self.postalCodeField = postalCodeField
    // Placeholder is set by country code setter

    fieldsView.clipsToBounds = true
    fieldsView.backgroundColor = UIColor.clear

    allFields = [numberField, expirationField, cvcField, postalCodeField].compactMap { $0 }

    addSubview(self.fieldsView)
    for field in allFields {
      self.fieldsView.addSubview(field)
    }

    addSubview(brandImageView)
    // On small screens, the number field fits ~4 numbers, and the brandImage is just as large.
    // Previously, taps on the brand image would *dismiss* the keyboard. Make it move to the numberField instead
    brandImageView.isUserInteractionEnabled = true
    brandImageView.addGestureRecognizer(
      UITapGestureRecognizer(
        target: numberField,
        action: #selector(UIResponder.becomeFirstResponder)))

    focusedTextFieldForLayout = nil
    updateCVCPlaceholder()
    resetSubviewEditingTransitionState()

    viewModel.postalCodeRequested = true
    countryCode = Locale.autoupdatingCurrent.regionCode
  }

  // MARK: appearance properties
  func clearSizingCache() {
    textToWidthCache = [:]
    numberToWidthCache = [:]
  }

  static let placeholderGrayColor: UIColor = {
    if #available(iOS 13.0, *) {
      return .systemGray2
    }
    return .lightGray
  }()

  /// :nodoc:
  @objc public override var backgroundColor: UIColor? {
    get {
      var defaultColor = UIColor.white
      if #available(iOS 13.0, *) {
        defaultColor = UIColor.systemBackground
      }

      return super.backgroundColor ?? defaultColor
    }
    set {
      super.backgroundColor = newValue
      self.numberField.backgroundColor = newValue
    }
  }

  /// :nodoc:
  @objc public override var contentVerticalAlignment: UIControl.ContentVerticalAlignment {
    get {
      return super.contentVerticalAlignment
    }
    set(contentVerticalAlignment) {
      super.contentVerticalAlignment = contentVerticalAlignment
      for field in allFields {
        field.contentVerticalAlignment = contentVerticalAlignment
      }
      switch contentVerticalAlignment {
      case .center:
        brandImageView.contentMode = .center
      case .bottom:
        brandImageView.contentMode = .bottom
      case .fill:
        brandImageView.contentMode = .top
      case .top:
        brandImageView.contentMode = .top
      @unknown default:
        break
      }
    }
  }

  func updatePostalFieldPlaceholder() {
    if postalCodePlaceholder == nil {
      postalCodeField.placeholder = defaultPostalFieldPlaceholder(forCountryCode: countryCode)
    } else {
      postalCodeField.placeholder = postalCodePlaceholder
    }
  }

  func defaultPostalFieldPlaceholder(forCountryCode countryCode: String?) -> String? {
    if countryCode?.uppercased() == "US" {
      return STPLocalizedString("ZIP", "Short string for zip code (United States only)")
    } else {
      return STPLocalizedString(
        "Postal", "Short string for postal code (text used in non-US countries)")
    }
  }

  // MARK: UIControl

  // MARK: UIResponder & related methods
  /// :nodoc:
  @objc public override var isFirstResponder: Bool {
    return currentFirstResponderField() != nil
  }

  /// :nodoc:
  @objc public override var canBecomeFirstResponder: Bool {
    let firstResponder = currentFirstResponderField() ?? nextFirstResponderField()
    return firstResponder.canBecomeFirstResponder
  }

  /// Returns the next text field to be edited, in priority order:
  /// 1. If we're currently in a text field, returns the next one (ignoring postalCodeField if postalCodeEntryEnabled == NO)
  /// 2. Otherwise, returns the first invalid field (either cycling back from the end or as it gains 1st responder)
  /// 3. As a final fallback, just returns the last field
  func nextFirstResponderField() -> STPFormTextField {
    let currentFirstResponder = currentFirstResponderField()
    if let currentFirstResponder = currentFirstResponder {
      let index = allFields.firstIndex(of: currentFirstResponder) ?? NSNotFound
      if index != NSNotFound {
        let nextField =
          allFields.stp_boundSafeObject(at: index + 1) as? STPFormTextField
        if nextField != nil && (postalCodeEntryEnabled || nextField != postalCodeField) {
          return nextField!
        }
      }
    }

    if (numberField.text?.count ?? 0) == 0 {
      return numberField
    }

    return _firstInvalidAutoAdvanceField() ?? lastSubField()
  }

  func _firstInvalidAutoAdvanceField() -> STPFormTextField? {
    if viewModel.validationStateForExpiration() != .valid {
      return expirationField
    } else if viewModel.validationStateForCVC() != .valid {
      return cvcField
    } else if postalCodeEntryEnabled && viewModel.validationStateForPostalCode() != .valid {
      return postalCodeField
    } else {
      return nil
    }
  }

  func lastSubField() -> STPFormTextField {
    return (postalCodeEntryEnabled ? postalCodeField : cvcField)
  }

  @objc func currentFirstResponderField() -> STPFormTextField? {
    for textField in allFields {
      if textField.isFirstResponder {
        return textField
      }
    }
    return nil
  }

  /// :nodoc:
  @objc public override var canResignFirstResponder: Bool {
    return currentFirstResponderField()?.canResignFirstResponder ?? false
  }

  func previousField() -> STPFormTextField? {
    let currentSubResponder = currentFirstResponderField()
    if let currentSubResponder = currentSubResponder {
      let index = allFields.firstIndex(of: currentSubResponder) ?? NSNotFound
      if index != NSNotFound && index > 0 {
        return allFields[index - 1]
      }
    }
    return nil
  }

  // MARK: public convenience methods

  @objc func valid() -> Bool {
    return isValid
  }

  // MARK: readonly variables

  func setText(_ text: String?, inField field: STPCardFieldType) {
    let nonNilText = text ?? ""
    var textField: STPFormTextField?
    switch field {
    case .number:
      textField = numberField
    case .expiration:
      textField = expirationField
    case .CVC:
      textField = cvcField
    case .postalCode:
      textField = postalCodeField
    }
    textField?.text = nonNilText
  }

  func numberFullWidth() -> CGFloat {
    return CGFloat(
      max(
        width(forCardNumber: viewModel.cardNumber),
        width(forCardNumber: viewModel.defaultPlaceholder())))
  }

  func numberCompressedWidth() -> CGFloat {

    var cardNumber = self.cardNumber
    if (cardNumber?.count ?? 0) == 0 {
      cardNumber = viewModel.defaultPlaceholder()
    }

    let currentBrand = STPCardValidator.brand(forNumber: cardNumber ?? "")
    let sortedCardNumberFormat =
      (STPCardValidator.cardNumberFormat(forCardNumber: cardNumber ?? "") as NSArray).sortedArray(
        using: #selector(getter:NSNumber.uintValue)) as! [NSNumber]
    let fragmentLength = STPCardValidator.fragmentLength(for: currentBrand)
    let maxLength: Int = max(Int(fragmentLength), sortedCardNumberFormat.last!.intValue)

    let maxCompressedString = "".padding(toLength: maxLength, withPad: "8", startingAt: 0)
    return width(forText: maxCompressedString)
  }

  func cvcFieldWidth() -> CGFloat {
    if focusedTextFieldForLayout != NSNumber(value: STPCardFieldType.CVC.rawValue) && viewModel.validationStateForCVC() == .valid {
      // If we're not focused and have valid text, size exactly to what is entered
      return width(forText: viewModel.cvc)
    } else {
      // Otherwise size to fit our placeholder or what is likely to be the
      // largest possible string enterable (whichever is larger)
      let maxCvcLength = Int(STPCardValidator.maxCVCLength(for: viewModel.brand))
      var longestCvc = "888"
      if maxCvcLength == 4 {
        longestCvc = "8888"
      }

      return CGFloat(max(width(forText: cvcField.placeholder), width(forText: longestCvc)))
    }
  }

  func expirationFieldWidth() -> CGFloat {
    if focusedTextFieldForLayout == nil && viewModel.validationStateForExpiration() == .valid {
      // If we're not focused and have valid text, size exactly to what is entered
      return width(forText: viewModel.rawExpiration)
    } else {
      // Otherwise size to fit our placeholder or what is likely to be the
      // largest possible string enterable (whichever is larger)
      return CGFloat(max(width(forText: expirationField.placeholder), width(forText: "88/88")))
    }
  }

  func postalCodeFieldFullWidth() -> CGFloat {
    let compressedWidth = postalCodeFieldCompressedWidth()
    let currentTextWidth = width(forText: viewModel.postalCode)

    if currentTextWidth <= compressedWidth {
      return compressedWidth
    } else if countryCode?.uppercased() == "US" {
      // This format matches ZIP+4 which is currently disabled since it is
      // not used for billing, but could be useful for future shipping addr purposes
      return width(forText: "88888-8888 ")
    } else {
      // This format more closely matches the typical max UK/Canadian size which is our most common non-US market currently
      return width(forText: "888 8888 ")
    }
  }

  func postalCodeFieldCompressedWidth() -> CGFloat {
    var maxTextWidth: CGFloat = 0
    if countryCode?.uppercased() == "US" {
      // The QuickType ZIP suggestion adds a space at the end, so we will too for calculating our bounds
      maxTextWidth = width(forText: "88888 ")
    } else {
      // This format more closely matches the typical max UK/Canadian size which is our most common non-US market currently
      maxTextWidth = width(forText: "888 8888 ")
    }

    let placeholderWidth = width(
      forText: defaultPostalFieldPlaceholder(forCountryCode: countryCode))
    return CGFloat(max(maxTextWidth, placeholderWidth))
  }

  /// :nodoc:
  @objc public override var intrinsicContentSize: CGSize {

    let imageSize = brandImageView.image?.size

    sizingField.text = viewModel.defaultPlaceholder()
    sizingField.sizeToFit()
    let textHeight = sizingField.frame.height
    let imageHeight = (imageSize?.height ?? 0.0) + (STPPaymentCardTextFieldDefaultInsets)
    let height = ceil(CGFloat((max(max(imageHeight, textHeight), 44))))

    var width =
      STPPaymentCardTextFieldDefaultInsets + (imageSize?.width ?? 0.0)
      + STPPaymentCardTextFieldDefaultInsets + numberFullWidth()
      + STPPaymentCardTextFieldDefaultInsets

    width = ceil(width)

    return CGSize(width: width, height: height)
  }

  enum STPCardTextFieldState: Int {
    case visible
    case compressed
    case hidden
  }

  func minimumPaddingForViews(
    withWidth width: CGFloat,
    pan panVisibility: STPCardTextFieldState,
    expiry expiryVisibility: STPCardTextFieldState,
    cvc cvcVisibility: STPCardTextFieldState,
    postal postalVisibility: STPCardTextFieldState
  ) -> CGFloat {

    var requiredWidth: CGFloat = 0
    var paddingsRequired: CGFloat = -1

    if panVisibility != .hidden {
      paddingsRequired += 1
      requiredWidth += (panVisibility == .compressed) ? numberCompressedWidth() : numberFullWidth()
    }

    if expiryVisibility != .hidden {
      paddingsRequired += 1
      requiredWidth += expirationFieldWidth()
    }

    if cvcVisibility != .hidden {
      paddingsRequired += 1
      requiredWidth += cvcFieldWidth()
    }

    if postalVisibility != .hidden && postalCodeEntryEnabled {
      paddingsRequired += 1
      requiredWidth +=
        (postalVisibility == .compressed)
        ? postalCodeFieldCompressedWidth() : postalCodeFieldFullWidth()
    }

    if paddingsRequired > 0 {
      return ceil((width - requiredWidth) / paddingsRequired)
    } else {
      return STPPaymentCardTextFieldMinimumPadding
    }
  }

  /// :nodoc:
  @objc
  public override func layoutSubviews() {
    super.layoutSubviews()
    recalculateSubviewLayout()
  }

  func recalculateSubviewLayout() {

    let bounds = self.bounds

    brandImageView.frame = brandImageRect(forBounds: bounds)
    let fieldsViewRect = fieldsRect(forBounds: bounds)
    fieldsView.frame = fieldsViewRect

    let availableFieldsWidth = fieldsViewRect.width - (2 * STPPaymentCardTextFieldDefaultInsets)

    // These values are filled in via the if statements and then used
    // to do the proper layout at the end
    let fieldsHeight = fieldsViewRect.height
    var hPadding = STPPaymentCardTextFieldDefaultPadding
    var panVisibility: STPCardTextFieldState = .visible
    var expiryVisibility: STPCardTextFieldState = .visible
    var cvcVisibility: STPCardTextFieldState = .visible
    var postalVisibility: STPCardTextFieldState = postalCodeEntryEnabled ? .visible : .hidden

    let calculateMinimumPaddingWithLocalVars: (() -> CGFloat) = {
      return self.minimumPaddingForViews(
        withWidth: availableFieldsWidth,
        pan: panVisibility,
        expiry: expiryVisibility,
        cvc: cvcVisibility,
        postal: postalVisibility)
    }

    hPadding = calculateMinimumPaddingWithLocalVars()

    if hPadding >= STPPaymentCardTextFieldMinimumPadding {
      // Can just render everything at full size
      // Do Nothing
    } else {
      // Need to do selective view compression/hiding

      if focusedTextFieldForLayout == nil {
        /*
                             No field is currently being edited -

                             Render all fields visible:
                             Show compressed PAN, visible CVC and expiry, fill remaining space
                             with postal if necessary

                             The most common way to be in this state is the user finished entry
                             and has moved on to another field (so we want to show summary)
                             but possibly some fields are invalid
                             */
        while hPadding < STPPaymentCardTextFieldMinimumPadding {
          // Try hiding things in this order
          if panVisibility == .visible {
            panVisibility = .compressed
          } else if postalVisibility == .visible {
            postalVisibility = .compressed
          } else {
            // Can't hide anything else, set to minimum and stop
            hPadding = STPPaymentCardTextFieldMinimumPadding
            break
          }
          hPadding = calculateMinimumPaddingWithLocalVars()
        }
      } else {
        switch STPCardFieldType(rawValue: focusedTextFieldForLayout?.intValue ?? 0)! {
        case .number:
          /*
                                             The user is entering PAN

                                             It must be fully visible. Everything else is optional
                                             */

          while hPadding < STPPaymentCardTextFieldMinimumPadding {
            if postalVisibility == .visible {
              postalVisibility = .compressed
            } else if postalVisibility == .compressed {
              postalVisibility = .hidden
            } else if cvcVisibility == .visible {
              cvcVisibility = .hidden
            } else if expiryVisibility == .visible {
              expiryVisibility = .hidden
            } else {
              hPadding = STPPaymentCardTextFieldMinimumPadding
              break
            }
            hPadding = calculateMinimumPaddingWithLocalVars()
          }
        case .expiration:
          /*
                                             The user is entering expiration date

                                             It must be fully visible, and the next and previous fields
                                             must be visible so they can be tapped over to
                                             */
          while hPadding < STPPaymentCardTextFieldMinimumPadding {
            if panVisibility == .visible {
              panVisibility = .compressed
            } else if postalVisibility == .visible {
              postalVisibility = .compressed
            } else if postalVisibility == .compressed {
              postalVisibility = .hidden
            } else {
              hPadding = STPPaymentCardTextFieldMinimumPadding
              break
            }
            hPadding = calculateMinimumPaddingWithLocalVars()
          }
        case .CVC:
          /*
                                             The user is entering CVC

                                             It must be fully visible, and the next and previous fields
                                             must be visible so they can be tapped over to (although
                                             there might not be a next field)
                                             */
          while hPadding < STPPaymentCardTextFieldMinimumPadding {
            if panVisibility == .visible {
              panVisibility = .compressed
            } else if postalVisibility == .visible {
              postalVisibility = .compressed
            } else if panVisibility == .compressed {
              panVisibility = .hidden
            } else {
              hPadding = STPPaymentCardTextFieldMinimumPadding
              break
            }
            hPadding = calculateMinimumPaddingWithLocalVars()
          }
        case .postalCode:
          /*
                                             The user is entering postal code

                                             It must be fully visible, and the previous field must
                                             be visible
                                             */
          while hPadding < STPPaymentCardTextFieldMinimumPadding {
            if panVisibility == .visible {
              panVisibility = .compressed
            } else if panVisibility == .compressed {
              panVisibility = .hidden
            } else if expiryVisibility == .visible {
              expiryVisibility = .hidden
            } else {
              hPadding = STPPaymentCardTextFieldMinimumPadding
              break
            }
            hPadding = calculateMinimumPaddingWithLocalVars()
          }
        }
      }
    }

    // -- Do layout here --
    var xOffset = STPPaymentCardTextFieldDefaultInsets
    var width: CGFloat = 0

    // Make all fields actually slightly wider than needed so that when the
    // cursor is at the end position the contents aren't clipped off to the left side
    let additionalWidth = self.width(forText: "8")

    if panVisibility == .compressed {
      // Need to lower xOffset so pan is partially off-screen

      let hasEnteredCardNumber = (cardNumber?.count ?? 0) > 0
      let compressedCardNumber =
        viewModel.compressedCardNumber(withPlaceholder: numberPlaceholder) ?? ""
      let cardNumberToHide = (hasEnteredCardNumber ? cardNumber : numberPlaceholder)?.stp_string(
        byRemovingSuffix: compressedCardNumber)

      if (cardNumberToHide?.count ?? 0) > 0
        && STPCardValidator.stringIsNumeric(cardNumberToHide ?? "")
      {
        width = hasEnteredCardNumber ? self.width(forCardNumber: cardNumber) : numberFullWidth()

        let hiddenWidth = self.width(forCardNumber: cardNumberToHide)
        xOffset -= hiddenWidth
        let maskView = UIView(
          frame: CGRect(
            x: hiddenWidth,
            y: 0,
            width: width - hiddenWidth,
            height: fieldsHeight))
        maskView.backgroundColor = UIColor.black
        if #available(iOS 13.0, *) {
          maskView.backgroundColor = UIColor.label
        }
        maskView.isOpaque = true
        maskView.isUserInteractionEnabled = false
        UIView.performWithoutAnimation({
          self.numberField.mask = maskView
        })
      } else {
        width = numberCompressedWidth()
        UIView.performWithoutAnimation({
          self.numberField.mask = nil
        })
      }
    } else {
      width = numberFullWidth()
      UIView.performWithoutAnimation({
        self.numberField.mask = nil
      })

      if panVisibility == .hidden {
        // Need to lower xOffset so pan is fully off screen
        xOffset = xOffset - width - hPadding
      }
    }

    numberField.frame = CGRect(
      x: xOffset, y: 0,
      width: CGFloat(min(width + additionalWidth, fieldsView.frame.width - additionalWidth)),
      height: fieldsHeight)
    xOffset += width + hPadding

    width = expirationFieldWidth()
    expirationField.frame = CGRect(
      x: xOffset, y: 0, width: width + additionalWidth, height: fieldsHeight)
    // If the field isn't visible, we don't want to move the xOffset forward.
    if (expiryVisibility != .hidden) {
      xOffset += width + hPadding
    }

    width = cvcFieldWidth()
    cvcField.frame = CGRect(x: xOffset, y: 0, width: width + additionalWidth, height: fieldsHeight)
    if (cvcVisibility != .hidden) {
      xOffset += width + hPadding
    }
    
    if postalCodeEntryEnabled {
      width = fieldsView.frame.size.width - xOffset - STPPaymentCardTextFieldDefaultInsets
      postalCodeField.frame = CGRect(
        x: xOffset, y: 0, width: width + additionalWidth, height: fieldsHeight)
    }

    let updateFieldVisibility: ((STPFormTextField?, STPCardTextFieldState) -> Void)? = {
      field, fieldState in
      if fieldState == .hidden {
        field?.alpha = 0.0
        field?.isAccessibilityElement = false
      } else {
        field?.alpha = 1.0
        field?.isAccessibilityElement = true
      }
    }

    updateFieldVisibility?(numberField, panVisibility)
    updateFieldVisibility?(expirationField, expiryVisibility)
    updateFieldVisibility?(cvcField, cvcVisibility)
    updateFieldVisibility?(postalCodeField, postalCodeEntryEnabled ? postalVisibility : .hidden)
  }

  // MARK: - private helper methods
  func build() -> STPFormTextField {
    let textField = STPFormTextField(frame: CGRect.zero)
    textField.backgroundColor = UIColor.clear
    // setCountryCode: updates the postalCodeField keyboardType, this is safe
    textField.keyboardType = .asciiCapableNumberPad
    textField.textAlignment = .left
    textField.font = font
    textField.defaultColor = textColor
    textField.errorColor = textErrorColor
    textField.placeholderColor = placeholderColor
    textField.formDelegate = self
    textField.validText = true
    return textField
  }

  typealias STPLayoutAnimationCompletionBlock = (Bool) -> Void

  func layoutViews(
    toFocus focusedField: NSNumber?,
    becomeFirstResponder shouldBecomeFirstResponder: Bool,
    animated: Bool,
    completion: STPLayoutAnimationCompletionBlock?
  ) {

    var fieldtoFocus = focusedField

    if fieldtoFocus == nil
      && !(focusedTextFieldForLayout == NSNumber(value: STPCardFieldType.number.rawValue))
    {
      fieldtoFocus = NSNumber(value: STPCardFieldType.number.rawValue)
      if shouldBecomeFirstResponder {
        numberField.becomeFirstResponder()
      }
    }

    if (fieldtoFocus == nil && focusedTextFieldForLayout == nil)
      || (fieldtoFocus != nil && (focusedTextFieldForLayout == fieldtoFocus))
    {
      if let completion = completion {
        completion(true)
      }
      return
    }

    focusedTextFieldForLayout = fieldtoFocus

    let animations: (() -> Void)? = {
      self.recalculateSubviewLayout()
    }

    if animated {
      let duration: TimeInterval = 0.3
      if let animations = animations {
        UIView.animate(
          withDuration: duration,
          delay: 0,
          usingSpringWithDamping: 0.85,
          initialSpringVelocity: 0,
          options: [],
          animations: animations,
          completion: completion)
      }
    } else {
      animations?()
    }
  }

  func width(forAttributedText attributedText: NSAttributedString?) -> CGFloat {
    // UITextField doesn't seem to size correctly here for unknown reasons
    // But UILabel reliably calculates size correctly using this method
    sizingLabel.attributedText = attributedText
    sizingLabel.sizeToFit()
    return ceil(sizingLabel.bounds.width)

  }

  func width(forText text: String?) -> CGFloat {
    guard let text = text, text.count > 0 else {
      return 0
    }

    if let cachedValue = textToWidthCache[text] {
      return CGFloat(cachedValue.doubleValue)
    }
    sizingField.autoFormattingBehavior = .none
    sizingField.text = STPNonLocalizedString(text)
    let cachedValue = NSNumber(value: Float(width(forAttributedText: sizingField.attributedText)))
    textToWidthCache[text] = cachedValue
    return CGFloat(cachedValue.doubleValue)
  }

  func width(forCardNumber cardNumber: String?) -> CGFloat {
    guard let cardNumber = cardNumber, cardNumber.count > 0 else {
      return 0
    }

    if let cachedValue = numberToWidthCache[cardNumber] {
      return CGFloat(cachedValue.doubleValue)
    }
    sizingField.autoFormattingBehavior = .cardNumbers
    sizingField.text = cardNumber
    let cachedValue = NSNumber(value: Float(width(forAttributedText: sizingField.attributedText)))
    numberToWidthCache[cardNumber] = cachedValue
    return CGFloat(cachedValue.doubleValue)
  }

  // MARK: STPFormTextFieldDelegate
  @objc(formTextFieldDidBackspaceOnEmpty:) func formTextFieldDidBackspace(
    onEmpty formTextField: STPFormTextField
  ) {
    let previous = previousField()
    previous?.becomeFirstResponder()
    UIAccessibility.post(notification: .screenChanged, argument: nil)
    if previous?.hasText ?? false {
      previous?.deleteBackward()
    }
  }

  @objc(formTextField:modifyIncomingTextChange:) func formTextField(
    _ formTextField: STPFormTextField,
    modifyIncomingTextChange input: NSAttributedString
  ) -> NSAttributedString {
    guard let fieldType = STPCardFieldType(rawValue: formTextField.tag) else {
      return NSAttributedString(string: "")
    }
    switch fieldType {
    case .number:
      viewModel.cardNumber = input.string
      setNeedsLayout()
    case .expiration:
      viewModel.rawExpiration = input.string
    case .CVC:
      viewModel.cvc = input.string
    case .postalCode:
      viewModel.postalCode = input.string
      setNeedsLayout()
    }

    switch fieldType {
    case .number:
      return NSAttributedString(
        string: viewModel.cardNumber ?? "",
        attributes: numberField.defaultTextAttributes)
    case .expiration:
      return NSAttributedString(
        string: viewModel.rawExpiration ?? "",
        attributes: expirationField.defaultTextAttributes)
    case .CVC:
      return NSAttributedString(
        string: viewModel.cvc ?? "",
        attributes: cvcField.defaultTextAttributes)
    case .postalCode:
      return NSAttributedString(
        string: viewModel.postalCode ?? "",
        attributes: cvcField.defaultTextAttributes)
    }
  }

  @objc(formTextFieldTextDidChange:) func formTextFieldTextDidChange(
    _ formTextField: STPFormTextField
  ) {
    guard let fieldType = STPCardFieldType(rawValue: formTextField.tag) else {
      return
    }

    formTextField.validText = true

    switch fieldType {
    case .number:
      let number = viewModel.cardNumber

      // Changing the card number field can invalidate the cvc, e.g. going from 4 digit Amex cvc to 3 digit Visa
      // it is not expected that the brand will change based on network response so we update this immediately
      // as well as in the completion just in case
      updateCVCPlaceholder()
      cvcField.validText = viewModel.validationStateForCVC() != .invalid
      updateImage(for: fieldType)

      if viewModel.hasCompleteMetadataForCardNumber {
        let state = STPCardValidator.validationState(
          forNumber: viewModel.cardNumber ?? "", validatingCardBrand: true)
        updateCVCPlaceholder()
        cvcField.validText = viewModel.validationStateForCVC() != .invalid
        formTextField.validText = state != .invalid

        if state == .valid {
          // auto-advance
          nextFirstResponderField().becomeFirstResponder()
          UIAccessibility.post(notification: .screenChanged, argument: nil)
        }
      } else {
        viewModel.validationStateForCardNumber(handler: { state in
          if self.viewModel.cardNumber == number {
            self.updateCVCPlaceholder()
            self.cvcField.validText = self.viewModel.validationStateForCVC() != .invalid
            formTextField.validText = state != .invalid
            if state == .valid {
              // log that user entered full complete PAN before we got a network response
              STPAnalyticsClient.sharedClient.logUserEnteredCompletePANBeforeMetadataLoaded(
                with: STPPaymentConfiguration.shared)
            }
            self.onChange()
          }
          // Update image on response because we may want to remove the loading indicator
          if let tag = (self.currentFirstResponderField() ?? self.numberField)?.tag,
            let current = STPCardFieldType(rawValue: tag)
          {
            self.updateImage(for: current)
          }
          // no auto-advance
        })

        if viewModel.isNumberMaxLength {
          let isValidLuhn = STPCardValidator.stringIsValidLuhn(viewModel.cardNumber ?? "")
          formTextField.validText = isValidLuhn
          if isValidLuhn {
            // auto-advance
            nextFirstResponderField().becomeFirstResponder()
            UIAccessibility.post(notification: .screenChanged, argument: nil)
          }
        }
      }
    case .expiration:
      let state = viewModel.validationStateForExpiration()
      formTextField.validText = state != .invalid
      if state == .valid {
        // auto-advance
        nextFirstResponderField().becomeFirstResponder()
        UIAccessibility.post(notification: .screenChanged, argument: nil)
      }
    case .CVC:
      let state = viewModel.validationStateForCVC()
      formTextField.validText = state != .invalid
      if state == .valid {
        /*
                                     Even though any CVC longer than the min required CVC length
                                     is valid, we don't want to forward on to the next field
                                     unless it is actually >= the max cvc length (otherwise when
                                     postal code is showing, you can't easily enter CVCs longer than
                                     the minimum.
                                     */
        let sanitizedCvc = STPCardValidator.sanitizedNumericString(for: formTextField.text ?? "")
        if sanitizedCvc.count >= STPCardValidator.maxCVCLength(for: viewModel.brand) {
          // auto-advance
          nextFirstResponderField().becomeFirstResponder()
          UIAccessibility.post(notification: .screenChanged, argument: nil)
        }
      }
    case .postalCode:
      formTextField.validText = viewModel.validationStateForExpiration() != .invalid
    // no auto-advance
    /*
                            Similar to the UX problems on CVC, since our Postal Code validation
                            is pretty light, we want to block auto-advance here. In the US, this
                            allows users to enter 9 digit zips if they want, and as many as they
                            need in non-US countries (where >0 characters is "valid")
                            */
    }

    onChange()
  }

  enum STPFieldEditingTransitionCallSite: Int {
    case shouldBegin
    case shouldEnd
    case didBegin
    case didEnd
  }

  // Explanation of the logic here is with the definition of these properties
  // at the top of this file
  @discardableResult func getAndUpdateSubviewEditingTransitionState(
    fromCall sendingMethod: STPFieldEditingTransitionCallSite
  ) -> Bool {
    var stateToReturn: Bool
    switch sendingMethod {
    case .shouldBegin:
      receivedUnmatchedShouldBeginEditing = true
      if receivedUnmatchedShouldEndEditing {
        isMidSubviewEditingTransitionInternal = true
      }
      stateToReturn = isMidSubviewEditingTransitionInternal
    case .shouldEnd:
      receivedUnmatchedShouldEndEditing = true
      if receivedUnmatchedShouldBeginEditing {
        isMidSubviewEditingTransitionInternal = true
      }
      stateToReturn = isMidSubviewEditingTransitionInternal
    case .didBegin:
      stateToReturn = isMidSubviewEditingTransitionInternal
      receivedUnmatchedShouldBeginEditing = false
      if receivedUnmatchedShouldEndEditing == false {
        isMidSubviewEditingTransitionInternal = false
      }
    case .didEnd:
      stateToReturn = isMidSubviewEditingTransitionInternal
      receivedUnmatchedShouldEndEditing = false
      if receivedUnmatchedShouldBeginEditing == false {
        isMidSubviewEditingTransitionInternal = false
      }
    }

    return stateToReturn
  }

  func resetSubviewEditingTransitionState() {
    isMidSubviewEditingTransitionInternal = false
    receivedUnmatchedShouldBeginEditing = false
    receivedUnmatchedShouldEndEditing = false
  }

  /// :nodoc:
  @objc
  public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    getAndUpdateSubviewEditingTransitionState(fromCall: .shouldBegin)
    return true
  }

  /// :nodoc:
  @objc
  public func textFieldDidBeginEditing(_ textField: UITextField) {
    let isMidSubviewEditingTransition = getAndUpdateSubviewEditingTransitionState(
      fromCall: .didBegin)

    layoutViews(
      toFocus: NSNumber(value: textField.tag),
      becomeFirstResponder: true,
      animated: true, completion: nil)

    if !isMidSubviewEditingTransition {
      if delegate?.responds(
        to: #selector(STPAddCardViewController.paymentCardTextFieldDidBeginEditing(_:))) ?? false
      {
        delegate?.paymentCardTextFieldDidBeginEditing?(self)
      }
    }

    guard let cardType = STPCardFieldType(rawValue: textField.tag) else {
      return
    }
    switch cardType {
    case .number:
      (textField as? STPFormTextField)?.validText = true
      if delegate?.responds(
        to: #selector(STPPaymentCardTextFieldDelegate.paymentCardTextFieldDidBeginEditingNumber(_:))
      ) ?? false {
        delegate?.paymentCardTextFieldDidBeginEditingNumber?(self)
      }
    case .CVC:
      if delegate?.responds(
        to: #selector(STPAddCardViewController.paymentCardTextFieldDidBeginEditingCVC(_:))) ?? false
      {
        delegate?.paymentCardTextFieldDidBeginEditingCVC?(self)
      }
    case .expiration:
      if delegate?.responds(
        to: #selector(
          STPPaymentCardTextFieldDelegate.paymentCardTextFieldDidBeginEditingExpiration(_:)))
        ?? false
      {
        delegate?.paymentCardTextFieldDidBeginEditingExpiration?(self)
      }
    case .postalCode:
      if delegate?.responds(
        to: #selector(
          STPPaymentCardTextFieldDelegate.paymentCardTextFieldDidBeginEditingPostalCode(_:)))
        ?? false
      {
        delegate?.paymentCardTextFieldDidBeginEditingPostalCode?(self)
      }
    }
    updateImage(for: cardType)
  }

  /// :nodoc:
  @objc
  public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
    getAndUpdateSubviewEditingTransitionState(fromCall: .shouldEnd)
    updateImage(for: .number)
    return true
  }

  /// :nodoc:
  @objc
  public func textFieldDidEndEditing(_ textField: UITextField) {
    let isMidSubviewEditingTransition = getAndUpdateSubviewEditingTransitionState(fromCall: .didEnd)

    guard let cardType = STPCardFieldType(rawValue: textField.tag) else {
      return
    }

    switch cardType {
    case .number:
      viewModel.validationStateForCardNumber(handler: { state in
        if state == .incomplete && !textField.isEditing {
          (textField as? STPFormTextField)?.validText = false
        }
      })
      if delegate?.responds(
        to: #selector(STPPaymentCardTextFieldDelegate.paymentCardTextFieldDidEndEditingNumber(_:)))
        ?? false
      {
        delegate?.paymentCardTextFieldDidEndEditingNumber?(self)
      }
    case .CVC:
      if delegate?.responds(
        to: #selector(STPAddCardViewController.paymentCardTextFieldDidEndEditingCVC(_:))) ?? false
      {
        delegate?.paymentCardTextFieldDidEndEditingCVC?(self)
      }
    case .expiration:
      if delegate?.responds(
        to: #selector(
          STPPaymentCardTextFieldDelegate.paymentCardTextFieldDidEndEditingExpiration(_:))) ?? false
      {
        delegate?.paymentCardTextFieldDidEndEditingExpiration?(self)
      }
    case .postalCode:
      if delegate?.responds(
        to: #selector(
          STPPaymentCardTextFieldDelegate.paymentCardTextFieldDidEndEditingPostalCode(_:))) ?? false
      {
        delegate?.paymentCardTextFieldDidEndEditingPostalCode?(self)
      }
    }

    if !isMidSubviewEditingTransition {
      layoutViews(
        toFocus: nil,
        becomeFirstResponder: false,
        animated: true, completion: nil)
      updateImage(for: .number)
      if delegate?.responds(
        to: #selector(STPPaymentCardTextFieldDelegate.paymentCardTextFieldDidEndEditing(_:)))
        ?? false
      {
        delegate?.paymentCardTextFieldDidEndEditing?(self)
      }
    }
  }

  /// :nodoc:
  @objc
  public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if textField == lastSubField() && _firstInvalidAutoAdvanceField() == nil {
      // User pressed return in the last field, and all fields are valid
      if delegate?.responds(
        to: #selector(STPAddCardViewController.paymentCardTextFieldWillEndEditing(forReturn:)))
        ?? false
      {
        delegate?.paymentCardTextFieldWillEndEditing?(forReturn: self)
      }
      resignFirstResponder()
    } else {
      // otherwise, move to the next field
      nextFirstResponderField().becomeFirstResponder()
      UIAccessibility.post(notification: .screenChanged, argument: nil)
    }

    return false
  }

  @objc internal func brandImage(
    for fieldType: STPCardFieldType, validationState: STPCardValidationState
  ) -> UIImage? {
    switch fieldType {
    case .number:
      if validationState == .invalid {
        return STPPaymentCardTextField.errorImage(for: viewModel.brand)
      } else {
        if viewModel.hasCompleteMetadataForCardNumber {
          return STPPaymentCardTextField.brandImage(for: viewModel.brand)
        } else {
          return STPPaymentCardTextField.brandImage(for: .unknown)
        }
      }
    case .CVC:
      return STPPaymentCardTextField.cvcImage(for: viewModel.brand)
    case .expiration:
      return STPPaymentCardTextField.brandImage(for: viewModel.brand)
    case .postalCode:
      return STPPaymentCardTextField.brandImage(for: viewModel.brand)
    }
  }

  func brandImageAnimationOptions(
    forNewType newType: STPCardFieldType,
    newBrand: STPCardBrand,
    oldType: STPCardFieldType,
    oldBrand: STPCardBrand
  ) -> UIView.AnimationOptions {

    if newType == .CVC && oldType != .CVC {
      // Transitioning to show CVC

      if newBrand != .amex {
        // CVC is on the back
        return [.curveEaseInOut, .transitionFlipFromRight]
      }
    } else if newType != .CVC && oldType == .CVC {
      // Transitioning to stop showing CVC

      if oldBrand != .amex {
        // CVC was on the back
        return [.curveEaseInOut, .transitionFlipFromLeft]
      }
    }

    // All other cases just cross dissolve
    return [.curveEaseInOut, .transitionCrossDissolve]

  }

  func updateImage(for fieldType: STPCardFieldType) {

    let addLoadingIndicator: (() -> Void)? = {
      if self.metadataLoadingIndicator == nil {
        self.metadataLoadingIndicator = STPCardLoadingIndicator()

        self.metadataLoadingIndicator?.translatesAutoresizingMaskIntoConstraints = false
        if let metadataLoadingIndicator = self.metadataLoadingIndicator {
          self.addSubview(metadataLoadingIndicator)
        }
        NSLayoutConstraint.activate(
          [
            self.metadataLoadingIndicator?.rightAnchor.constraint(
              equalTo: self.brandImageView.rightAnchor),
            self.metadataLoadingIndicator?.topAnchor.constraint(
              equalTo: self.brandImageView.topAnchor),
          ].compactMap { $0 })
      }

      let loadingIndicator = self.metadataLoadingIndicator
      if !(loadingIndicator?.isHidden ?? false) {
        return
      }

      loadingIndicator?.alpha = 0.0
      loadingIndicator?.isHidden = false
      UIView.animate(
        withDuration: 0.6, delay: 0, options: .curveEaseInOut,
        animations: {
          loadingIndicator?.alpha = 1.0
        }
      ) { _ in
        loadingIndicator?.alpha = 1.0
      }
    }

    let removeLoadingIndicator: (() -> Void)? = {
      if self.metadataLoadingIndicator != nil && !(self.metadataLoadingIndicator?.isHidden ?? false)
      {
        let loadingIndicator = self.metadataLoadingIndicator

        UIView.animate(
          withDuration: 0.6, delay: 0, options: .curveEaseInOut,
          animations: {
            loadingIndicator?.alpha = 0.0
          }
        ) { _ in
          loadingIndicator?.alpha = 0.0
          loadingIndicator?.isHidden = true
        }
      }
    }

    let applyBrandImage: ((STPCardFieldType, STPCardValidationState) -> Void)? = {
      applyFieldType, validationState in
      let image = self.brandImage(for: applyFieldType, validationState: validationState)
      if !(image == self.brandImageView.image) {

        let newBrand = self.viewModel.brand
        let imageAnimationOptions = self.brandImageAnimationOptions(
          forNewType: fieldType,
          newBrand: newBrand,
          oldType: self.currentBrandImageFieldType,
          oldBrand: self.currentBrandImageBrand)

        self.currentBrandImageFieldType = applyFieldType
        self.currentBrandImageBrand = newBrand

        UIView.transition(
          with: self.brandImageView,
          duration: 0.2,
          options: imageAnimationOptions,
          animations: {
            self.brandImageView.image = image
          })
      }
    }

    if !(viewModel.hasCompleteMetadataForCardNumber)
      && STPBINRange.isLoadingCardMetadata(forPrefix: viewModel.cardNumber ?? "")
    {
      applyBrandImage?(.number, .incomplete)
      // delay a bit before showing loading indicator because the response may come quickly
      DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(
          Int64(kCardLoadingAnimationDelay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC),
        execute: {
          if !(self.viewModel.hasCompleteMetadataForCardNumber)
            && STPBINRange.isLoadingCardMetadata(forPrefix: self.viewModel.cardNumber ?? "")
          {
            addLoadingIndicator?()
          }
        })
    } else {
      removeLoadingIndicator?()

      switch fieldType {
      case .number:
        applyBrandImage?(
          .number,
          STPCardValidator.validationState(
            forNumber: viewModel.cardNumber ?? "", validatingCardBrand: true))
      case .expiration:
        applyBrandImage?(fieldType, (viewModel.validationStateForExpiration()))
      case .CVC:
        applyBrandImage?(fieldType, (viewModel.validationStateForCVC()))
      case .postalCode:
        applyBrandImage?(fieldType, (viewModel.validationStateForPostalCode()))
      }
    }
  }

  func defaultCVCPlaceholder() -> String? {
    if viewModel.brand == .amex {
      return STPLocalizedString("CVV", "Label for entering CVV in text field")
    } else {
      return STPLocalizedString("CVC", "Label for entering CVC in text field")
    }
  }

  func updateCVCPlaceholder() {
    if let cvcPlaceholder = cvcPlaceholder {
      cvcField.placeholder = cvcPlaceholder
      cvcField.accessibilityLabel = cvcPlaceholder
    } else {
      cvcField.placeholder = defaultCVCPlaceholder()
      cvcField.accessibilityLabel = defaultCVCPlaceholder()
    }
  }

  func onChange() {
    if delegate?.responds(to: #selector(STPAddCardViewController.paymentCardTextFieldDidChange(_:)))
      ?? false
    {
      delegate?.paymentCardTextFieldDidChange?(self)
    }
    sendActions(for: .valueChanged)
  }

  // MARK: UIKeyInput
  /// :nodoc:
  @objc public var hasText: Bool {
    return numberField.hasText || expirationField.hasText || cvcField.hasText
  }

  /// :nodoc:
  @objc
  public func insertText(_ text: String) {
    currentFirstResponderField()?.insertText(text)
  }

  /// :nodoc:
  @objc
  public func deleteBackward() {
    currentFirstResponderField()?.deleteBackward()
  }

  /// :nodoc:
  @objc
  public class func keyPathsForValuesAffectingIsValid() -> Set<String> {
    return Set<String>([
      "viewModel.isValid",
      "viewModel.hasCompleteMetadataForCardNumber",
    ])
  }
}

/// This protocol allows a delegate to be notified when a payment text field's
/// contents change, which can in turn be used to take further actions depending
/// on the validity of its contents.
@objc public protocol STPPaymentCardTextFieldDelegate: NSObjectProtocol {
  /// Called when either the card number, expiration, or CVC changes. At this point,
  /// one can call `isValid` on the text field to determine, for example,
  /// whether or not to enable a button to submit the form. Example:
  /// - (void)paymentCardTextFieldDidChange:(STPPaymentCardTextField *)textField {
  /// self.paymentButton.enabled = textField.isValid;
  /// }
  /// - Parameter textField: the text field that has changed
  @objc optional func paymentCardTextFieldDidChange(_ textField: STPPaymentCardTextField)
  /// Called when editing begins in the text field as a whole.
  /// After receiving this callback, you will always also receive a callback for which
  /// specific subfield of the view began editing.
  @objc optional func paymentCardTextFieldDidBeginEditing(_ textField: STPPaymentCardTextField)
  /// Notification that the user pressed the `return` key after completely filling
  /// out the STPPaymentCardTextField with data that passes validation.
  /// The Stripe SDK is going to `resignFirstResponder` on the `STPPaymentCardTextField`
  /// to dismiss the keyboard after this delegate method returns, however if your app wants
  /// to do something more (ex: move first responder to another field), this is a good
  /// opportunity to do that.
  /// This is delivered *before* the corresponding `paymentCardTextFieldDidEndEditing:`
  /// - Parameter textField: The STPPaymentCardTextField that was being edited when the user pressed return
  @objc optional func paymentCardTextFieldWillEndEditing(
    forReturn textField: STPPaymentCardTextField)
  /// Called when editing ends in the text field as a whole.
  /// This callback is always preceded by an callback for which
  /// specific subfield of the view ended its editing.
  @objc optional func paymentCardTextFieldDidEndEditing(_ textField: STPPaymentCardTextField)
  /// Called when editing begins in the payment card field's number field.
  @objc optional func paymentCardTextFieldDidBeginEditingNumber(
    _ textField: STPPaymentCardTextField)
  /// Called when editing ends in the payment card field's number field.
  @objc optional func paymentCardTextFieldDidEndEditingNumber(_ textField: STPPaymentCardTextField)
  /// Called when editing begins in the payment card field's CVC field.
  @objc optional func paymentCardTextFieldDidBeginEditingCVC(_ textField: STPPaymentCardTextField)
  /// Called when editing ends in the payment card field's CVC field.
  @objc optional func paymentCardTextFieldDidEndEditingCVC(_ textField: STPPaymentCardTextField)
  /// Called when editing begins in the payment card field's expiration field.
  @objc optional func paymentCardTextFieldDidBeginEditingExpiration(
    _ textField: STPPaymentCardTextField)
  /// Called when editing ends in the payment card field's expiration field.
  @objc optional func paymentCardTextFieldDidEndEditingExpiration(
    _ textField: STPPaymentCardTextField)
  /// Called when editing begins in the payment card field's ZIP/postal code field.
  @objc optional func paymentCardTextFieldDidBeginEditingPostalCode(
    _ textField: STPPaymentCardTextField)
  /// Called when editing ends in the payment card field's ZIP/postal code field.
  @objc optional func paymentCardTextFieldDidEndEditingPostalCode(
    _ textField: STPPaymentCardTextField)
}

//
//  STPPaymentCardTextField+Private.h
//  Stripe
//
//  Created by Brian Dorfman on 5/3/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

private let kCardLoadingAnimationDelay: TimeInterval = 0.1
