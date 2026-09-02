//
//  HostedAuthUrlBuilder.swift
//  StripeCore
//
//  Created by Mat Schmid on 2025-03-27.
//

import Foundation

@_spi(STP) public enum HostedAuthUrlBuilder {
    /// Builds the Hosted Auth URL by appending various query parameters.
    @_spi(STP) public static func build(
        baseHostedAuthUrl: URL,
        isInstantDebits: Bool,
        hasExistingAccountholderToken: Bool,
        elementsSessionContext: ElementsSessionContext?,
        prefillDetailsOverride: PrefillData? = nil,
        additionalQueryParameters: String? = nil
    ) -> URL {
        var parameters: [String] = []

        if let additionalQueryParameters, additionalQueryParameters.isEmpty == false {
            parameters.append(additionalQueryParameters)
        }

        // Only add additional instant debits parameters if there isn't an existing accountholder.
        // This is for the linked account flow, which uses instant debits, but shouldn't create the payment method.
        if isInstantDebits, !hasExistingAccountholderToken {
            parameters.append("return_payment_method=true")
            parameters.append("expand_payment_method=true")

            if let incentiveEligibilitySession = elementsSessionContext?.incentiveEligibilitySession {
                parameters.append("instantDebitsIncentive=true")
                parameters.append("incentiveEligibilitySession=\(incentiveEligibilitySession.id)")

                if let linkConsumerIncentive = elementsSessionContext?.linkConsumerIncentive {
                    parameters.append(contentsOf: hostedParameters(for: linkConsumerIncentive))
                }
            }

            if let linkMode = elementsSessionContext?.linkMode {
                parameters.append("link_mode=\(linkMode.rawValue)")
            }

            if let billingDetails = elementsSessionContext?.billingDetails {
                if let name = billingDetails.name, !name.isEmpty {
                    parameters.append("billingDetails[name]=\(name)")
                }
                if let email = billingDetails.email, !email.isEmpty {
                    parameters.append("billingDetails[email]=\(email)")
                }
                if let phone = billingDetails.phone, !phone.isEmpty {
                    parameters.append("billingDetails[phone]=\(phone)")
                }
                if let address = billingDetails.address {
                    if let city = address.city, !city.isEmpty {
                        parameters.append("billingDetails[address][city]=\(city)")
                    }
                    if let country = address.country, !country.isEmpty {
                        parameters.append("billingDetails[address][country]=\(country)")
                    }
                    if let line1 = address.line1, !line1.isEmpty {
                        parameters.append("billingDetails[address][line1]=\(line1)")
                    }
                    if let line2 = address.line2, !line2.isEmpty {
                        parameters.append("billingDetails[address][line2]=\(line2)")
                    }
                    if let postalCode = address.postalCode, !postalCode.isEmpty {
                        parameters.append("billingDetails[address][postal_code]=\(postalCode)")
                    }
                    if let state = address.state, !state.isEmpty {
                        parameters.append("billingDetails[address][state]=\(state)")
                    }
                }
            }
        }

        if let prefillDetails = prefillDetailsOverride ?? elementsSessionContext?.prefillDetails {
            if let email = prefillDetails.email, !email.isEmpty {
                parameters.append("email=\(email)")
            }
            if let phoneNumber = prefillDetails.phone, !phoneNumber.isEmpty {
                parameters.append("linkMobilePhone=\(phoneNumber)")
            }
            if let countryCode = prefillDetails.countryCode, !countryCode.isEmpty {
                parameters.append("linkMobilePhoneCountry=\(countryCode)")
            }
        }

        parameters.append("launched_by=ios_sdk")

        if let allowRedisplay = elementsSessionContext?.allowRedisplay {
            parameters.append("allow_redisplay=\(allowRedisplay)")
        }

        // Join all values with an &, and URL encode.
        // We encode these parameters since they will be appended to the auth flow URL.
        let joinedParameters = parameters
            .joined(separator: "&")
            .addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        guard let joinedParameters else {
            return baseHostedAuthUrl
        }

        let urlString = baseHostedAuthUrl.absoluteString
        let joiningCharacter = urlString.hasSuffix("&") || joinedParameters.hasPrefix("&")
            ? ""
            : "&"
        let updatedUrlString = urlString + joiningCharacter + joinedParameters
        return URL(string: updatedUrlString) ?? baseHostedAuthUrl
    }

    private static func hostedParameters(for incentive: LinkConsumerIncentive) -> [String] {
        guard
            let incentiveCampaign = incentive.incentiveCampaign,
            let currency = incentive.incentiveParams.currency
        else {
            // The hosted flow requires these fields. Avoid sending a partial object that would make
            // the entire launch payload fail validation.
            return []
        }

        var parameters = [
            "linkConsumerIncentive[incentive_campaign]=\(incentiveCampaign)",
            "linkConsumerIncentive[incentive_params][payment_method]=\(incentive.incentiveParams.paymentMethod)",
            "linkConsumerIncentive[incentive_params][currency]=\(currency)",
        ]

        if let amountFlat = incentive.incentiveParams.amountFlat {
            parameters.append("linkConsumerIncentive[incentive_params][amount_flat]=\(amountFlat)")
        }
        if let amountPercent = incentive.incentiveParams.amountPercent {
            parameters.append("linkConsumerIncentive[incentive_params][amount_percent]=\(amountPercent)")
        }
        if let minimumPaymentAmount = incentive.incentiveParams.minimumPaymentAmount {
            parameters.append("linkConsumerIncentive[incentive_params][minimum_payment_amount]=\(minimumPaymentAmount)")
        }
        if let incentiveParamsSignature = incentive.incentiveParamsSignature {
            parameters.append("linkConsumerIncentive[incentive_params_signature]=\(incentiveParamsSignature)")
        }
        if let validForSession = incentive.validForSession {
            parameters.append("linkConsumerIncentive[valid_for_session]=\(validForSession)")
        }

        return parameters
    }
}
