//
//  STPAUBECSDebitFormView.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 3/4/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

/// STPAUBECSDebitFormViewDelegate provides methods for STPAUBECSDebitFormView to inform its delegate
/// of when the form has been completed.
@objc public protocol STPAUBECSDebitFormViewDelegate: NSObjectProtocol {
  /// Called when the form transitions from complete to incomplete or vice-versa.
  /// - Parameters:
  ///   - form: The `STPAUBECSDebitFormView` instance whose completion state has changed
  ///   - complete: Whether the form is considered complete and can generate an `STPPaymentMethodParams` instance.
  func auBECSDebitForm(_ form: STPAUBECSDebitFormView, didChangeToStateComplete complete: Bool)
}

/// STPAUBECSDebitFormView is a subclass of UIControl that contains all of the necessary fields and legal text for collecting AU BECS Debit payments.
/// For additional customization options - seealso: STPFormTextFieldContainer
public class STPAUBECSDebitFormView: STPMultiFormTextField, STPMultiFormFieldDelegate,
  UITextViewDelegate
{
  private var viewModel: STPAUBECSFormViewModel!
  private var _nameTextField: STPFormTextField!
  private var _emailTextField: STPFormTextField!
  private var _bsbNumberTextField: STPFormTextField!
  private var _accountNumberTextField: STPFormTextField!
  private var labeledNameField: STPLabeledFormTextFieldView!
  private var labeledEmailField: STPLabeledFormTextFieldView!
  private var labeledBECSField: STPLabeledMultiFormTextFieldView!
  private var bankIconView: UIImageView!
  private var bsbLabel: UILabel!
  private var mandateLabel: UITextView!
  private var companyName: String

  /// - Parameter companyName: The name of the company collecting AU BECS Debit payment details information. This will be used to provide the required service agreement text. - seealso: https://stripe.com/au-becs/legal
  @objc(initWithCompanyName:)
  public required init(companyName: String) {
    self.companyName = companyName
    super.init(frame: CGRect.zero)
    viewModel = STPAUBECSFormViewModel()
    _nameTextField = _buildTextField()
    _nameTextField.keyboardType = .default
    _nameTextField.placeholder = STPLocalizedString(
      "Full name", "Placeholder string for name entry field.")
    _nameTextField.textContentType = .name

    _emailTextField = _buildTextField()
    _emailTextField.keyboardType = .emailAddress
    _emailTextField.placeholder = STPLocalizedString(
      "example@example.com", "Placeholder string for email entry field.")
    _emailTextField.textContentType = .emailAddress

    _bsbNumberTextField = _buildTextField()
    _bsbNumberTextField.placeholder = STPLocalizedString(
      "BSB", "Placeholder text for BSB Number entry field for BECS Debit.")
    _bsbNumberTextField.autoFormattingBehavior = .bsbNumber
    _bsbNumberTextField.leftViewMode = .always
    bankIconView = UIImageView()
    bankIconView.contentMode = .center
    bankIconView.image = viewModel.bankIcon(forInput: nil)
    bankIconView.translatesAutoresizingMaskIntoConstraints = false
    let iconContainer = UIView()
    iconContainer.addSubview(bankIconView)
    iconContainer.translatesAutoresizingMaskIntoConstraints = false
    _bsbNumberTextField.leftView = iconContainer

    _accountNumberTextField = _buildTextField()
    _accountNumberTextField.placeholder = STPLocalizedString(
      "Account number", "Placeholder text for Account number entry field for BECS Debit.")

    labeledNameField = STPLabeledFormTextFieldView(
      formLabel: STPAUBECSDebitFormView._nameTextFieldLabel(), textField: _nameTextField)
    labeledNameField.formBackgroundColor = formBackgroundColor
    labeledNameField.translatesAutoresizingMaskIntoConstraints = false
    addSubview(labeledNameField)

    labeledEmailField = STPLabeledFormTextFieldView(
      formLabel: STPAUBECSDebitFormView._emailTextFieldLabel(), textField: _emailTextField)
    labeledEmailField.topSeparatorHidden = true
    labeledEmailField.formBackgroundColor = formBackgroundColor
    labeledEmailField.translatesAutoresizingMaskIntoConstraints = false
    addSubview(labeledEmailField)

    labeledBECSField = STPLabeledMultiFormTextFieldView(
      formLabel: STPAUBECSDebitFormView._bsbNumberTextFieldLabel(),
      firstTextField: _bsbNumberTextField,
      secondTextField: _accountNumberTextField)
    labeledBECSField.formBackgroundColor = formBackgroundColor
    labeledBECSField.translatesAutoresizingMaskIntoConstraints = false
    addSubview(labeledBECSField)

    bsbLabel = UILabel()
    bsbLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
    bsbLabel.textColor = _defaultBSBLabelTextColor()
    bsbLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(bsbLabel)

    let mandateTextLabel = UITextView()
    mandateTextLabel.isScrollEnabled = false
    mandateTextLabel.isEditable = false
    mandateTextLabel.isSelectable = true
    mandateTextLabel.backgroundColor = UIColor.clear
    // Get rid of the extra padding added by default to UITextViews
    mandateTextLabel.textContainerInset = .zero
    mandateTextLabel.textContainer.lineFragmentPadding = 0.0

    mandateTextLabel.delegate = self

    let mandateText = NSMutableAttributedString(
      string:
        "By providing your bank account details and confirming this payment, you agree to this Direct Debit Request and the Direct Debit Request service agreement, and authorise Stripe Payments Australia Pty Ltd ACN 160 180 343 Direct Debit User ID number 507156 (\"Stripe\") to debit your account through the Bulk Electronic Clearing System (BECS) on behalf of \(companyName) (the \"Merchant\") for any amounts separately communicated to you by the Merchant. You certify that you are either an account holder or an authorised signatory on the account listed above."
    )
    let linkRange = (mandateText.string as NSString).range(
      of: "Direct Debit Request service agreement")
    if linkRange.location != NSNotFound {
      mandateText.addAttribute(
        .link, value: "https://stripe.com/au-becs-dd-service-agreement/legal", range: linkRange)
    } else {
      assert(false, "Shouldn't be missing the text to linkify.")
    }
    mandateTextLabel.attributedText = mandateText
    // Set font and textColor after setting the attributedText so they are applied as attributes automatically
    mandateTextLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
    if #available(iOS 13.0, *) {
      mandateTextLabel.textColor = UIColor.secondaryLabel
    } else {
      // Fallback on earlier versions
      mandateTextLabel.textColor = UIColor.darkGray
    }

    mandateTextLabel.translatesAutoresizingMaskIntoConstraints = false

    addSubview(mandateTextLabel)
    mandateLabel = mandateTextLabel

    var constraints = [
      bankIconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
      bankIconView.topAnchor.constraint(equalTo: iconContainer.topAnchor, constant: 0),
      bankIconView.leadingAnchor.constraint(equalTo: iconContainer.leadingAnchor),
      bankIconView.trailingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: -8),
      iconContainer.heightAnchor.constraint(greaterThanOrEqualTo: bankIconView.heightAnchor, multiplier: 1.0),
      iconContainer.widthAnchor.constraint(greaterThanOrEqualTo: bankIconView.widthAnchor, multiplier: 1.0),
      labeledNameField.leadingAnchor.constraint(equalTo: leadingAnchor),
      labeledNameField.trailingAnchor.constraint(equalTo: trailingAnchor),
      labeledNameField.topAnchor.constraint(equalTo: topAnchor),
      labeledEmailField.leadingAnchor.constraint(equalTo: leadingAnchor),
      labeledEmailField.trailingAnchor.constraint(equalTo: trailingAnchor),
      labeledEmailField.topAnchor.constraint(equalTo: labeledNameField.bottomAnchor),
      labeledNameField.labelWidthDimension.constraint(
        equalTo: labeledEmailField.labelWidthDimension),
      labeledBECSField.leadingAnchor.constraint(equalTo: leadingAnchor),
      labeledBECSField.trailingAnchor.constraint(equalTo: trailingAnchor),
      labeledBECSField.topAnchor.constraint(
        equalTo: labeledEmailField.bottomAnchor, constant: 4),
      bsbLabel.topAnchor.constraint(equalTo: labeledBECSField.bottomAnchor, constant: 4),
      // Constrain to bottom of becs details instead of bank name label becuase it is height 0 when no data
      // has been entered
      mandateTextLabel.topAnchor.constraint(
        equalTo: labeledBECSField.bottomAnchor, constant: 40.0),
      bottomAnchor.constraint(equalTo: mandateTextLabel.bottomAnchor),
    ].compactMap { $0 }


    constraints.append(
      contentsOf: [
        bsbLabel.leadingAnchor.constraint(
          equalToSystemSpacingAfter: layoutMarginsGuide.leadingAnchor, multiplier: 1.0),
        layoutMarginsGuide.trailingAnchor.constraint(
          equalToSystemSpacingAfter: bsbLabel.trailingAnchor, multiplier: 1.0),
        mandateTextLabel.leadingAnchor.constraint(
          equalToSystemSpacingAfter: layoutMarginsGuide.leadingAnchor, multiplier: 1.0),
        layoutMarginsGuide.trailingAnchor.constraint(
          equalToSystemSpacingAfter: mandateTextLabel.trailingAnchor, multiplier: 1.0),
      ].compactMap { $0 })

    NSLayoutConstraint.activate(constraints)

    formTextFields = [
      _nameTextField,
      _emailTextField,
      _bsbNumberTextField,
      _accountNumberTextField,
    ].compactMap { $0 }
    multiFormFieldDelegate = self
  }

  /// Use initWithCompanyName instead.
  required convenience init?(coder: NSCoder) {
    assertionFailure("Use initWithCompanyName instead.")
    self.init(companyName: "")
  }

  /// Use initWithCompanyName instead.
  override convenience init(frame: CGRect) {
    assertionFailure("Use initWithCompanyName instead.")
    self.init(companyName: "")
  }

  /// The background color for the form text fields. Defaults to .systemBackground on iOS 13.0 and later, .white on earlier iOS versions.
  @objc public var formBackgroundColor: UIColor = {
    if #available(iOS 13.0, *) {
      return .systemBackground
    } else {
      // Fallback on earlier versions
      return .white
    }
  }()
  {
    didSet {
      labeledNameField.formBackgroundColor = formBackgroundColor
      labeledEmailField.formBackgroundColor = formBackgroundColor
      labeledBECSField.formBackgroundColor = formBackgroundColor
    }
  }

  /// The delegate to inform about changes to this STPAUBECSDebitFormView instance.
  @objc public weak var becsDebitFormDelegate: STPAUBECSDebitFormViewDelegate?
  /// This property will return a non-nil value if and only if the form is in a complete state. The `STPPaymentMethodParams` instance
  /// will have it's `auBECSDebit` property populated with the values input in this form.
  @objc public var paymentMethodParams: STPPaymentMethodParams? {
    return viewModel.paymentMethodParams
  }

  private var _paymentMethodParams: STPPaymentMethodParams?

  func _buildTextField() -> STPFormTextField {
    let textField = STPFormTextField(frame: CGRect.zero)
    textField.keyboardType = .asciiCapableNumberPad
    textField.textAlignment = .natural

    textField.font = formFont
    textField.defaultColor = formTextColor
    textField.errorColor = formTextErrorColor
    textField.placeholderColor = formPlaceholderColor
    textField.keyboardAppearance = formKeyboardAppearance

    textField.validText = true
    textField.selectionEnabled = true
    return textField
  }

  class func _nameTextFieldLabel() -> String {
    return STPLocalizationUtils.localizedNameString()
  }

  class func _emailTextFieldLabel() -> String {
    return STPLocalizationUtils.localizedEmailString()
  }

  class func _bsbNumberTextFieldLabel() -> String {
    return STPLocalizationUtils.localizedBankAccountString()
  }

  class func _accountNumberTextFieldLabel() -> String {
    return self._bsbNumberTextFieldLabel()  // same label
  }

  func _updateValidText(for formTextField: STPFormTextField) {
    if formTextField == _bsbNumberTextField {
      formTextField.validText =
        viewModel.isInputValid(
          formTextField.text ?? "",
          for: .BSBNumber,
          editing: formTextField.isFirstResponder)
    } else if formTextField == _accountNumberTextField {
      formTextField.validText =
        viewModel.isInputValid(
          formTextField.text ?? "",
          for: .accountNumber,
          editing: formTextField.isFirstResponder)
    } else if formTextField == _nameTextField {
      formTextField.validText =
        viewModel.isInputValid(
          formTextField.text ?? "",
          for: .name,
          editing: formTextField.isFirstResponder)
    } else if formTextField == _emailTextField {
      formTextField.validText =
        viewModel.isInputValid(
          formTextField.text ?? "",
          for: .email,
          editing: formTextField.isFirstResponder)
    } else {
      assert(
        false,
        "Shouldn't call for text field not managed by \(NSStringFromClass(STPAUBECSDebitFormView.self))"
      )
    }
  }

  /// :nodoc:
  @objc
  public override func systemLayoutSizeFitting(
    _ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
    verticalFittingPriority: UILayoutPriority
  ) -> CGSize {
    // UITextViews don't play nice with autolayout, so we have to add a temporary height constraint
    // to get this method to account for the full, non-scrollable size of _mandateLabel
    layoutIfNeeded()
    let tempConstraint = mandateLabel.heightAnchor.constraint(
      equalToConstant: mandateLabel.contentSize.height )
    tempConstraint.isActive = true
    let size = super.systemLayoutSizeFitting(
      targetSize, withHorizontalFittingPriority: horizontalFittingPriority,
      verticalFittingPriority: verticalFittingPriority)
    tempConstraint.isActive = false
    return size

  }

  func _defaultBSBLabelTextColor() -> UIColor {
    if #available(iOS 13.0, *) {
      return UIColor.secondaryLabel
    } else {
      // Fallback on earlier versions
      return UIColor.darkGray
    }
  }

  func _updateBSBLabel() {
    var isErrorString = false
    bsbLabel.text = viewModel.bsbLabel(
      forInput: _bsbNumberTextField.text, editing: _bsbNumberTextField.isFirstResponder ,
      isErrorString: &isErrorString)
    bsbLabel.textColor = isErrorString ? formTextErrorColor : _defaultBSBLabelTextColor()
  }

  // MARK: - STPMultiFormFieldDelegate
  func formTextFieldDidStartEditing(
    _ formTextField: STPFormTextField,
    inMultiForm multiFormField: STPMultiFormTextField
  ) {
    _updateValidText(for: formTextField)
    if formTextField == _bsbNumberTextField {
      _updateBSBLabel()
    }
  }

  func formTextFieldDidEndEditing(
    _ formTextField: STPFormTextField,
    inMultiForm multiFormField: STPMultiFormTextField
  ) {
    _updateValidText(for: formTextField)
    if formTextField == _bsbNumberTextField {
      _updateBSBLabel()
    }
  }

  func modifiedIncomingTextChange(
    _ input: NSAttributedString,
    for formTextField: STPFormTextField,
    inMultiForm multiFormField: STPMultiFormTextField
  ) -> NSAttributedString {
    if formTextField == _bsbNumberTextField {
      return NSAttributedString(
        string: viewModel.formattedString(forInput: input.string, in: .BSBNumber) ,
        attributes: _bsbNumberTextField.defaultTextAttributes)
    } else if formTextField == _accountNumberTextField {
      return NSAttributedString(
        string: viewModel.formattedString(forInput: input.string, in: .accountNumber) ,
        attributes: _accountNumberTextField.defaultTextAttributes)
    } else if formTextField == _nameTextField {
      return NSAttributedString(
        string: viewModel.formattedString(forInput: input.string, in: .name) ,
        attributes: _nameTextField.defaultTextAttributes)
    } else if formTextField == _emailTextField {
      return NSAttributedString(
        string: viewModel.formattedString(forInput: input.string, in: .email) ,
        attributes: _emailTextField.defaultTextAttributes)
    } else {
      assert(
        false,
        "Shouldn't call for text field not managed by \(NSStringFromClass(STPAUBECSDebitFormView.self))"
      )
      return input
    }
  }

  func formTextFieldTextDidChange(
    _ formTextField: STPFormTextField,
    inMultiForm multiFormField: STPMultiFormTextField
  ) {
    _updateValidText(for: formTextField)

    let hadCompletePaymentMethod = viewModel.paymentMethodParams != nil

    if formTextField == _bsbNumberTextField {
      viewModel.bsbNumber = formTextField.text

      _updateBSBLabel()
      bankIconView.image = viewModel.bankIcon(forInput: formTextField.text)

      // Since BSB number affects validity for the account number as well, we also need to update that field
      _updateValidText(for: _accountNumberTextField)

      if viewModel.isFieldComplete(
        withInput: formTextField.text ?? "", in: .BSBNumber, editing: formTextField.isFirstResponder
      ) {
        focusNextForm()
      }
    } else if formTextField == _accountNumberTextField {
      viewModel.accountNumber = formTextField.text
      if viewModel.isFieldComplete(
        withInput: formTextField.text ?? "", in: .accountNumber,
          editing: formTextField.isFirstResponder)
      {
        focusNextForm()
      }
    } else if formTextField == _nameTextField {
      viewModel.name = formTextField.text
    } else if formTextField == _emailTextField {
      viewModel.email = formTextField.text
    } else {
      assert(
        false,
        "Shouldn't call for text field not managed by \(NSStringFromClass(STPAUBECSDebitFormView.self))"
      )
    }

    let nowHasCompletePaymentMethod = viewModel.paymentMethodParams != nil
    if hadCompletePaymentMethod != nowHasCompletePaymentMethod {
      becsDebitFormDelegate?.auBECSDebitForm(
        self, didChangeToStateComplete: nowHasCompletePaymentMethod)
    }
  }

  func isFormFieldComplete(
    _ formTextField: STPFormTextField,
    inMultiForm multiFormField: STPMultiFormTextField
  ) -> Bool {
    if formTextField == _bsbNumberTextField {
      return viewModel.isFieldComplete(
        withInput: formTextField.text ?? "", in: .BSBNumber, editing: false)
    } else if formTextField == _accountNumberTextField {
      return viewModel.isFieldComplete(
        withInput: formTextField.text ?? "", in: .accountNumber, editing: false)
    } else if formTextField == _nameTextField {
      return viewModel.isFieldComplete(
        withInput: formTextField.text ?? "", in: .name, editing: false)
    } else if formTextField == _emailTextField {
      return viewModel.isFieldComplete(
        withInput: formTextField.text ?? "", in: .email, editing: false)
    } else {
      assert(
        false,
        "Shouldn't call for text field not managed by \(NSStringFromClass(STPAUBECSDebitFormView.self))"
      )
      return false
    }
  }

  // MARK: - UITextViewDelegate
  /// :nodoc:
  @objc
  public func textView(
    _ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange,
    interaction: UITextItemInteraction
  ) -> Bool {
    return true
  }

  // MARK: - STPFormTextFieldContainer (Overrides)
  /// :nodoc:
  @objc public override var formFont: UIFont {
    get {
      super.formFont
    }
    set {
      super.formFont = newValue
      labeledNameField.formLabelFont = newValue
      labeledEmailField.formLabelFont = newValue
    }
  }

  /// :nodoc:
  @objc public override var formTextColor: UIColor {
    get {
      super.formTextColor
    }
    set {
      super.formTextColor = newValue
      labeledNameField.formLabelTextColor = newValue
      labeledEmailField.formLabelTextColor = newValue
    }
  }
}

extension STPAUBECSDebitFormView {
  func nameTextField() -> STPFormTextField {
    return _nameTextField
  }

  func emailTextField() -> STPFormTextField {
    return _emailTextField
  }

  func bsbNumberTextField() -> STPFormTextField {
    return _bsbNumberTextField
  }

  func accountNumberTextField() -> STPFormTextField {
    return _accountNumberTextField
  }
}
