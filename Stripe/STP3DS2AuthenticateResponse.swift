//
//  STP3DS2AuthenticateResponse.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 5/22/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

import Stripe3DS2

enum STP3DS2AuthenticateResponseState: Int {
  /// Unknown Authenticate Response state
  case unknown = 0
  /// State indicating that a challenge flow needs to be applied
  case challengeRequired
  /// State indicating that the authentication succeeded
  case succeeded
}

class STP3DS2AuthenticateResponse: NSObject, STPAPIResponseDecodable {
  private(set) var allResponseFields: [AnyHashable: Any] = [:]
  /// The Authentication Response received from the Access Control Server
  private(set) var authenticationResponse: STDSAuthenticationResponse?
  /// When the 3DS2 Authenticate Response was created.
  private(set) var created: Date?
  /// Whether or not this Authenticate Response was created in livemode.
  private(set) var livemode = false
  /// The identifier for the Source associated with this Authenticate Response
  private(set) var sourceID: String?
  /// A fallback URL to redirect to instead of running native 3DS2
  private(set) var fallbackURL: URL?
  /// The state of the authentication
  private(set) var state: STP3DS2AuthenticateResponseState = .unknown

  override required init() {
    super.init()
  }

  class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
    guard let response = response else {
      return nil
    }
    let dict = (response as NSDictionary).stp_dictionaryByRemovingNulls() as NSDictionary

    let fallbackURL = dict.stp_url(forKey: "fallback_redirect_url")

    let authenticationResponseJSON = dict.stp_dictionary(forKey: "ares")

    var authenticationResponse: STDSAuthenticationResponse?
    if let authenticationResponseJSON = authenticationResponseJSON {
      authenticationResponse = STDSAuthenticationResponseFromJSON(authenticationResponseJSON)
    }
    if authenticationResponse == nil && fallbackURL == nil {
      // we need at least one of ares or fallback_redirect_url
      return nil
    }

    let stateString = dict.stp_string(forKey: "state")
    var state: STP3DS2AuthenticateResponseState = .unknown
    if stateString == "succeeded" {
      state = .succeeded
    } else if stateString == "challenge_required" {
      state = .challengeRequired
    }

    let authResponse = self.init()
    authResponse.authenticationResponse = authenticationResponse
    authResponse.state = state
    authResponse.created = dict.stp_date(forKey: "created")
    authResponse.livemode = dict.stp_bool(forKey: "livemode", or: true)
    authResponse.sourceID = dict.stp_string(forKey: "source")
    authResponse.fallbackURL = fallbackURL
    authResponse.allResponseFields = response

    return authResponse
  }
}
