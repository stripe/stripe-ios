//
//  STPAddress.swift
//  Stripe
//
//  Created by Ben Guo on 4/13/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Contacts
import Foundation
import PassKit

/// What set of billing address information you need to collect from your user.
///
/// @note If the user is from a country that does not use zip/postal codes,
/// the user may not be asked for one regardless of this setting.
@objc
public enum STPBillingAddressFields: UInt {
  /// No billing address information
  case none
  /// Just request the user's billing postal code
  case postalCode
  /// Request the user's full billing address
  case full
  /// Just request the user's billing name
  case name
  /// Just request the user's billing ZIP (synonym for STPBillingAddressFieldsZip)
  @available(*, deprecated, message: "Use STPBillingAddressFields.postalCode instead")
  case zip
}

/// STPAddress Contains an address as represented by the Stripe API.
public class STPAddress: NSObject {
  /// The user's full name (e.g. "Jane Doe")
  @objc public var name: String?

  /// The first line of the user's street address (e.g. "123 Fake St")
  @objc public var line1: String?

  /// The apartment, floor number, etc of the user's street address (e.g. "Apartment 1A")
  @objc public var line2: String?

  /// The city in which the user resides (e.g. "San Francisco")
  @objc public var city: String?

  /// The state in which the user resides (e.g. "CA")
  @objc public var state: String?

  /// The postal code in which the user resides (e.g. "90210")
  @objc public var postalCode: String?

  /// The ISO country code of the address (e.g. "US")
  @objc public var country: String?

  /// The phone number of the address (e.g. "8885551212")
  @objc public var phone: String?

  /// The email of the address (e.g. "jane@doe.com")
  @objc public var email: String?

  @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

  /// When creating a charge on your backend, you can attach shipping information
  /// to prevent fraud on a physical good. You can use this method to turn your user's
  /// shipping address and selected shipping method into a hash suitable for attaching
  /// to a charge. You should pass this to your backend, and use it as the `shipping`
  /// parameter when creating a charge.
  /// - seealso: https://stripe.com/docs/api#create_charge-shipping
  /// - Parameters:
  ///   - address:  The user's shipping address. If nil, this method will return nil.
  ///   - method:   The user's selected shipping method. May be nil.
  @objc(shippingInfoForChargeWithAddress:shippingMethod:)
  public class func shippingInfoForCharge(
    with address: STPAddress?,
    shippingMethod method: PKShippingMethod?
  ) -> [AnyHashable: Any]? {
    guard let address = address else {
      return nil
    }

    var params: [AnyHashable: Any] = [:]
    params["name"] = address.name
    params["phone"] = address.phone
    params["carrier"] = method?.label
    // Re-use STPFormEncoder
    params["address"] = STPFormEncoder.dictionary(forObject: address)
    return params
  }

  /// Initializes an empty STPAddress.
  @objc
  public override init() {
    super.init()
  }

  /// Initializes a new STPAddress with data from STPPaymentMethodBillingDetails.
  /// - Parameter billingDetails: The STPPaymentMethodBillingDetails instance you want to populate the STPAddress from.
  /// - Returns: A new STPAddress instance with data copied from the passed in billing details.
  @objc
  public init(paymentMethodBillingDetails billingDetails: STPPaymentMethodBillingDetails) {
    super.init()
    name = billingDetails.name
    phone = billingDetails.phone
    email = billingDetails.email
    let pmAddress = billingDetails.address
    line1 = pmAddress?.line1
    line2 = pmAddress?.line2
    city = pmAddress?.city
    state = pmAddress?.state
    postalCode = pmAddress?.postalCode
    country = pmAddress?.country
  }

  /// Initializes a new STPAddress with data from an PassKit contact.
  /// - Parameter contact: The PassKit contact you want to populate the STPAddress from.
  /// - Returns: A new STPAddress instance with data copied from the passed in contact.
  @objc(initWithPKContact:)
  public init(pkContact contact: PKContact) {
    super.init()
    let nameComponents = contact.name
    if let nameComponents = nameComponents {
      givenName = stringIfHasContentsElseNil(nameComponents.givenName)
      familyName = stringIfHasContentsElseNil(nameComponents.familyName)

      name = stringIfHasContentsElseNil(
        PersonNameComponentsFormatter.localizedString(from: nameComponents, style: .default))
    }
    email = stringIfHasContentsElseNil(contact.emailAddress)
    if let phoneNumber = contact.phoneNumber {
      phone = sanitizedPhoneString(from: phoneNumber)
    } else {
      phone = nil
    }
    setAddressFromCNPostal(contact.postalAddress)
  }

  /// Generates a PassKit contact representation of this STPAddress.
  /// - Returns: A new PassKit contact with data copied from this STPAddress instance.
  @objc(PKContactValue)
  public func pkContactValue() -> PKContact {
    let contact = PKContact()
    var personName = PersonNameComponents()
    personName.givenName = firstName()
    personName.familyName = lastName()
    contact.name = personName
    contact.emailAddress = email
    let address = CNMutablePostalAddress()
    address.street = street() ?? ""
    address.city = city ?? ""
    address.state = state ?? ""
    address.postalCode = postalCode ?? ""
    address.country = country ?? ""
    contact.postalAddress = address
    contact.phoneNumber = CNPhoneNumber(stringValue: phone ?? "")
    return contact
  }

  /// Initializes a new STPAddress with a contact from the Contacts framework.
  /// - Parameter contact: The CNContact you want to populate the STPAddress from.
  /// - Returns: A new STPAddress instance with data copied from the passed in contact.
  @objc(initWithCNContact:)
  public init(cnContact contact: CNContact) {
    super.init()
    givenName = stringIfHasContentsElseNil(contact.givenName)
    familyName = stringIfHasContentsElseNil(contact.familyName)
    name = stringIfHasContentsElseNil(
      CNContactFormatter.string(
        from: contact,
        style: .fullName))
    email = stringIfHasContentsElseNil(contact.emailAddresses.first?.value as String?)
    if let value1 = contact.phoneNumbers.first?.value {
      phone = sanitizedPhoneString(from: value1)
    }

    if let value1 = contact.postalAddresses.first?.value {
      setAddressFromCNPostal(value1)
    }
  }

  /// Checks if this STPAddress has the level of valid address information
  /// required by the passed in setting.
  /// - Parameter requiredFields: The required level of billing address information to
  /// check against.
  /// - Returns: YES if this address contains at least the necessary information,
  /// NO otherwise.
  @objc
  public func containsRequiredFields(_ requiredFields: STPBillingAddressFields) -> Bool {
    switch requiredFields {
    case .none:
      return true
    case .postalCode:
      return STPPostalCodeValidator.validationState(
        forPostalCode: postalCode,
        countryCode: country) == .valid
    case .full:
      return hasValidPostalAddress()
    case .name:
      return (name?.count ?? 0) > 0
    default:
      fatalError()
    }
  }

  /// Checks if this STPAddress has any content (possibly invalid) in any of the
  /// desired billing address fields.
  /// Where `containsRequiredFields:` validates that this STPAddress contains valid data in
  /// all of the required fields, this method checks for the existence of *any* data.
  /// For example, if `desiredFields` is `STPBillingAddressFieldsZip`, this will check
  /// if the postalCode is empty.
  /// Note: When `desiredFields == STPBillingAddressFieldsNone`, this method always returns
  /// NO.
  /// @parameter desiredFields The billing address information the caller is interested in.
  /// - Returns: YES if there is any data in this STPAddress that's relevant for those fields.
  @objc(containsContentForBillingAddressFields:)
  public func containsContent(for desiredFields: STPBillingAddressFields) -> Bool {
    switch desiredFields {
    case .none:
      return false
    case .postalCode:
      return (postalCode?.count ?? 0) > 0
    case .full:
      return hasPartialPostalAddress()
    case .name:
      return (name?.count ?? 0) > 0
    default:
      fatalError()
    }
  }

  /// Checks if this STPAddress has the level of valid address information
  /// required by the passed in setting.
  /// Note: When `requiredFields == nil`, this method always returns
  /// YES.
  /// - Parameter requiredFields: The required shipping address information to check against.
  /// - Returns: YES if this address contains at least the necessary information,
  /// NO otherwise.
  @objc
  public func containsRequiredShippingAddressFields(_ requiredFields: Set<STPContactField>?)
    -> Bool
  {
    guard let requiredFields = requiredFields else {
      return true
    }
    var containsFields = true

    if requiredFields.contains(.name) {
      containsFields = containsFields && (name?.count ?? 0) > 0
    }
    if requiredFields.contains(.emailAddress) {
      containsFields = containsFields && STPEmailAddressValidator.stringIsValidEmailAddress(email)
    }
    if requiredFields.contains(.phoneNumber) {
      containsFields =
        containsFields
        && STPPhoneNumberValidator.stringIsValidPhoneNumber(phone ?? "", forCountryCode: country)
    }
    if requiredFields.contains(.postalAddress) {
      containsFields = containsFields && hasValidPostalAddress()
    }
    return containsFields
  }

  /// Checks if this STPAddress has any content (possibly invalid) in any of the
  /// desired shipping address fields.
  /// Where `containsRequiredShippingAddressFields:` validates that this STPAddress
  /// contains valid data in all of the required fields, this method checks for the
  /// existence of *any* data.
  /// Note: When `desiredFields == nil`, this method always returns
  /// NO.
  /// @parameter desiredFields The shipping address information the caller is interested in.
  /// - Returns: YES if there is any data in this STPAddress that's relevant for those fields.
  @objc
  public func containsContent(forShippingAddressFields desiredFields: Set<STPContactField>?)
    -> Bool
  {
    guard let desiredFields = desiredFields else {
      return false
    }
    return (desiredFields.contains(.name) && (name?.count ?? 0) > 0)
      || (desiredFields.contains(.emailAddress) && (email?.count ?? 0) > 0)
      || (desiredFields.contains(.phoneNumber) && (phone?.count ?? 0) > 0)
      || (desiredFields.contains(.postalAddress) && hasPartialPostalAddress())
  }

  /// Converts an STPBillingAddressFields enum value into the closest equivalent
  /// representation of PKContactField options
  /// - Parameter billingAddressFields: Stripe billing address fields enum value to convert.
  /// - Returns: The closest representation of the billing address requirement as
  /// a PKContactField value.
  @objc(applePayContactFieldsFromBillingAddressFields:)
  public class func applePayContactFields(from billingAddressFields: STPBillingAddressFields)
    -> Set<PKContactField>
  {
    switch billingAddressFields {
    case .none:
      return Set<PKContactField>([])
    case .postalCode, .full:
      return Set<PKContactField>([.name, .postalAddress])
    case .name:
      return Set<PKContactField>([.name])
    case .zip:
      return Set()
    @unknown default:
      fatalError()
    }
  }

  /// Converts a set of STPContactField values into the closest equivalent
  /// representation of PKContactField options
  /// - Parameter contactFields: Stripe contact fields values to convert.
  /// - Returns: The closest representation of the contact fields as
  /// a PKContactField value.
  @objc
  public class func pkContactFields(
    fromStripeContactFields contactFields: Set<STPContactField>?
  ) -> Set<PKContactField>? {
    guard let contactFields = contactFields else {
      return nil
    }

    var pkFields: Set<PKContactField> = Set()
    let stripeToPayKitContactMap: [STPContactField: PKContactField] = [
      STPContactField.postalAddress: PKContactField.postalAddress,
      STPContactField.emailAddress: PKContactField.emailAddress,
      STPContactField.phoneNumber: PKContactField.phoneNumber,
      STPContactField.name: PKContactField.name,
    ]

    for contactField in contactFields {
      if let convertedField = stripeToPayKitContactMap[contactField] {
        pkFields.insert(convertedField)
      }
    }
    return pkFields
  }

  @objc public private(set) var allResponseFields: [AnyHashable: Any] = [:]
  private var givenName: String?
  private var familyName: String?

  private func sanitizedPhoneString(from phoneNumber: CNPhoneNumber) -> String? {
    return stringIfHasContentsElseNil(
      STPCardValidator.sanitizedNumericString(for: phoneNumber.stringValue))
  }

  private func setAddressFromCNPostal(_ address: CNPostalAddress?) {
    line1 = stringIfHasContentsElseNil(address?.street)
    city = stringIfHasContentsElseNil(address?.city)
    state = stringIfHasContentsElseNil(address?.state)
    postalCode = stringIfHasContentsElseNil(address?.postalCode)
    country = stringIfHasContentsElseNil(address?.isoCountryCode.uppercased())
  }

  private func firstName() -> String? {
    if let givenName = givenName {
      return givenName
    } else {
      let components = name?.components(separatedBy: " ")
      return components?.first
    }
  }

  private func lastName() -> String? {
    if let familyName = familyName {
      return familyName
    } else {
      if let components = name?.components(separatedBy: " "),
        let firstName = components.first,
        let lastName = name?.replacingOccurrences(of: firstName, with: "").trimmingCharacters(
          in: .whitespaces)
      {
        return stringIfHasContentsElseNil(lastName)
      }
      return nil
    }
  }

  private func street() -> String? {
    var street: String?
    if let line1 = line1 {
      street = "" + line1
    }
    if let line2 = line2 {
      street = [street ?? "", line2].joined(separator: " ")
    }
    return street
  }

  private func hasValidPostalAddress() -> Bool {
    return (line1?.count ?? 0) > 0 && (city?.count ?? 0) > 0 && (country?.count ?? 0) > 0
      && ((state?.count ?? 0) > 0 || !(country == "US"))
      && (STPPostalCodeValidator.validationState(
        forPostalCode: postalCode,
        countryCode: country) == .valid)
  }

  /// Does this STPAddress contain any data in the postal address fields?
  /// If they are all empty or nil, returns NO. Even a single character in a
  /// single field will return YES.
  private func hasPartialPostalAddress() -> Bool {
    return (line1?.count ?? 0) > 0 || (line2?.count ?? 0) > 0 || (city?.count ?? 0) > 0
      || (country?.count ?? 0) > 0 || (state?.count ?? 0) > 0 || (postalCode?.count ?? 0) > 0
  }
}

extension STPAddress: STPAPIResponseDecodable {
  @objc
  public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
    guard let dict = response else {
      return nil
    }

    let address = STPAddress()
    address.allResponseFields = dict
    /// all properties are nullable
    address.city = dict["city"] as? String
    address.country = dict["country"] as? String
    address.line1 = dict["line1"] as? String
    address.line2 = dict["line2"] as? String
    address.postalCode = dict["postal_code"] as? String
    address.state = dict["state"] as? String
    return address as? Self
  }
}

extension STPAddress: STPFormEncodable {

  @objc
  public class func rootObjectName() -> String? {
    return nil
  }

  @objc
  public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
    // Paralleling `decodedObjectFromAPIResponse:`, *only* the 6 address fields are encoded
    // If this changes, shippingInfoForChargeWithAddress:shippingMethod: might break
    return [
      NSStringFromSelector(#selector(getter:line1)): "line1",
      NSStringFromSelector(#selector(getter:line2)): "line2",
      NSStringFromSelector(#selector(getter:city)): "city",
      NSStringFromSelector(#selector(getter:state)): "state",
      NSStringFromSelector(#selector(getter:CNMutablePostalAddress.postalCode)): "postal_code",
      NSStringFromSelector(#selector(getter:country)): "country",
    ]
  }

}

extension STPAddress: NSCopying {
  /// :nodoc:
  @objc
  public func copy(with zone: NSZone? = nil) -> Any {
    let copyAddress = STPAddress()

    // Name might be stored as full name in _name, or split between given/family name
    // access ivars directly and explicitly copy the instances.
    copyAddress.name = name
    copyAddress.givenName = givenName
    copyAddress.familyName = familyName

    copyAddress.line1 = line1
    copyAddress.line2 = line2
    copyAddress.city = city
    copyAddress.state = state
    copyAddress.postalCode = postalCode
    copyAddress.country = country

    copyAddress.phone = phone
    copyAddress.email = email

    copyAddress.allResponseFields = allResponseFields

    return copyAddress
  }
}

func stringIfHasContentsElseNil(_ string: String?) ->  // MARK: -
  String?
{
  guard let string = string,
    !string.isEmpty
  else {
    return nil
  }
  return string
}
