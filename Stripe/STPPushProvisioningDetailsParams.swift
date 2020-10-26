//
//  STPPushProvisioningDetailsParams.swift
//  Stripe
//
//  Created by Jack Flintermann on 9/26/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

import Foundation

/// A helper class for turning the raw certificate array, nonce, and nonce signature emitted by PKAddPaymentPassViewController into a format that is understandable by the Stripe API.
/// If you are using STPPushProvisioningContext to implement your integration, you do not need to use this class.
public class STPPushProvisioningDetailsParams: NSObject {
  /// The Stripe ID of the Issuing card object to retrieve details for.
  @objc public private(set) var cardId: String?
  /// An array of certificates that should be used to encrypt the card details.
  @objc public private(set) var certificates: [Data]?
  /// A nonce that should be used during the encryption of the card details.
  @objc public private(set) var nonce: Data?
  /// A nonce signature that should be used during the encryption of the card details.
  @objc public private(set) var nonceSignature: Data?
  /// Implemented for convenience - the Stripe API expects the certificate chain as an array of base64-encoded strings.

  @objc public var certificatesBase64: [String] {
    var base64Certificates: [AnyHashable] = []
    for certificate in certificates ?? [] {
      base64Certificates.append(certificate.base64EncodedString(options: []))
    }
    return base64Certificates as? [String] ?? []
  }
  /// Implemented for convenience - the Stripe API expects the nonce as a hex-encoded string.

  @objc public var nonceHex: String? {
    if let nonce = nonce {
      return STPPushProvisioningDetailsParams.hexadecimalString(for: nonce)
    }
    return nil
  }
  /// Implemented for convenience - the Stripe API expects the nonce signature as a hex-encoded string.

  @objc public var nonceSignatureHex: String? {
    if let nonceSignature = nonceSignature {
      return STPPushProvisioningDetailsParams.hexadecimalString(for: nonceSignature)
    }
    return nil
  }

  /// Instantiates a new params object with the provided attributes.
  @objc public required init(
    cardId: String,
    certificates: [Data],
    nonce: Data,
    nonceSignature: Data
  ) {
    self.cardId = cardId
    self.certificates = certificates
    self.nonce = nonce
    self.nonceSignature = nonceSignature
  }

  @objc(paramsWithCardId:certificates:nonce:nonceSignature:) class func paramsWithCardId(
    cardId: String,
    certificates: [Data],
    nonce: Data,
    nonceSignature: Data
  ) -> Self {
    return self.init(
      cardId: cardId, certificates: certificates, nonce: nonce, nonceSignature: nonceSignature)
  }

  // Adapted from https://stackoverflow.com/questions/39075043/how-to-convert-data-to-hex-string-in-swift
  class func hexadecimalString(for data: Data) -> String {
    return data.map { String(format: "%02hhx", $0) }.joined()
  }
}
