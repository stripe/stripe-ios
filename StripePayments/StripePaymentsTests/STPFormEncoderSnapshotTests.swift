//
//  STPFormEncoderSnapshotTests.swift
//  StripePaymentsTests
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit
@_spi(InternalOnlyAPI) @testable import StripeCore
@_spi(InternalOnlyAPI) @_spi(KlarnaSDKPrivatePreview) @testable import StripePayments
import XCTest

/// Compares the output of `STPFormEncoder` for a fully populated instance of every
/// `STPFormEncodable` type against a reference snapshot (`STPFormEncoderSnapshot.json`).
///
/// The reference snapshot was recorded with the key-value-coding based encoder that shipped before
/// the encoder read properties through key paths. Any difference in the encoded parameters, including
/// a change in the type of a leaf value (for example a boolean becoming an integer), fails the test.
class STPFormEncoderSnapshotTests: XCTestCase {

    /// Set to a file path to write a new reference snapshot instead of comparing against the existing one.
    static let recordPath: String? = nil

    override func setUp() {
        super.setUp()
        // `STPClientAttributionMetadata` reads the analytics session ID; make sure there is one to encode.
        AnalyticsHelper.shared.generateSessionID()
    }

    func testEncodedParametersMatchReferenceSnapshot() throws {
        let fixtures = Self.makeFixtures()
        let names = fixtures.map(\.name)
        XCTAssertEqual(Set(names).count, names.count, "Fixture names must be unique")

        var actual: [String: Any] = [:]
        for fixture in fixtures {
            actual[fixture.name] = Self.canonicalize(STPFormEncoder.dictionary(forObject: fixture.object))
        }

        if let recordPath = Self.recordPath {
            let data = try JSONSerialization.data(withJSONObject: actual, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: URL(fileURLWithPath: recordPath))
            XCTFail("Recorded reference snapshot to \(recordPath). Set `recordPath` back to nil.")
            return
        }

        let url = try XCTUnwrap(
            Bundle(for: Self.self).url(forResource: "STPFormEncoderSnapshot", withExtension: "json"),
            "Missing STPFormEncoderSnapshot.json in the test bundle"
        )
        let expected = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
        )

        XCTAssertEqual(Set(expected.keys), Set(actual.keys), "The set of fixtures differs from the reference snapshot")
        for name in names.sorted() {
            guard let expectedValue = expected[name], let actualValue = actual[name] else {
                continue
            }
            XCTAssertEqual(
                try Self.jsonString(actualValue),
                try Self.jsonString(expectedValue),
                "Encoded parameters for \(name) differ from the reference snapshot"
            )
        }
    }

    /// Guards against fixtures silently leaving a mapped property unset, which would weaken the comparison above.
    func testFixturesPopulateEveryMappedProperty() {
        for fixture in Self.makeFixtures() where fixture.checksCompleteness {
            let object = fixture.object
            let encoded = STPFormEncoder.dictionary(forObject: object)
            let keyPairs: [String: Any]
            if let rootObjectName = type(of: object).rootObjectName() {
                keyPairs = encoded[rootObjectName] as? [String: Any] ?? [:]
            } else {
                keyPairs = encoded
            }
            let mappedFieldNames = Set(type(of: object).propertyNamesToFormFieldNamesMapping().values)
            let additionalFieldNames = Set(object.additionalAPIParameters.keys.compactMap { $0 as? String })
            XCTAssertEqual(
                Set(keyPairs.keys),
                mappedFieldNames.union(additionalFieldNames),
                "\(fixture.name) does not populate every mapped property"
            )
        }
    }

    // MARK: - Canonicalization

    /// Converts encoded parameters into a JSON-compatible tree that records the type of every leaf value.
    static func canonicalize(_ value: Any) -> Any {
        switch value {
        case let dictionary as NSDictionary:
            var result: [String: Any] = [:]
            for (key, value) in dictionary {
                // Keys are expected to be strings, so only tag the ones that aren't.
                let key = (key as? String).map(normalized) ?? canonicalLeaf(key)
                result[key] = canonicalize(value)
            }
            return result
        case let array as NSArray:
            return array.map { canonicalize($0) }
        case let set as NSSet:
            return set.map { "\(canonicalize($0))" }.sorted()
        default:
            return canonicalLeaf(value)
        }
    }

    static func canonicalLeaf(_ value: Any) -> String {
        switch value {
        case let number as NSNumber:
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return "bool:\(number.boolValue)"
            }
            return "number(\(String(cString: number.objCType))):\(number.stringValue)"
        case let string as NSString:
            return "string:\(normalized(string as String))"
        case is NSNull:
            return "null"
        case let date as NSDate:
            return "date:\(date.timeIntervalSince1970)"
        case let data as NSData:
            return "data:\(data.base64EncodedString())"
        default:
            return "other(\(type(of: value))):\(value)"
        }
    }

    /// Replaces values that change between runs or SDK versions with stable placeholders.
    static func normalized(_ string: String) -> String {
        var string = string
        if let sessionID = AnalyticsHelper.shared.sessionID {
            string = string.replacingOccurrences(of: sessionID, with: "<session_id>")
        }
        return string.replacingOccurrences(of: StripeAPIConfiguration.STPSDKVersion, with: "<sdk_version>")
    }

    static func jsonString(_ value: Any) throws -> String {
        let data = try JSONSerialization.data(
            withJSONObject: ["value": value],
            options: [.prettyPrinted, .sortedKeys]
        )
        return String(bytes: data, encoding: .utf8) ?? ""
    }

    // MARK: - Fixtures

    struct Fixture {
        let name: String
        let object: NSObject & STPFormEncodable
        /// Whether every mapped property is expected to appear in the encoded output.
        var checksCompleteness = true
    }

    static func extra(_ name: String) -> [AnyHashable: Any] {
        return ["\(name)_extra": ["string": "extra", "int": 7, "bool": true, "list": [1, "two", false]]]
    }

    static func connectAddress(_ prefix: String = "") -> STPConnectAccountAddress {
        let address = STPConnectAccountAddress()
        address.line1 = "\(prefix)123 Main St"
        address.line2 = "\(prefix)Apt 4"
        address.town = "\(prefix)Town"
        address.city = "\(prefix)San Francisco"
        address.state = "\(prefix)CA"
        address.postalCode = "\(prefix)94107"
        address.country = "US"
        address.additionalAPIParameters = extra("connect_address")
        return address
    }

    static func paymentMethodAddress() -> STPPaymentMethodAddress {
        let address = STPPaymentMethodAddress()
        address.line1 = "510 Townsend St"
        address.line2 = "Floor 2"
        address.city = "San Francisco"
        address.state = "CA"
        address.postalCode = "94103"
        address.country = "US"
        address.additionalAPIParameters = extra("pm_address")
        return address
    }

    static func billingDetails() -> STPPaymentMethodBillingDetails {
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.address = paymentMethodAddress()
        billingDetails.email = "jenny@example.com"
        billingDetails.name = "Jenny Rosen"
        billingDetails.phone = "+15555555555"
        billingDetails.additionalAPIParameters = extra("billing_details")
        return billingDetails
    }

    static func address() -> STPAddress {
        let address = STPAddress()
        address.name = "Jenny Rosen"
        address.line1 = "1 Market St"
        address.line2 = "Suite 100"
        address.city = "San Francisco"
        address.state = "CA"
        address.postalCode = "94105"
        address.country = "US"
        address.phone = "+15555555555"
        address.email = "jenny@example.com"
        address.additionalAPIParameters = extra("address")
        return address
    }

    static func cardNetworks() -> STPPaymentMethodCardNetworksParams {
        let networks = STPPaymentMethodCardNetworksParams(preferred: "cartes_bancaires")
        networks.additionalAPIParameters = extra("card_networks")
        return networks
    }

    static func paymentMethodCard() -> STPPaymentMethodCardParams {
        let card = STPPaymentMethodCardParams()
        card.number = "4242424242424242"
        card.expMonth = 12
        card.expYear = 2034
        card.cvc = "123"
        card.token = "tok_visa"
        card.networks = cardNetworks()
        card.additionalAPIParameters = extra("pm_card")
        return card
    }

    static func clientAttributionMetadata() -> STPClientAttributionMetadata {
        let metadata = STPClientAttributionMetadata(
            elementsSessionConfigId: "elements_session_config_123",
            checkoutSessionId: "cs_test_123",
            checkoutConfigId: "checkout_config_123",
            merchantIntegrationSource: "elements",
            merchantIntegrationSubtype: "mobile",
            merchantIntegrationAdditionalElements: [.paymentElement, .expressCheckoutElement],
            paymentIntentCreationFlow: .deferred,
            paymentMethodSelectionFlow: .merchantSpecified
        )
        metadata.additionalAPIParameters = extra("client_attribution_metadata")
        return metadata
    }

    static func radarOptions() -> STPRadarOptions {
        let options = STPRadarOptions(hcaptchaToken: "hcaptcha_token_123")
        options.iosVerificationObject = ["key_id": "key_123", "assertion": "assertion_123"]
        options.additionalAPIParameters = extra("radar_options")
        return options
    }

    static func mandateOnline(inferFromClient: Bool = false) -> STPMandateOnlineParams {
        let online = STPMandateOnlineParams(ipAddress: "127.0.0.1", userAgent: "Mozilla/5.0")
        online.inferFromClient = NSNumber(value: inferFromClient)
        online.additionalAPIParameters = extra("mandate_online")
        return online
    }

    static func mandateCustomerAcceptance() -> STPMandateCustomerAcceptanceParams {
        let acceptance = STPMandateCustomerAcceptanceParams()
        acceptance.type = .online
        acceptance.onlineParams = mandateOnline()
        acceptance.additionalAPIParameters = extra("customer_acceptance")
        return acceptance
    }

    static func mandateData() -> STPMandateDataParams {
        let mandateData = STPMandateDataParams(customerAcceptance: mandateCustomerAcceptance())
        mandateData.additionalAPIParameters = extra("mandate_data")
        return mandateData
    }

    static func shippingAddress() -> STPPaymentIntentShippingDetailsAddressParams {
        let address = STPPaymentIntentShippingDetailsAddressParams(line1: "1 Shipping Way")
        address.line2 = "Unit 9"
        address.city = "Oakland"
        address.state = "CA"
        address.postalCode = "94607"
        address.country = "US"
        address.additionalAPIParameters = extra("shipping_address")
        return address
    }

    static func shipping() -> STPPaymentIntentShippingDetailsParams {
        let shipping = STPPaymentIntentShippingDetailsParams(address: shippingAddress(), name: "Jenny Rosen")
        shipping.carrier = "UPS"
        shipping.phone = "+15555555555"
        shipping.trackingNumber = "1Z999"
        shipping.additionalAPIParameters = extra("shipping")
        return shipping
    }

    static func alipayOptions() -> STPConfirmAlipayOptions {
        let options = STPConfirmAlipayOptions()
        options.currency = "usd"
        options.setupFutureUsage = .offSession
        options.additionalAPIParameters = extra("alipay_options")
        return options
    }

    static func blikOptions() -> STPConfirmBLIKOptions {
        let options = STPConfirmBLIKOptions(code: "123456")
        options.additionalAPIParameters = extra("blik_options")
        return options
    }

    static func cardOptions() -> STPConfirmCardOptions {
        let options = STPConfirmCardOptions()
        options.cvc = "123"
        options.network = "visa"
        options.additionalAPIParameters = extra("card_options")
        return options
    }

    static func klarnaOptions() -> STPConfirmKlarnaOptions {
        let options = STPConfirmKlarnaOptions(
            interoperabilityToken: "interop_token",
            partnerConfirmationToken: "partner_token"
        )
        options.additionalAPIParameters = extra("klarna_options")
        return options
    }

    static func konbiniOptions() -> STPConfirmKonbiniOptions {
        let options = STPConfirmKonbiniOptions()
        options.confirmationNumber = "12345678901"
        options.additionalAPIParameters = extra("konbini_options")
        return options
    }

    static func linkOptions() -> STPConfirmLinkOptions {
        let options = STPConfirmLinkOptions()
        options.setupFutureUsage = .onSession
        options.additionalAPIParameters = extra("link_options")
        return options
    }

    static func usBankAccountOptions() -> STPConfirmUSBankAccountOptions {
        let options = STPConfirmUSBankAccountOptions(setupFutureUsage: .offSession)
        options.additionalAPIParameters = extra("us_bank_account_options")
        return options
    }

    static func weChatPayOptions() -> STPConfirmWeChatPayOptions {
        let options = STPConfirmWeChatPayOptions(appId: "wx_app_id")
        options.additionalAPIParameters = extra("wechat_pay_options")
        return options
    }

    static func paymentMethodOptions() -> STPConfirmPaymentMethodOptions {
        let options = STPConfirmPaymentMethodOptions()
        options.alipayOptions = alipayOptions()
        options.cardOptions = cardOptions()
        options.blikOptions = blikOptions()
        options.weChatPayOptions = weChatPayOptions()
        options.usBankAccountOptions = usBankAccountOptions()
        options.konbiniOptions = konbiniOptions()
        options.klarnaOptions = klarnaOptions()
        options.linkOptions = linkOptions()
        options.additionalAPIParameters = extra("payment_method_options")
        return options
    }

    /// Fully populates the type-specific params for `type`, so every payment method type is covered.
    static func populate(_ params: STPPaymentMethodParams, for type: STPPaymentMethodType) {
        switch type {
        case .card:
            params.card = paymentMethodCard()
        case .iDEAL:
            params.iDEAL?.bankName = "ing"
        case .FPX:
            params.fpx?.rawBankString = "maybank2u"
        case .SEPADebit:
            params.sepaDebit?.iban = "DE89370400440532013000"
        case .bacsDebit:
            params.bacsDebit?.sortCode = "108800"
            params.bacsDebit?.accountNumber = "00012345"
        case .AUBECSDebit:
            params.auBECSDebit?.bsbNumber = "000000"
            params.auBECSDebit?.accountNumber = "000123456"
        case .boleto:
            params.boleto?.taxID = "00.000.000/0001-91"
        case .link:
            params.link?.paymentDetailsID = "csmrpd_123"
            params.link?.credentials = ["consumer_session_client_secret": "secret_123", "nested": ["a": 1]]
        case .naverPay:
            params.naverPay?.fundingString = "card"
        case .netBanking:
            params.netBanking?.bank = "hdfc"
        case .payByBank:
            params.payByBank?.bank = "barclays"
        case .USBankAccount:
            let usBankAccount = STPPaymentMethodUSBankAccountParams()
            usBankAccount.accountHolderType = .company
            usBankAccount.accountType = .savings
            usBankAccount.accountNumber = "000123456789"
            usBankAccount.routingNumber = "110000000"
            usBankAccount.linkAccountSessionID = "fcsess_123"
            params.usBankAccount = usBankAccount
        default:
            break
        }
        // Every type-specific params object can carry additional parameters.
        let typeSpecificParams: [NSObject & STPFormEncodable] = [
            params.card, params.alipay, params.iDEAL, params.fpx, params.sepaDebit, params.bacsDebit,
            params.auBECSDebit, params.payPal, params.przelewy24, params.eps, params.bancontact,
            params.netBanking, params.oxxo, params.grabPay, params.afterpayClearpay, params.blik,
            params.weChatPay, params.boleto, params.link, params.klarna, params.affirm, params.usBankAccount,
            params.cashApp, params.revolutPay, params.swish, params.mobilePay, params.vipps, params.amazonPay,
            params.alma, params.sunbit, params.billie, params.satispay, params.crypto, params.multibanco,
            params.payPay, params.twint, params.wero, params.payByBank, params.kakaoPay, params.krCard,
            params.naverPay, params.payco, params.sequra, params.scalapay, params.goPay, params.mondu,
            params.ngUSSD, params.qris, params.ngWallet, params.shopeePay, params.trueMoney, params.touchNGo,
            params.gcash, params.momo, params.ngBankTransfer, params.ngCard,
        ].compactMap { $0 }
        for typeSpecific in typeSpecificParams {
            typeSpecific.additionalAPIParameters = extra("type_specific")
        }
    }

    static func paymentMethodParams(type: STPPaymentMethodType) -> STPPaymentMethodParams {
        let params = STPPaymentMethodParams(type: type)
        populate(params, for: type)
        params.billingDetails = billingDetails()
        params.allowRedisplay = .always
        params.metadata = ["order_id": "1234", "note": "fixture"]
        params.radarOptions = radarOptions()
        params.clientAttributionMetadata = clientAttributionMetadata()
        params.additionalAPIParameters = extra("payment_method_params")
        return params
    }

    static func cardParams() -> STPCardParams {
        let card = STPCardParams()
        card.number = "4242424242424242"
        card.expMonth = 12
        card.expYear = 2034
        card.cvc = "123"
        card.name = "Jenny Rosen"
        card.address = address()
        card.currency = "usd"
        card.additionalAPIParameters = extra("card")
        return card
    }

    static func bankAccountParams() -> STPBankAccountParams {
        let bankAccount = STPBankAccountParams()
        bankAccount.accountNumber = "000123456789"
        bankAccount.routingNumber = "110000000"
        bankAccount.country = "US"
        bankAccount.currency = "usd"
        bankAccount.accountHolderName = "Jenny Rosen"
        bankAccount.accountHolderType = .company
        bankAccount.additionalAPIParameters = extra("bank_account")
        return bankAccount
    }

    static func sourceParams() -> STPSourceParams {
        let source = STPSourceParams()
        source.type = .card
        source.amount = NSNumber(value: 1099)
        source.currency = "usd"
        source.metadata = ["order_id": "1234", "count": 3]
        source.owner = ["name": "Jenny Rosen", "address": ["line1": "1 Market St"]]
        source.token = "tok_visa"
        source.usage = .reusable
        source.additionalAPIParameters = extra("source")
        return source
    }

    static func paymentIntentConfirmParams(paymentMethodType: STPPaymentMethodType) -> STPPaymentIntentConfirmParams {
        let params = STPPaymentIntentConfirmParams(clientSecret: "pi_123_secret_456")
        params.paymentMethodParams = paymentMethodParams(type: paymentMethodType)
        params.paymentMethodId = "pm_123"
        params.setupFutureUsage = .offSession
        params.sourceParams = sourceParams()
        params.sourceId = "src_123"
        params.receiptEmail = "jenny@example.com"
        params.savePaymentMethod = NSNumber(value: true)
        params.setAsDefaultPM = NSNumber(value: false)
        params.returnURL = "payments-example://stripe-redirect"
        params.useStripeSDK = true
        params.mandateData = mandateData()
        params.paymentMethodOptions = paymentMethodOptions()
        params.shipping = shipping()
        params.radarOptions = radarOptions()
        params.clientAttributionMetadata = clientAttributionMetadata()
        params.confirmationToken = "ctoken_123"
        params.additionalAPIParameters = extra("payment_intent_confirm")
        return params
    }

    static func setupIntentConfirmParams(paymentMethodType: STPPaymentMethodType) -> STPSetupIntentConfirmParams {
        let params = STPSetupIntentConfirmParams(clientSecret: "seti_123_secret_456")
        params.paymentMethodParams = paymentMethodParams(type: paymentMethodType)
        params.paymentMethodID = "pm_123"
        params.paymentMethodOptions = paymentMethodOptions()
        params.setAsDefaultPM = NSNumber(value: true)
        params.returnURL = "payments-example://stripe-redirect"
        params.useStripeSDK = false
        params.mandateData = mandateData()
        params.radarOptions = radarOptions()
        params.clientAttributionMetadata = clientAttributionMetadata()
        params.confirmationToken = "ctoken_123"
        params.additionalAPIParameters = extra("setup_intent_confirm")
        return params
    }

    static func confirmationTokenClientContext() -> STPConfirmationTokenClientContext {
        let context = STPConfirmationTokenClientContext()
        context.mode = "payment"
        context.currency = "usd"
        context.setupFutureUsage = "off_session"
        context.captureMethod = "manual"
        context.paymentMethodTypes = ["card", "us_bank_account"]
        context.onBehalfOf = "acct_123"
        context.paymentMethodConfiguration = "pmc_123"
        context.customer = "cus_123"
        context.paymentMethodOptions = ["card": ["require_cvc_recollection": true], "count": 2]
        context.additionalAPIParameters = extra("client_context")
        return context
    }

    static func confirmationTokenParams() -> STPConfirmationTokenParams {
        let params = STPConfirmationTokenParams()
        params.paymentMethod = "pm_123"
        params.paymentMethodData = paymentMethodParams(type: .card)
        params.paymentMethodOptions = paymentMethodOptions()
        params.returnURL = "payments-example://stripe-redirect"
        params.setupFutureUsage = .onSession
        params.shipping = shipping()
        params.mandateData = mandateData()
        params.setAsDefaultPM = NSNumber(value: true)
        params.clientAttributionMetadata = clientAttributionMetadata()
        params.clientContext = confirmationTokenClientContext()
        params.additionalAPIParameters = extra("confirmation_token")
        return params
    }

    static func verificationDocument(_ prefix: String) -> STPConnectAccountVerificationDocument {
        let document = STPConnectAccountVerificationDocument()
        document.front = "file_\(prefix)_front"
        document.back = "file_\(prefix)_back"
        document.additionalAPIParameters = extra("verification_document")
        return document
    }

    static func individualVerification() -> STPConnectAccountIndividualVerification {
        let verification = STPConnectAccountIndividualVerification()
        verification.document = verificationDocument("document")
        verification.additionalDocument = verificationDocument("additional")
        verification.additionalAPIParameters = extra("verification")
        return verification
    }

    static func individualParams() -> STPConnectAccountIndividualParams {
        let individual = STPConnectAccountIndividualParams()
        individual.address = connectAddress()
        individual.kanaAddress = connectAddress("kana ")
        individual.kanjiAddress = connectAddress("kanji ")
        var dateOfBirth = DateComponents()
        dateOfBirth.day = 31
        dateOfBirth.month = 12
        dateOfBirth.year = 1990
        individual.dateOfBirth = dateOfBirth
        individual.email = "jenny@example.com"
        individual.firstName = "Jenny"
        individual.kanaFirstName = "kana Jenny"
        individual.kanjiFirstName = "kanji Jenny"
        individual.gender = "female"
        individual.idNumber = "000000000"
        individual.lastName = "Rosen"
        individual.kanaLastName = "kana Rosen"
        individual.kanjiLastName = "kanji Rosen"
        individual.maidenName = "Smith"
        individual.metadata = ["key": "value", "number": 42]
        individual.phone = "+15555555555"
        individual.ssnLast4 = "0000"
        individual.verification = individualVerification()
        individual.additionalAPIParameters = extra("individual")
        return individual
    }

    static func companyParams() -> STPConnectAccountCompanyParams {
        let company = STPConnectAccountCompanyParams()
        company.address = connectAddress()
        company.kanaAddress = connectAddress("kana ")
        company.kanjiAddress = connectAddress("kanji ")
        company.directorsProvided = true
        company.name = "Rocket Rides"
        company.kanaName = "kana Rocket Rides"
        company.kanjiName = "kanji Rocket Rides"
        company.ownersProvided = false
        company.phone = "+15555555555"
        company.taxID = "000000000"
        company.taxIDRegistrar = "registrar"
        company.vatID = "vat_123"
        company.additionalAPIParameters = extra("company")
        return company
    }

    static func dateOfBirth() -> STPDateOfBirth {
        let dateOfBirth = STPDateOfBirth()
        dateOfBirth.day = 1
        dateOfBirth.month = 2
        dateOfBirth.year = 1980
        dateOfBirth.additionalAPIParameters = extra("dob")
        return dateOfBirth
    }

    static func connectAccountParams(company: Bool) -> STPConnectAccountParams {
        let params: STPConnectAccountParams
        if company {
            params = STPConnectAccountParams(tosShownAndAccepted: true, company: companyParams())!
        } else {
            params = STPConnectAccountParams(tosShownAndAccepted: true, individual: individualParams())!
        }
        params.additionalAPIParameters = extra("connect_account")
        return params
    }

    static func paymentMethodUpdateParams() -> STPPaymentMethodUpdateParams {
        let params = STPPaymentMethodUpdateParams(card: paymentMethodCard(), billingDetails: billingDetails())
        params.additionalAPIParameters = extra("payment_method_update")
        return params
    }

    static func makeFixtures() -> [Fixture] {
        var fixtures: [Fixture] = [
            Fixture(name: "STPAddress", object: address()),
            Fixture(name: "STPBankAccountParams", object: bankAccountParams()),
            Fixture(name: "STPCardParams", object: cardParams()),
            Fixture(name: "STPClientAttributionMetadata", object: clientAttributionMetadata()),
            Fixture(name: "STPConfirmAlipayOptions", object: alipayOptions()),
            Fixture(name: "STPConfirmBLIKOptions", object: blikOptions()),
            Fixture(name: "STPConfirmCardOptions", object: cardOptions()),
            Fixture(name: "STPConfirmKlarnaOptions", object: klarnaOptions()),
            Fixture(name: "STPConfirmKonbiniOptions", object: konbiniOptions()),
            Fixture(name: "STPConfirmLinkOptions", object: linkOptions()),
            Fixture(name: "STPConfirmPaymentMethodOptions", object: paymentMethodOptions()),
            Fixture(name: "STPConfirmUSBankAccountOptions", object: usBankAccountOptions()),
            Fixture(name: "STPConfirmWeChatPayOptions", object: weChatPayOptions()),
            Fixture(name: "STPConfirmationTokenClientContext", object: confirmationTokenClientContext()),
            Fixture(name: "STPConfirmationTokenParams", object: confirmationTokenParams()),
            Fixture(name: "STPConnectAccountAddress", object: connectAddress()),
            Fixture(name: "STPConnectAccountCompanyParams", object: companyParams()),
            Fixture(name: "STPConnectAccountIndividualParams", object: individualParams()),
            Fixture(name: "STPConnectAccountIndividualVerification", object: individualVerification()),
            // Only one of `individual` and `company` is set at a time.
            Fixture(name: "STPConnectAccountParams.company", object: connectAccountParams(company: true), checksCompleteness: false),
            Fixture(name: "STPConnectAccountParams.individual", object: connectAccountParams(company: false), checksCompleteness: false),
            Fixture(name: "STPConnectAccountVerificationDocument", object: verificationDocument("document")),
            Fixture(name: "STPDateOfBirth", object: dateOfBirth()),
            Fixture(name: "STPMandateCustomerAcceptanceParams", object: mandateCustomerAcceptance()),
            Fixture(name: "STPMandateDataParams", object: mandateData()),
            Fixture(name: "STPMandateOnlineParams", object: mandateOnline()),
            // Inferring from the client omits the IP address and user agent.
            Fixture(name: "STPMandateOnlineParams.inferFromClient", object: mandateOnline(inferFromClient: true), checksCompleteness: false),
            Fixture(name: "STPPaymentIntentShippingDetailsAddressParams", object: shippingAddress()),
            Fixture(name: "STPPaymentIntentShippingDetailsParams", object: shipping()),
            Fixture(name: "STPPaymentMethodAddress", object: paymentMethodAddress()),
            Fixture(name: "STPPaymentMethodBillingDetails", object: billingDetails()),
            Fixture(name: "STPPaymentMethodCardNetworksParams", object: cardNetworks()),
            Fixture(name: "STPPaymentMethodCardParams", object: paymentMethodCard()),
            Fixture(name: "STPPaymentMethodUpdateParams", object: paymentMethodUpdateParams()),
            Fixture(name: "STPRadarOptions", object: radarOptions()),
            Fixture(name: "STPSourceParams", object: sourceParams()),
            Fixture(name: "STPSourceParams.fromCard", object: STPSourceParams.cardParams(withCard: cardParams()), checksCompleteness: false),
        ]

        // Every payment method type.
        for type in STPPaymentMethodType.allCases {
            let typeName = STPPaymentMethod.string(from: type) ?? "\(type.rawValue)"
            // Each `STPPaymentMethodParams` only populates the params for its own type.
            fixtures.append(
                Fixture(name: "STPPaymentMethodParams.\(typeName)", object: paymentMethodParams(type: type), checksCompleteness: false)
            )
        }

        // Confirm params with a selection of payment method types. Every payment method type is covered above.
        for type in [STPPaymentMethodType.card, .USBankAccount, .SEPADebit, .link, .klarna] {
            let typeName = STPPaymentMethod.string(from: type) ?? "\(type.rawValue)"
            fixtures.append(
                Fixture(name: "STPPaymentIntentConfirmParams.\(typeName)", object: paymentIntentConfirmParams(paymentMethodType: type))
            )
            fixtures.append(
                Fixture(name: "STPSetupIntentConfirmParams.\(typeName)", object: setupIntentConfirmParams(paymentMethodType: type))
            )
        }
        // Confirm params with only the required properties set.
        fixtures.append(
            Fixture(
                name: "STPPaymentIntentConfirmParams.minimal",
                object: STPPaymentIntentConfirmParams(clientSecret: "pi_123_secret_456"),
                checksCompleteness: false
            )
        )
        fixtures.append(
            Fixture(
                name: "STPSetupIntentConfirmParams.minimal",
                object: STPSetupIntentConfirmParams(clientSecret: "seti_123_secret_456"),
                checksCompleteness: false
            )
        )

        // Standalone type-specific params, including those with no mapped properties.
        for type in STPPaymentMethodType.allCases {
            let params = paymentMethodParams(type: type)
            let typeName = STPPaymentMethod.string(from: type) ?? "\(type.rawValue)"
            let typeSpecificParams: (NSObject & STPFormEncodable)? = {
                switch type {
                case .card: return params.card
                case .alipay: return params.alipay
                case .grabPay: return params.grabPay
                case .iDEAL: return params.iDEAL
                case .FPX: return params.fpx
                case .SEPADebit: return params.sepaDebit
                case .AUBECSDebit: return params.auBECSDebit
                case .bacsDebit: return params.bacsDebit
                case .przelewy24: return params.przelewy24
                case .EPS: return params.eps
                case .bancontact: return params.bancontact
                case .netBanking: return params.netBanking
                case .OXXO: return params.oxxo
                case .payPal: return params.payPal
                case .afterpayClearpay: return params.afterpayClearpay
                case .blik: return params.blik
                case .weChatPay: return params.weChatPay
                case .boleto: return params.boleto
                case .link: return params.link
                case .klarna: return params.klarna
                case .affirm: return params.affirm
                case .USBankAccount: return params.usBankAccount
                case .cashApp: return params.cashApp
                case .revolutPay: return params.revolutPay
                case .swish: return params.swish
                case .mobilePay: return params.mobilePay
                case .vipps: return params.vipps
                case .amazonPay: return params.amazonPay
                case .alma: return params.alma
                case .sunbit: return params.sunbit
                case .billie: return params.billie
                case .satispay: return params.satispay
                case .crypto: return params.crypto
                case .multibanco: return params.multibanco
                case .payPay: return params.payPay
                case .twint: return params.twint
                case .wero: return params.wero
                case .payByBank: return params.payByBank
                case .kakaoPay: return params.kakaoPay
                case .krCard: return params.krCard
                case .naverPay: return params.naverPay
                case .payco: return params.payco
                case .sequra: return params.sequra
                case .scalapay: return params.scalapay
                case .goPay: return params.goPay
                case .mondu: return params.mondu
                case .ngUSSD: return params.ngUSSD
                case .qris: return params.qris
                case .ngWallet: return params.ngWallet
                case .shopeePay: return params.shopeePay
                case .trueMoney: return params.trueMoney
                case .touchNGo: return params.touchNGo
                case .gcash: return params.gcash
                case .momo: return params.momo
                case .ngBankTransfer: return params.ngBankTransfer
                case .ngCard: return params.ngCard
                default: return nil
                }
            }()
            if let typeSpecificParams {
                fixtures.append(Fixture(name: "TypeSpecificParams.\(typeName)", object: typeSpecificParams))
            }
        }
        return fixtures
    }
}
