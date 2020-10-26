//
//  STPSourceParams.swift
//  Stripe
//
//  Created by Ben Guo on 1/23/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create a Source object.
/// - seealso: https://stripe.com/docs/api#create_source
public class STPSourceParams: NSObject, STPFormEncodable, NSCopying {
  @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]
  var redirectMerchantName: String?

  /// The type of the source to create. Required.

  @objc public var type: STPSourceType {
    get {
      return STPSource.type(from: rawTypeString ?? "")
    }
    set(type) {
      // If setting unknown and we're already unknown, don't want to override raw value
      if type != self.type {
        rawTypeString = STPSource.string(from: type)
      }
    }
  }
  /// The raw underlying type string sent to the server.
  /// Generally you should use `type` instead unless you have a reason not to.
  /// You can use this if you want to create a param of a type not yet supported
  /// by the current version of the SDK's `STPSourceType` enum.
  /// Setting this to a value not known by the SDK causes `type` to
  /// return `STPSourceTypeUnknown`
  @objc public var rawTypeString: String?
  /// A positive integer in the smallest currency unit representing the
  /// amount to charge the customer (e.g., @1099 for a €10.99 payment).
  /// Required for `single_use` sources.
  @objc public var amount: NSNumber?
  /// The currency associated with the source. This is the currency for which the source
  /// will be chargeable once ready.
  @objc public var currency: String?
  /// The authentication flow of the source to create. `flow` may be "redirect",
  /// "receiver", "verification", or "none". It is generally inferred unless a type
  /// supports multiple flows.
  @objc public var flow: STPSourceFlow
  /// A set of key/value pairs that you can attach to a source object.
  @objc public var metadata: [AnyHashable: Any]?
  /// Information about the owner of the payment instrument. May be used or required
  /// by particular source types.
  @objc public var owner: [AnyHashable: Any]?
  /// Parameters required for the redirect flow. Required if the source is
  /// authenticated by a redirect (`flow` is "redirect").
  @objc public var redirect: [AnyHashable: Any]?
  /// An optional token used to create the source. When passed, token properties will
  /// override source parameters.
  @objc var token: String?
  /// Whether this source should be reusable or not. `usage` may be "reusable" or
  /// "single_use". Some source types may or may not be reusable by construction,
  /// while other may leave the option at creation.
  @objc public var usage: STPSourceUsage

  override required init() {
    rawTypeString = ""
    flow = .unknown
    usage = .unknown
    additionalAPIParameters = [:]
    super.init()
  }
}

// MARK: - Constructors
extension STPSourceParams {
  /// Creates params for a Bancontact source.
  /// - seealso: https://stripe.com/docs/bancontact#create-source
  /// - Parameters:
  ///   - amount:               The amount to charge the customer in EUR.
  ///   - name:                 The full name of the account holder.
  ///   - returnURL:            The URL the customer should be redirected to after
  /// they have successfully verified the payment.
  ///   - statementDescriptor:  (Optional) A custom statement descriptor for
  /// the payment.
  /// @note The currency for Bancontact must be "eur". This will be set automatically
  /// for you.
  /// - Returns: an STPSourceParams object populated with the provided values.
  @objc
  public class func bancontactParams(
    withAmount amount: Int,
    name: String,
    returnURL: String,
    statementDescriptor: String?
  ) -> STPSourceParams {
    let params = self.init()
    params.type = .bancontact
    params.amount = NSNumber(value: amount)
    params.currency = "eur"  // Bancontact must always use eur
    params.owner = [
      "name": name
    ]
    params.redirect = [
      "return_url": returnURL
    ]
    if let statementDescriptor = statementDescriptor {
      params.additionalAPIParameters = [
        "bancontact": [
          "statement_descriptor": statementDescriptor
        ]
      ]
    }
    return params
  }

  /// Creates params for a Card source.
  /// - seealso: https://stripe.com/docs/sources/cards#create-source
  /// - Parameter card:        An object containing the user's card details
  /// - Returns: an STPSourceParams object populated with the provided card details.
  @objc
  public class func cardParams(withCard card: STPCardParams) -> STPSourceParams {
    let params = self.init()
    params.type = .card
    let keyPairs = STPFormEncoder.dictionary(forObject: card)["card"] as? [AnyHashable: Any]
    var cardDict: [AnyHashable: Any] = [:]
    let cardKeys = ["number", "cvc", "exp_month", "exp_year"]
    for key in cardKeys {
      if let keyPair = keyPairs?[key] {
        cardDict[key] = keyPair
      }
    }
    params.additionalAPIParameters = [
      "card": cardDict
    ]
    var addressDict: [AnyHashable: Any] = [:]
    let addressKeyMapping = [
      "address_line1": "line1",
      "address_line2": "line2",
      "address_city": "city",
      "address_state": "state",
      "address_zip": "postal_code",
      "address_country": "country",
    ]
    for key in addressKeyMapping.keys {
      if let newKey = addressKeyMapping[key],
        let keyPair = keyPairs?[key]
      {
        addressDict[newKey] = keyPair
      }
    }
    var ownerDict: [AnyHashable: Any] = [:]
    ownerDict["address"] = addressDict
    ownerDict["name"] = card.name
    params.owner = ownerDict
    return params
  }

  /// Creates params for a Giropay source.
  /// - seealso: https://stripe.com/docs/sources/giropay#create-source
  /// - Parameters:
  ///   - amount:               The amount to charge the customer in EUR.
  ///   - name:                 The full name of the account holder.
  ///   - returnURL:            The URL the customer should be redirected to after
  /// they have successfully verified the payment.
  ///   - statementDescriptor:  (Optional) A custom statement descriptor for
  /// the payment.
  /// @note The currency for Giropay must be "eur". This will be set automatically
  /// for you.
  /// - Returns: an STPSourceParams object populated with the provided values.
  @objc
  public class func giropayParams(
    withAmount amount: Int,
    name: String,
    returnURL: String,
    statementDescriptor: String?
  ) -> STPSourceParams {
    let params = self.init()
    params.type = .giropay
    params.amount = NSNumber(value: amount)
    params.currency = "eur"  // Giropay must always use eur
    params.owner = [
      "name": name
    ]
    params.redirect = [
      "return_url": returnURL
    ]
    if let statementDescriptor = statementDescriptor {
      params.additionalAPIParameters = [
        "giropay": [
          "statement_descriptor": statementDescriptor
        ]
      ]
    }
    return params
  }

  /// Creates params for an iDEAL source.
  /// - seealso: https://stripe.com/docs/sources/ideal#create-source
  /// - Parameters:
  ///   - amount:               The amount to charge the customer in EUR.
  ///   - name:                 (Optional) The full name of the account holder.
  ///   - returnURL:            The URL the customer should be redirected to after
  /// they have successfully verified the payment.
  ///   - statementDescriptor:  (Optional) A custom statement descriptor for t
  /// he payment.
  ///   - bank:                 (Optional) The customer's bank.
  /// @note The currency for iDEAL must be "eur". This will be set automatically
  /// for you.
  /// - Returns: an STPSourceParams object populated with the provided values.
  @objc
  public class func idealParams(
    withAmount amount: Int,
    name: String?,
    returnURL: String,
    statementDescriptor: String?,
    bank: String?
  ) -> STPSourceParams {
    let params = self.init()
    params.type = .iDEAL
    params.amount = NSNumber(value: amount)
    params.currency = "eur"  // iDEAL must always use eur
    if (name?.count ?? 0) > 0 {
      params.owner = [
        "name": name ?? ""
      ]
    }
    params.redirect = [
      "return_url": returnURL
    ]
    if (statementDescriptor?.count ?? 0) > 0 || (bank?.count ?? 0) > 0 {
      var idealDict: [AnyHashable: Any] = [:]
      idealDict["statement_descriptor"] =
        (((statementDescriptor?.count ?? 0) > 0) ? statementDescriptor : nil) ?? ""
      idealDict["bank"] = (((bank?.count ?? 0) > 0) ? bank : nil) ?? ""
      params.additionalAPIParameters = [
        "ideal": idealDict
      ]
    }
    return params
  }

  /// Creates params for a SEPA Debit source.
  /// - seealso: https://stripe.com/docs/sources/sepa-debit#create-source
  /// - Parameters:
  ///   - name:         The full name of the account holder.
  ///   - iban:         The IBAN number for the bank account you wish to debit.
  ///   - addressLine1: (Optional) The bank account holder's first address line.
  ///   - city:         (Optional) The bank account holder's city.
  ///   - postalCode:   (Optional) The bank account holder's postal code.
  ///   - country:      (Optional) The bank account holder's two-letter
  /// country code.
  /// @note The currency for SEPA Debit must be "eur". This will be set automatically
  /// for you.
  /// - Returns: an STPSourceParams object populated with the provided values.
  @objc
  public class func sepaDebitParams(
    withName name: String,
    iban: String,
    addressLine1: String?,
    city: String?,
    postalCode: String?,
    country: String?
  ) -> STPSourceParams {
    let params = self.init()
    params.type = .SEPADebit
    params.currency = "eur"  // SEPA Debit must always use eur

    var owner: [AnyHashable: Any] = [:]
    owner["name"] = name

    var address: [String: String]? = [:]
    address?["city"] = city
    address?["postal_code"] = postalCode
    address?["country"] = country
    address?["line1"] = addressLine1

    if (address?.count ?? 0) > 0 {
      if let address = address {
        owner["address"] = address
      }
    }

    params.owner = owner
    params.additionalAPIParameters = [
      "sepa_debit": [
        "iban": iban
      ]
    ]
    return params
  }

  /// Creates params for a Sofort source.
  /// - seealso: https://stripe.com/docs/sources/sofort#create-source
  /// - Parameters:
  ///   - amount:               The amount to charge the customer in EUR.
  ///   - returnURL:            The URL the customer should be redirected to after
  /// they have successfully verified the payment.
  ///   - country:              The country code of the customer's bank.
  ///   - statementDescriptor:  (Optional) A custom statement descriptor for
  /// the payment.
  /// @note The currency for Sofort must be "eur". This will be set automatically
  /// for you.
  /// - Returns: an STPSourceParams object populated with the provided values.
  @objc
  public class func sofortParams(
    withAmount amount: Int,
    returnURL: String,
    country: String,
    statementDescriptor: String?
  ) -> STPSourceParams {
    let params = self.init()
    params.type = .sofort
    params.amount = NSNumber(value: amount)
    params.currency = "eur"  // sofort must always use eur
    params.redirect = [
      "return_url": returnURL
    ]
    var sofortDict: [AnyHashable: Any] = [:]
    sofortDict["country"] = country
    if let statementDescriptor = statementDescriptor {
      sofortDict["statement_descriptor"] = statementDescriptor
    }
    params.additionalAPIParameters = [
      "sofort": sofortDict
    ]
    return params
  }

  /// Creates params for a Klarna source.
  /// - seealso: https://stripe.com/docs/sources/klarna#create-source
  /// - Parameters:
  ///   - returnURL:            The URL the customer should be redirected to after
  /// they have successfully verified the payment.
  ///   - currency:             The currency the payment is being created in.
  ///   - purchaseCountry:      The ISO-3166 2-letter country code of the customer's location.
  ///   - items:                An array of STPKlarnaLineItems. Klarna will present these on the confirmation
  /// page. The total amount charged will be a sum of the `totalAmount` of each of these items.
  ///   - customPaymentMethods: Required for customers located in the US. This determines whether Pay Later and/or Slice It
  /// is offered to a US customer.
  ///   - address:              An STPAddress for the customer. At a minimum, an `email`, `line1`, `postalCode`, `city`, and `country` must be provided.
  /// The address' `name` will be ignored in favor of the `firstName and `lastName` parameters.
  ///   - firstName:            The customer's first name.
  ///   - lastName:             The customer's last name.
  /// If the provided information is missing a line1, postal code, city, email, or first/last name, or if the country code is
  /// outside the specified country, no address information will be sent to Klarna, and Klarna will prompt the customer to provide their address.
  ///   - dateOfBirth:           The customer's date of birth. This will be used by Klarna for a credit check in some EU countries.
  /// The optional fields (address, firstName, lastName, and dateOfBirth) can be provided to skip Klarna's customer information form.
  /// If this information is missing, Klarna will prompt the customer for these values during checkout.
  /// Be careful with this option: If the provided information is invalid,
  /// Klarna may reject the transaction without giving the customer a chance to correct it.
  /// - Returns: an STPSourceParams object populated with the provided values.
  @available(swift, obsoleted: 1.0)
  @objc(
    klarnaParamsWithReturnURL:currency:purchaseCountry:items:customPaymentMethods:billingAddress:
    billingFirstName:billingLastName:billingDOB:
  )
  public class func objc_klarnaParams(
    withReturnURL returnURL: String,
    currency: String,
    purchaseCountry: String,
    items: [STPKlarnaLineItem],
    customPaymentMethods: [NSNumber],
    billingAddress address: STPAddress?,
    billingFirstName firstName: String?,
    billingLastName lastName: String?,
    billingDOB dateOfBirth: STPDateOfBirth?
  ) -> STPSourceParams {
    let customPaymentMethods: [STPKlarnaPaymentMethods] = customPaymentMethods.map {
      STPKlarnaPaymentMethods(rawValue: $0.intValue) ?? STPKlarnaPaymentMethods.none
    }
    return klarnaParams(
      withReturnURL: returnURL, currency: currency, purchaseCountry: purchaseCountry, items: items,
      customPaymentMethods: customPaymentMethods, billingAddress: address,
      billingFirstName: firstName, billingLastName: lastName, billingDOB: dateOfBirth)
  }

  /// Creates params for a Klarna source.
  /// - seealso: https://stripe.com/docs/sources/klarna#create-source
  /// - Parameters:
  ///   - returnURL:            The URL the customer should be redirected to after
  /// they have successfully verified the payment.
  ///   - currency:             The currency the payment is being created in.
  ///   - purchaseCountry:      The ISO-3166 2-letter country code of the customer's location.
  ///   - items:                An array of STPKlarnaLineItems. Klarna will present these on the confirmation
  /// page. The total amount charged will be a sum of the `totalAmount` of each of these items.
  ///   - customPaymentMethods: Required for customers located in the US. This determines whether Pay Later and/or Slice It
  /// is offered to a US customer.
  ///   - address:              An STPAddress for the customer. At a minimum, an `email`, `line1`, `postalCode`, `city`, and `country` must be provided.
  /// The address' `name` will be ignored in favor of the `firstName and `lastName` parameters.
  ///   - firstName:            The customer's first name.
  ///   - lastName:             The customer's last name.
  /// If the provided information is missing a line1, postal code, city, email, or first/last name, or if the country code is
  /// outside the specified country, no address information will be sent to Klarna, and Klarna will prompt the customer to provide their address.
  ///   - dateOfBirth:           The customer's date of birth. This will be used by Klarna for a credit check in some EU countries.
  /// The optional fields (address, firstName, lastName, and dateOfBirth) can be provided to skip Klarna's customer information form.
  /// If this information is missing, Klarna will prompt the customer for these values during checkout.
  /// Be careful with this option: If the provided information is invalid,
  /// Klarna may reject the transaction without giving the customer a chance to correct it.
  /// - Returns: an STPSourceParams object populated with the provided values.
  public class func klarnaParams(
    withReturnURL returnURL: String,
    currency: String,
    purchaseCountry: String,
    items: [STPKlarnaLineItem],
    customPaymentMethods: [STPKlarnaPaymentMethods],
    billingAddress address: STPAddress? = nil,
    billingFirstName firstName: String? = nil,
    billingLastName lastName: String? = nil,
    billingDOB dateOfBirth: STPDateOfBirth? = nil
  ) -> STPSourceParams {
    let params = self.init()
    params.type = .klarna
    params.currency = currency
    params.redirect = [
      "return_url": returnURL
    ]
    var additionalAPIParameters: [AnyHashable: Any] = [:]

    var klarnaDict: [AnyHashable: Any] = [:]
    klarnaDict["product"] = "payment"
    klarnaDict["purchase_country"] = purchaseCountry

    if let address = address {
      if (address.country == purchaseCountry) && address.line1 != nil && address.postalCode != nil
        && address.city != nil && address.email != nil && firstName != nil && lastName != nil
      {
        klarnaDict["first_name"] = firstName
        klarnaDict["last_name"] = lastName

        var ownerDict: [AnyHashable: Any] = [:]
        var addressDict: [AnyHashable: Any] = [:]

        addressDict["line1"] = address.line1 ?? ""
        addressDict["line2"] = address.line2 ?? ""
        addressDict["city"] = address.city ?? ""
        addressDict["state"] = address.state ?? ""
        addressDict["postal_code"] = address.postalCode ?? ""
        addressDict["country"] = address.country ?? ""

        ownerDict["address"] = addressDict
        ownerDict["phone"] = address.phone ?? ""
        ownerDict["email"] = address.email ?? ""
        additionalAPIParameters["owner"] = ownerDict
      }
    }

    if let dateOfBirth = dateOfBirth {
      klarnaDict["owner_dob_day"] = String(format: "%02ld", dateOfBirth.day)
      klarnaDict["owner_dob_month"] = String(format: "%02ld", dateOfBirth.month)
      klarnaDict["owner_dob_year"] = String(format: "%li", dateOfBirth.year)
    }

    var amount = 0
    let sourceOrderItems = NSMutableArray()
    for item in items {
      var itemType: String?
      switch item.itemType {
      case .SKU:
        itemType = "sku"
      case .tax:
        itemType = "tax"
      case .shipping:
        itemType = "shipping"
      default:
        break
      }
      if let quantity1 = item.quantity, let totalAmount1 = item.totalAmount {
        sourceOrderItems.add([
          "type": itemType ?? "",
          "description": item.itemDescription ?? "",
          "quantity": quantity1,
          "amount": totalAmount1,
          "currency": currency,
        ])
      }
      amount = Int(item.totalAmount?.uint32Value ?? 0) + amount
    }
    params.amount = NSNumber(value: amount)

    if !customPaymentMethods.isEmpty {
      let customPaymentMethodsArray = NSMutableArray()
      if customPaymentMethods.contains(.payIn4)
        || customPaymentMethods.contains(.payIn4OrInstallments)
      {
        customPaymentMethodsArray.add("payin4")
      }
      if customPaymentMethods.contains(.installments)
        || customPaymentMethods.contains(.payIn4OrInstallments)
      {
        customPaymentMethodsArray.add("installments")
      }
      klarnaDict["custom_payment_methods"] = customPaymentMethodsArray.componentsJoined(by: ",")
    }

    additionalAPIParameters["source_order"] = [
      "items": sourceOrderItems
    ]
    additionalAPIParameters["klarna"] = klarnaDict
    additionalAPIParameters["flow"] = "redirect"

    params.additionalAPIParameters = additionalAPIParameters
    return params
  }

  /// Creates params for a Klarna source.
  /// - seealso: https://stripe.com/docs/sources/klarna#create-source
  /// - Parameters:
  ///   - returnURL:            The URL the customer should be redirected to after
  /// they have successfully verified the payment.
  ///   - currency:             The currency the payment is being created in.
  ///   - purchaseCountry:      The ISO-3166 2-letter country code of the customer's location.
  ///   - items:                An array of STPKlarnaLineItems. Klarna will present these in the confirmation
  /// dialog. The total amount charged will be a sum of the `totalAmount` of each of these items.
  ///   - customPaymentMethods: Required for customers located in the US. This determines whether Pay Later and/or Slice It
  /// is offered to a US customer.
  /// - Returns: an STPSourceParams object populated with the provided values.
  @available(swift, obsoleted: 1.0)
  @objc(klarnaParamsWithReturnURL:currency:purchaseCountry:items:customPaymentMethods:)
  public class func objc_klarnaParams(
    withReturnURL returnURL: String,
    currency: String,
    purchaseCountry: String,
    items: [STPKlarnaLineItem],
    customPaymentMethods: [NSNumber]
  ) -> STPSourceParams {
    return self.klarnaParams(
      withReturnURL: returnURL, currency: currency, purchaseCountry: purchaseCountry, items: items,
      customPaymentMethods: customPaymentMethods.map({
        STPKlarnaPaymentMethods(rawValue: $0.intValue) ?? .none
      }), billingAddress: nil, billingFirstName: "", billingLastName: "", billingDOB: nil)
  }

  /// Creates params for a Klarna source.
  /// - seealso: https://stripe.com/docs/sources/klarna#create-source
  /// - Parameters:
  ///   - returnURL:            The URL the customer should be redirected to after
  /// they have successfully verified the payment.
  ///   - currency:             The currency the payment is being created in.
  ///   - purchaseCountry:      The ISO-3166 2-letter country code of the customer's location.
  ///   - items:                An array of STPKlarnaLineItems. Klarna will present these in the confirmation
  /// dialog. The total amount charged will be a sum of the `totalAmount` of each of these items.
  ///   - customPaymentMethods: Required for customers located in the US. This determines whether Pay Later and/or Slice It
  /// is offered to a US customer.
  /// - Returns: an STPSourceParams object populated with the provided values.
  public class func klarnaParams(
    withReturnURL returnURL: String,
    currency: String,
    purchaseCountry: String,
    items: [STPKlarnaLineItem],
    customPaymentMethods: [STPKlarnaPaymentMethods]
  ) -> STPSourceParams {
    return self.klarnaParams(
      withReturnURL: returnURL, currency: currency, purchaseCountry: purchaseCountry, items: items,
      customPaymentMethods: customPaymentMethods, billingAddress: nil, billingFirstName: "",
      billingLastName: "", billingDOB: nil)
  }

  /// Creates params for a 3DS source.
  /// - seealso: https://stripe.com/docs/sources/three-d-secure#create-3ds-source
  /// - Parameters:
  ///   - amount:      The amount to charge the customer.
  ///   - currency:    The currency the payment is being created in.
  ///   - returnURL:   The URL the customer should be redirected to after they have
  /// successfully verified the payment.
  ///   - card:        The ID of the card source.
  /// - Returns: an STPSourceParams object populated with the provided card details.
  @objc
  public class func threeDSecureParams(
    withAmount amount: Int,
    currency: String,
    returnURL: String,
    card: String
  ) -> STPSourceParams {
    let params = self.init()
    params.type = .threeDSecure
    params.amount = NSNumber(value: amount)
    params.currency = currency
    params.additionalAPIParameters = [
      "three_d_secure": [
        "card": card
      ]
    ]
    params.redirect = [
      "return_url": returnURL
    ]
    return params
  }

  /// Creates params for a single-use Alipay source
  /// - seealso: https://stripe.com/docs/sources/alipay#create-source
  /// - Parameters:
  ///   - amount:      The amount to charge the customer.
  ///   - currency:    The currency the payment is being created in.
  ///   - returnURL:   The URL the customer should be redirected to after they have
  /// successfully verified the payment.
  /// - Returns: An STPSourceParams object populated with the provided values
  @objc
  public class func alipayParams(
    withAmount amount: Int,
    currency: String,
    returnURL: String
  ) -> STPSourceParams {
    let params = self.init()
    params.type = .alipay
    params.amount = NSNumber(value: amount)
    params.currency = currency
    params.redirect = [
      "return_url": returnURL
    ]

    let bundleID = Bundle.main.bundleIdentifier
    let versionKey = Bundle.stp_applicationVersion()
    if bundleID != nil && versionKey != nil {
      params.additionalAPIParameters = [
        "alipay": [
          "app_bundle_id": bundleID ?? "",
          "app_version_key": versionKey ?? "",
        ]
      ]
    }
    return params
  }

  /// Creates params for a reusable Alipay source
  /// - seealso: https://stripe.com/docs/sources/alipay#create-source
  /// - Parameters:
  ///   - currency:    The currency the payment is being created in.
  ///   - returnURL:   The URL the customer should be redirected to after they have
  /// successfully verified the payment.
  /// - Returns: An STPSourceParams object populated with the provided values
  @objc
  public class func alipayReusableParams(
    withCurrency currency: String,
    returnURL: String
  ) -> STPSourceParams {
    let params = self.init()
    params.type = .alipay
    params.currency = currency
    params.redirect = [
      "return_url": returnURL
    ]
    params.usage = .reusable

    return params
  }

  /// Creates params for a P24 source
  /// - seealso: https://stripe.com/docs/sources/p24#create-source
  /// - Parameters:
  ///   - amount:      The amount to charge the customer.
  ///   - currency:    The currency the payment is being created in (this must be
  /// EUR or PLN)
  ///   - email:       The email address of the account holder.
  ///   - name:        The full name of the account holder (optional).
  ///   - returnURL:   The URL the customer should be redirected to after they have
  /// - Returns: An STPSourceParams object populated with the provided values.
  @objc
  public class func p24Params(
    withAmount amount: Int,
    currency: String,
    email: String,
    name: String?,
    returnURL: String
  ) -> STPSourceParams {
    let params = self.init()
    params.type = .P24
    params.amount = NSNumber(value: amount)
    params.currency = currency

    var ownerDict = [
      "email": email
    ]
    if let name = name {
      ownerDict["name"] = name
    }
    params.owner = ownerDict
    params.redirect = [
      "return_url": returnURL
    ]
    return params
  }

  /// Creates params for a card source created from Visa Checkout.
  /// - seealso: https://stripe.com/docs/visa-checkout
  /// @note Creating an STPSource with these params will give you a
  /// source with type == STPSourceTypeCard
  /// - Parameter callId: The callId property from a `VisaCheckoutResult` object.
  /// - Returns: An STPSourceParams object populated with the provided values.
  @objc
  public class func visaCheckoutParams(withCallId callId: String) -> STPSourceParams {
    let params = self.init()
    params.type = .card
    params.additionalAPIParameters = [
      "card": [
        "visa_checkout": [
          "callid": callId
        ]
      ]
    ]
    return params
  }

  /// Creates params for a card source created from Masterpass.
  /// - seealso: https://stripe.com/docs/masterpass
  /// @note Creating an STPSource with these params will give you a
  /// source with type == STPSourceTypeCard
  /// - Parameters:
  ///   - cartId: The cartId from a `MCCCheckoutResponse` object.
  ///   - transactionId: The transactionid from a `MCCCheckoutResponse` object.
  /// - Returns: An STPSourceParams object populated with the provided values.
  @objc
  public class func masterpassParams(
    withCartId cartId: String,
    transactionId: String
  ) -> STPSourceParams {
    let params = self.init()
    params.type = .card
    params.additionalAPIParameters = [
      "card": [
        "masterpass": [
          "cart_id": cartId,
          "transaction_id": transactionId,
        ]
      ]
    ]
    return params
  }

  /// Create params for an EPS source
  /// - seealso: https://stripe.com/docs/sources/eps
  /// - Parameters:
  ///   - amount:                  The amount to charge the customer.
  ///   - name:                    The full name of the account holder.
  ///   - returnURL:               The URL the customer should be redirected to
  /// after the authorization process.
  ///   - statementDescriptor:     A custom statement descriptor for the
  /// payment (optional).
  /// - Returns: An STPSourceParams object populated with the provided values.
  @objc
  public class func epsParams(
    withAmount amount: Int,
    name: String,
    returnURL: String,
    statementDescriptor: String?
  ) -> STPSourceParams {
    let params = self.init()
    params.type = .EPS
    params.amount = NSNumber(value: amount)
    params.currency = "eur"  // EPS must always use eur
    params.owner = [
      "name": name
    ]
    params.redirect = [
      "return_url": returnURL
    ]

    if (statementDescriptor?.count ?? 0) > 0 {
      params.additionalAPIParameters = [
        "statement_descriptor": statementDescriptor ?? ""
      ]
    }

    return params
  }

  /// Create params for a Multibanco source
  /// - seealso: https://stripe.com/docs/sources/multibanco
  /// - Parameters:
  ///   - amount:      The amount to charge the customer.
  ///   - returnURL:   The URL the customer should be redirected to after the
  /// authorization process.
  ///   - email:       The full email address of the customer.
  /// - Returns: An STPSourceParams object populated with the provided values.
  @objc
  public class func multibancoParams(
    withAmount amount: Int,
    returnURL: String,
    email: String
  ) -> STPSourceParams {
    let params = self.init()
    params.type = .multibanco
    params.currency = "eur"  // Multibanco must always use eur
    params.amount = NSNumber(value: amount)
    params.redirect = [
      "return_url": returnURL
    ]
    params.owner = [
      "email": email
    ]
    return params
  }

  /// Create params for a WeChat Pay native app redirect source
  /// @note This feature is in private beta. For participating users, see
  /// https://stripe.com/docs/sources/wechat-pay/ios
  /// - Parameters:
  ///   - amount:               The amount to charge the customer.
  ///   - currency:             The currency of the payment
  ///   - appId:                Your WeChat-provided application id. WeChat Pay uses
  /// this as the redirect URL scheme
  ///   - statementDescriptor:  A custom statement descriptor for the payment (optional).
  /// - Returns: An STPSourceParams object populated with the provided values.
  @objc(wechatPayParamsWithAmount:currency:appId:statementDescriptor:)
  public class func wechatPay(
    withAmount amount: Int,
    currency: String,
    appId: String,
    statementDescriptor: String?
  ) -> STPSourceParams {
    let params = self.init()

    params.type = .weChatPay
    params.amount = NSNumber(value: amount)
    params.currency = currency

    var wechat: [AnyHashable: Any] = [:]
    wechat["appid"] = appId
    if (statementDescriptor?.count ?? 0) > 0 {
      wechat["statement_descriptor"] = statementDescriptor ?? ""
    }
    params.additionalAPIParameters = [
      "wechat": wechat
    ]
    return params
  }

  @objc func flowString() -> String? {
    return STPSource.string(from: flow)
  }

  @objc func usageString() -> String? {
    return STPSource.string(from: usage)
  }

  // MARK: - Description
  /// :nodoc:
  @objc public override var description: String {
    let props = [
      // Object
      String(format: "%@: %p", NSStringFromClass(STPSourceParams.self), self),
      // Basic source details
      "type = \((STPSource.string(from: type)) ?? "unknown")",
      "rawTypeString = \(rawTypeString ?? "")",
      // Additional source details (alphabetical)
      "amount = \(amount ?? 0)",
      "currency = \(currency ?? "")",
      "flow = \((STPSource.string(from: flow)) ?? "unknown")",
      "metadata = \(((metadata) != nil ? "<redacted>" : nil) ?? "")",
      "owner = \(((owner) != nil ? "<redacted>" : nil) ?? "")",
      "redirect = \(redirect ?? [:])",
      "token = \(token ?? "")",
      "usage = \((STPSource.string(from: usage)) ?? "unknown")",
    ]

    return "<\(props.joined(separator: "; "))>"
  }

  // MARK: - Redirect Dictionary

  /// Private setter allows for setting the name of the app in the returnURL so
  /// that it can be displayed on hooks.stripe.com if the automatic redirect back
  /// to the app fails.
  /// We intercept the reading of redirect dictionary from STPFormEncoder and replace
  /// the value of return_url if necessary
  @objc
  public func redirectDictionaryWithMerchantNameIfNecessary() -> [AnyHashable: Any] {
    if (redirectMerchantName != nil) && redirect?["return_url"] != nil {

      let url = URL(string: redirect?["return_url"] as? String ?? "")
      if let url = url {
        let urlComponents = NSURLComponents(
          url: url,
          resolvingAgainstBaseURL: false)

        if let urlComponents = urlComponents {

          for item in urlComponents.queryItems ?? [] {
            if item.name == "redirect_merchant_name" {
              // Just return, don't replace their value
              return redirect ?? [:]
            }
          }

          // If we get here, there was no existing redirect name

          var queryItems: [URLQueryItem] = urlComponents.queryItems ?? [URLQueryItem]()

          queryItems.append(
            URLQueryItem(
              name: "redirect_merchant_name",
              value: redirectMerchantName))
          urlComponents.queryItems = queryItems as [URLQueryItem]?

          var redirectCopy = redirect
          redirectCopy?["return_url"] = urlComponents.url?.absoluteString

          return redirectCopy ?? [:]
        }
      }
    }

    return redirect ?? [:]

  }

  // MARK: - STPFormEncodable
  public class func rootObjectName() -> String? {
    return nil
  }

  public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
    return [
      NSStringFromSelector(#selector(getter:rawTypeString)): "type",
      NSStringFromSelector(#selector(getter:amount)): "amount",
      NSStringFromSelector(#selector(getter:currency)): "currency",
      NSStringFromSelector(#selector(flowString)): "flow",
      NSStringFromSelector(#selector(getter:metadata)): "metadata",
      NSStringFromSelector(#selector(getter:owner)): "owner",
      NSStringFromSelector(#selector(redirectDictionaryWithMerchantNameIfNecessary)): "redirect",
      NSStringFromSelector(#selector(getter:token)): "token",
      NSStringFromSelector(#selector(usageString)): "usage",
    ]
  }

  // MARK: - NSCopying
  /// :nodoc:
  public func copy(with zone: NSZone? = nil) -> Any {
    let copy = Swift.type(of: self).init()
    copy.type = type
    copy.amount = amount
    copy.currency = currency
    copy.flow = flow
    copy.metadata = metadata
    copy.owner = owner
    copy.redirect = redirect
    copy.token = token
    copy.usage = usage
    return copy
  }
}
