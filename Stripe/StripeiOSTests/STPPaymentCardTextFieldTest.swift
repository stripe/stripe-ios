//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentCardTextFieldTest.m
//  Stripe
//
//  Created by Jack Flintermann on 8/26/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentsUI
import UIKit
import XCTest

/// Class that implements STPPaymentCardTextFieldDelegate and uses a block for each delegate method.
class PaymentCardTextFieldBlockDelegate: NSObject, STPPaymentCardTextFieldDelegate {
    var didChange: ((STPPaymentCardTextField) -> Void)?
    var willEndEditingForReturn: ((STPPaymentCardTextField) -> Void)?
    var didEndEditing: ((STPPaymentCardTextField) -> Void)?
    // add more properties for other delegate methods as this test needs them

    func paymentCardTextFieldDidChange(_ textField: STPPaymentCardTextField) {
        if let didChange {
            didChange(textField)
        }
    }

    func paymentCardTextFieldWillEndEditing(forReturn textField: STPPaymentCardTextField) {
        if let willEndEditingForReturn {
            willEndEditingForReturn(textField)
        }
    }

    func paymentCardTextFieldDidEndEditing(_ textField: STPPaymentCardTextField) {
        if let didEndEditing {
            didEndEditing(textField)
        }
    }
}

class STPPaymentCardTextFieldTest: XCTestCase {
    override class func setUp() {
        super.setUp()
        STPAPIClient.shared.publishableKey = STPTestingDefaultPublishableKey
    }

    func testIntrinsicContentSize() {
        let textField = STPPaymentCardTextField()

        let iOS8SystemFont = UIFont(name: "HelveticaNeue", size: 18)
        textField.font = iOS8SystemFont!
        XCTAssertEqual(textField.intrinsicContentSize.height, 44, accuracy: 0.1)
        XCTAssertEqual(textField.intrinsicContentSize.width, 241, accuracy: 0.1)

        let iOS9SystemFont = UIFont.systemFont(ofSize: 18)
        textField.font = iOS9SystemFont
        XCTAssertEqual(textField.intrinsicContentSize.height, 44, accuracy: 0.1)
        XCTAssertEqual(textField.intrinsicContentSize.width, 253, accuracy: 1.0)

        textField.font = UIFont(name: "Avenir", size: 44)!
        XCTAssertEqual(textField.intrinsicContentSize.height, 62, accuracy: 0.1)
        XCTAssertEqual(textField.intrinsicContentSize.width, 472, accuracy: 0.1)
    }

    func testSetCard_numberUnknown() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "1"
        card.number = number
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        sut.paymentMethodParams = params

        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.errorImage(for: .unknown)!.pngData()

        XCTAssertNotNil(sut.focusedTextFieldForLayout)
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == STPCardFieldType.number.rawValue)
        if let imgData {
            XCTAssertTrue(expectedImgData == imgData)
        }
        XCTAssertEqual(sut.numberField.text, number)
        XCTAssertEqual(sut.expirationField.text!.count, 0)
        XCTAssertEqual(sut.cvcField.text!.count, 0)
        XCTAssertNil(sut.currentFirstResponderField())
    }

    func testSetCard_expiration() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 50)
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        sut.paymentMethodParams = params
        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .unknown)?.pngData()

        XCTAssertNotNil(sut.focusedTextFieldForLayout)
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == STPCardFieldType.number.rawValue)
        if let imgData {
            XCTAssertTrue(expectedImgData! == imgData)
        }
        XCTAssertEqual(sut.numberField.text?.count, Int(0))
        XCTAssertEqual(sut.expirationField.text, "10/50")
        XCTAssertEqual(sut.cvcField.text?.count, Int(0))
        XCTAssertNil(sut.currentFirstResponderField())
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_CVC() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let cvc = "123"
        card.cvc = cvc
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        sut.paymentMethodParams = params
        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .unknown)?.pngData()

        XCTAssertNotNil(sut.focusedTextFieldForLayout)
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == STPCardFieldType.number.rawValue)
        if let imgData {
            XCTAssertTrue(expectedImgData == imgData)
        }
        XCTAssertEqual(sut.numberField.text!.count, Int(0))
        XCTAssertEqual(sut.expirationField.text!.count, Int(0))
        XCTAssertEqual(sut.cvcField.text, cvc)
        XCTAssertNil(sut.currentFirstResponderField())
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_updatesCVCValidity() {
        let sut = STPPaymentCardTextField()
        sut.numberField.text = "378282246310005"
        sut.cvcField.text = "1234"
        sut.expirationField.text = "10/50"
        XCTAssertTrue(sut.cvcField.validText)
        sut.numberField.text = "4242424242424242"
        XCTAssertFalse(sut.cvcField.validText)
    }

    func testSetCard_numberVisa() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "424242"
        card.number = number
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        sut.paymentMethodParams = params

        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .visa)?.pngData()

        XCTAssertNotNil(sut.focusedTextFieldForLayout)
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == STPCardFieldType.number.rawValue)
        if let imgData {
            XCTAssertNotNil(expectedImgData == imgData)
        }
        XCTAssertEqual(sut.numberField.text, number)
        XCTAssertEqual(sut.expirationField.text!.count, Int(0))
        XCTAssertEqual(sut.cvcField.text!.count, Int(0))
        XCTAssertEqual(sut.cvcField.placeholder, "CVC")
        XCTAssertNil(sut.currentFirstResponderField())
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_numberVisaInvalid() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "4242111111111111"
        card.number = number
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        sut.paymentMethodParams = params

        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.errorImage(for: .visa)!.pngData()

        if let imgData {
            XCTAssertTrue(expectedImgData == imgData)
        }
    }

    func testSetCard_withCBCInfo() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "424242"
        card.number = number
        card.networks = .init(preferred: "visa")
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        sut.paymentMethodParams = params
        XCTAssertEqual(sut.paymentMethodParams.card!.networks!.preferred, "visa")
    }

    func testSetCard_numberAmex() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "378282"
        card.number = number
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        sut.paymentMethodParams = params

        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .amex)?.pngData()

        XCTAssertNotNil(sut.focusedTextFieldForLayout)
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == STPCardFieldType.number.rawValue)
        if let imgData {
            XCTAssertTrue(expectedImgData == imgData)
        }
        XCTAssertEqual(sut.numberField.text, number)
        XCTAssertEqual(sut.cvcField.text!.count, Int(0))
        XCTAssertEqual(sut.cvcField.placeholder, "CVC")
        XCTAssertNil(sut.currentFirstResponderField())
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_numberAmexInvalid() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "378282246311111"
        card.number = number
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        sut.paymentMethodParams = params

        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.errorImage(for: .amex)!.pngData()

        XCTAssertNotNil(sut.focusedTextFieldForLayout)
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == STPCardFieldType.number.rawValue)
        if let imgData {
            XCTAssertTrue(expectedImgData == imgData)
        }
    }

    func testSetCard_numberAndExpiration() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "4242424242424242"
        card.number = number
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 50)
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        sut.paymentMethodParams = params

        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .visa)?.pngData()

        XCTAssertNotNil(sut.focusedTextFieldForLayout)
        if let imgData {
            XCTAssertTrue(expectedImgData == imgData)
        }
        XCTAssertEqual(sut.numberField.text, number)
        XCTAssertEqual(sut.expirationField.text, "10/50")
        XCTAssertEqual(sut.cvcField.text!.count, Int(0))
        XCTAssertNil(sut.currentFirstResponderField())
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_partialNumberAndExpiration() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "424242"
        card.number = number
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 50)
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        sut.paymentMethodParams = params

        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .visa)?.pngData()

        XCTAssertNotNil(sut.focusedTextFieldForLayout)
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == STPCardFieldType.number.rawValue)
        if let imgData {
            XCTAssertTrue(expectedImgData == imgData)
        }
        XCTAssertEqual(sut.numberField.text, number)
        XCTAssertEqual(sut.expirationField.text, "10/50")
        XCTAssertEqual(sut.cvcField.text!.count, Int(0))
        XCTAssertNil(sut.currentFirstResponderField())
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_numberAndCVC() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "378282246310005"
        let cvc = "123"
        card.number = number
        card.cvc = cvc
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        sut.paymentMethodParams = params

        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .amex)?.pngData()

        XCTAssertNotNil(sut.focusedTextFieldForLayout)
        if let imgData {
            XCTAssertTrue(expectedImgData == imgData)
        }
        XCTAssertEqual(sut.numberField.text, number)
        XCTAssertEqual(sut.expirationField.text!.count, Int(0))
        XCTAssertEqual(sut.cvcField.text, cvc)
        XCTAssertNil(sut.currentFirstResponderField())
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_expirationAndCVC() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let cvc = "123"
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 50)
        card.cvc = cvc
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        sut.paymentMethodParams = params

        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .unknown)?.pngData()

        XCTAssertNotNil(sut.focusedTextFieldForLayout)
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == STPCardFieldType.number.rawValue)
        if let imgData {
            XCTAssertTrue(expectedImgData == imgData)
        }
        XCTAssertEqual(sut.numberField.text!.count, Int(0))
        XCTAssertEqual(sut.expirationField.text, "10/50")
        XCTAssertEqual(sut.cvcField.text, cvc)
        XCTAssertNil(sut.currentFirstResponderField())
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_completeCardCountryWithoutPostal() {
        let sut = STPPaymentCardTextField()
        sut.countryCode = "BZ"
        let card = STPPaymentMethodCardParams()
        let number = "4242424242424242"
        let cvc = "123"
        card.number = number
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 50)
        card.cvc = cvc
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        sut.paymentMethodParams = params

        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .visa)?.pngData()

        XCTAssertNotNil(sut.focusedTextFieldForLayout)
        if let imgData {
            XCTAssertTrue(expectedImgData == imgData)
        }
        XCTAssertEqual(sut.numberField.text, number)
        XCTAssertEqual(sut.expirationField.text, "10/50")
        XCTAssertEqual(sut.cvcField.text, cvc)
        XCTAssertNil(sut.currentFirstResponderField())
        XCTAssertTrue(sut.isValid)
    }

    func testSetCard_completeCardNoPostal() {
        let sut = STPPaymentCardTextField()
        sut.postalCodeEntryEnabled = false
        let card = STPPaymentMethodCardParams()
        let number = "4242424242424242"
        let cvc = "123"
        card.number = number
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 50)
        card.cvc = cvc
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        sut.paymentMethodParams = params

        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .visa)?.pngData()

        XCTAssertNotNil(sut.focusedTextFieldForLayout)
        if let imgData {
            XCTAssertTrue(expectedImgData == imgData)
        }
        XCTAssertEqual(sut.numberField.text, number)
        XCTAssertEqual(sut.expirationField.text, "10/50")
        XCTAssertEqual(sut.cvcField.text, cvc)
        XCTAssertNil(sut.currentFirstResponderField())
        XCTAssertTrue(sut.isValid)
    }

    func testSetCard_completeCard() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "4242424242424242"
        let cvc = "123"
        card.number = number
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 50)
        card.cvc = cvc

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.address = STPPaymentMethodAddress()
        billingDetails.address!.postalCode = "90210"
        let params = STPPaymentMethodParams(card: card, billingDetails: billingDetails, metadata: nil)
        sut.paymentMethodParams = params

        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .visa)?.pngData()

        XCTAssertNotNil(sut.focusedTextFieldForLayout)
        if let imgData {
            XCTAssertTrue(expectedImgData == imgData)
        }
        XCTAssertEqual(sut.numberField.text, number)
        XCTAssertEqual(sut.expirationField.text, "10/50")
        XCTAssertEqual(sut.cvcField.text, cvc)
        XCTAssertNil(sut.currentFirstResponderField())
        XCTAssertTrue(sut.isValid)
    }

    func testSetCard_empty() {
        let sut = STPPaymentCardTextField()
        sut.numberField.text = "4242424242424242"
        sut.cvcField.text = "123"
        sut.expirationField.text = "10/50"
        let card = STPPaymentMethodCardParams()
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        sut.paymentMethodParams = params

        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .unknown)?.pngData()

        XCTAssertNotNil(sut.focusedTextFieldForLayout)
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == STPCardFieldType.number.rawValue)
        if let imgData {
            XCTAssertTrue(expectedImgData == imgData)
        }
        XCTAssertEqual(sut.numberField.text!.count, Int(0))
        XCTAssertEqual(sut.expirationField.text!.count, Int(0))
        XCTAssertEqual(sut.cvcField.text!.count, Int(0))
        XCTAssertNil(sut.currentFirstResponderField())
        XCTAssertFalse(sut.isValid)
    }

    func testSettingTextUpdatesViewModelText() {
        let sut = STPPaymentCardTextField()
        sut.numberField.text = "4242424242424242"
        XCTAssertEqual(sut.viewModel.cardNumber, sut.numberField.text)

        sut.cvcField.text = "123"
        XCTAssertEqual(sut.viewModel.cvc, sut.cvcField.text)

        sut.expirationField.text = "10/50"
        XCTAssertEqual(sut.viewModel.rawExpiration, sut.expirationField.text)
        XCTAssertEqual(sut.viewModel.expirationMonth, "10")
        XCTAssertEqual(sut.viewModel.expirationYear, "50")
    }

    func testSettingTextUpdatesCardParams() {
        let sut = STPPaymentCardTextField()
        sut.numberField.text = "4242424242424242"
        sut.cvcField.text = "123"
        sut.expirationField.text = "10/50"
        sut.postalCodeField.text = "90210"

        let card = sut.paymentMethodParams.card
        XCTAssertNotNil(card)
        XCTAssertEqual(card?.number, "4242424242424242")
        XCTAssertEqual(card?.cvc, "123")
        XCTAssertEqual(card?.expMonth?.intValue ?? 0, 10)
        XCTAssertEqual(card?.expYear?.intValue ?? 0, 50)
        XCTAssertEqual(sut.paymentMethodParams.billingDetails!.address!.postalCode, "90210")
    }

    func testSettingBillingDetailsRetainsBillingDetails() {
        let sut = STPPaymentCardTextField()
        let params = STPPaymentMethodCardParams()
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Test test"

        sut.paymentMethodParams = STPPaymentMethodParams(card: params, billingDetails: billingDetails, metadata: nil)
        let actual = sut.paymentMethodParams

        XCTAssertEqual("Test test", actual.billingDetails!.name)
    }

    func testSettingMetadataRetainsMetadata() {
        let sut = STPPaymentCardTextField()
        let params = STPPaymentMethodCardParams()
        sut.paymentMethodParams = STPPaymentMethodParams(card: params, billingDetails: nil, metadata: [
            "hello": "test",
        ])
        let actual = sut.paymentMethodParams

        XCTAssertEqual([
            "hello": "test",
        ], actual.metadata)
    }

    func testSettingPostalCodeUpdatesCardParams() {
        let sut = STPPaymentCardTextField()
        sut.numberField.text = "4242424242424242"
        sut.cvcField.text = "123"
        sut.expirationField.text = "10/50"
        sut.postalCodeField.text = "90210"

        let params = sut.paymentMethodParams.card
        XCTAssertNotNil(params)
        XCTAssertEqual(params?.number, "4242424242424242")
        XCTAssertEqual(params?.cvc, "123")
        XCTAssertEqual(params?.expMonth?.intValue ?? 0, 10)
        XCTAssertEqual(params?.expYear?.intValue ?? 0, 50)
    }

    func testEmptyPostalCodeVendsNilAddress() {
        let sut = STPPaymentCardTextField()
        sut.numberField.text = "4242424242424242"
        sut.cvcField.text = "123"
        sut.expirationField.text = "10/50"

        XCTAssertNil(sut.paymentMethodParams.billingDetails?.address?.postalCode)
        let params = sut.paymentMethodParams.card
        XCTAssertNotNil(params)
        XCTAssertEqual(params?.number, "4242424242424242")
        XCTAssertEqual(params?.cvc, "123")
        XCTAssertEqual(params?.expMonth?.intValue ?? 0, 10)
        XCTAssertEqual(params?.expYear?.intValue ?? 0, 50)
    }

    func testAccessingCardParamsDuringSettingCardParams() {
        let delegate = PaymentCardTextFieldBlockDelegate()
        delegate.didChange = { textField in
            // delegate reads the `cardParams` for any reason it wants
            _ = textField.paymentMethodParams.card
        }
        let sut = STPPaymentCardTextField()
        sut.delegate = delegate

        let params = STPPaymentMethodCardParams()
        params.number = "4242424242424242"
        params.cvc = "123"

        sut.paymentMethodParams = STPPaymentMethodParams(card: params, billingDetails: nil, metadata: nil)
        let actual = sut.paymentMethodParams.card

        XCTAssertEqual("4242424242424242", actual!.number)
        XCTAssertEqual("123", actual!.cvc)
    }

    func testSetCardParamsCopiesObject() {
        let sut = STPPaymentCardTextField()
        let params = STPPaymentMethodCardParams()

        params.number = "4242424242424242" // legit
        sut.paymentMethodParams = STPPaymentMethodParams(card: params, billingDetails: nil, metadata: nil)

        // fetching `sut.cardParams` returns a copy, so edits happen to caller's copy
        sut.paymentMethodParams.card!.number = "number 1"

        // `sut` copied `params` (& `params.address`) when set, so edits to original don't show up
        params.number = "number 2"

        XCTAssertEqual("4242424242424242", sut.paymentMethodParams.card!.number)

        XCTAssertNotEqual("number 1", sut.paymentMethodParams.card!.number, "return value from cardParams cannot be edited inline")

        XCTAssertNotEqual("number 2", sut.paymentMethodParams.card!.number, "caller changed their copy after setCardParams:")
    }

    // MARK: - paymentMethodParams

    func testSetCard_numberUnknown_pm() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "1"
        card.number = number
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.errorImage(for: .unknown)!.pngData()

        XCTAssertNotNil(sut.focusedTextFieldForLayout)
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == STPCardFieldType.number.rawValue)
        if let imgData {
            XCTAssertTrue(expectedImgData == imgData)
        }
        XCTAssertEqual(sut.numberField.text, number)
        XCTAssertEqual(sut.expirationField.text!.count, Int(0))
        XCTAssertEqual(sut.cvcField.text!.count, Int(0))
        XCTAssertNil(sut.currentFirstResponderField())
    }

    func testSetCard_expiration_pm() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 50)
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .unknown)?.pngData()

        XCTAssertNotNil(sut.focusedTextFieldForLayout)
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == STPCardFieldType.number.rawValue)
        if let imgData {
            XCTAssertTrue(expectedImgData == imgData)
        }
        XCTAssertEqual(sut.numberField.text!.count, Int(0))
        XCTAssertEqual(sut.expirationField.text, "10/50")
        XCTAssertEqual(sut.cvcField.text!.count, Int(0))
        XCTAssertNil(sut.currentFirstResponderField())
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_CVC_pm() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let cvc = "123"
        card.cvc = cvc
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .unknown)?.pngData()

        XCTAssertNotNil(sut.focusedTextFieldForLayout)
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == STPCardFieldType.number.rawValue)
        if let imgData {
            XCTAssertTrue(expectedImgData == imgData)
        }
        XCTAssertEqual(sut.numberField.text!.count, Int(0))
        XCTAssertEqual(sut.expirationField.text!.count, Int(0))
        XCTAssertEqual(sut.cvcField.text, cvc)
        XCTAssertNil(sut.currentFirstResponderField())
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_numberVisa_pm() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "424242"
        card.number = number
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .visa)?.pngData()

        XCTAssertNotNil(sut.focusedTextFieldForLayout)
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == STPCardFieldType.number.rawValue)
        if let imgData {
            XCTAssertTrue(expectedImgData == imgData)
        }
        XCTAssertEqual(sut.numberField.text, number)
        XCTAssertEqual(sut.expirationField.text!.count, Int(0))
        XCTAssertEqual(sut.cvcField.text!.count, Int(0))
        XCTAssertEqual(sut.cvcField.placeholder, "CVC")
        XCTAssertNil(sut.currentFirstResponderField())
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_numberVisaInvalid_pm() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "4242111111111111"
        card.number = number
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.errorImage(for: .visa)!.pngData()

        if let imgData {
            XCTAssertTrue(expectedImgData == imgData)
        }
    }

    func testSetCard_numberAmex_pm() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "378282"
        card.number = number
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .amex)?.pngData()

        XCTAssertNotNil(sut.focusedTextFieldForLayout)
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == STPCardFieldType.number.rawValue)
        if let imgData {
            XCTAssertTrue(expectedImgData == imgData)
        }
        XCTAssertEqual(sut.numberField.text, number)
        XCTAssertEqual(sut.cvcField.text!.count, Int(0))
        XCTAssertEqual(sut.cvcField.placeholder, "CVC")
        XCTAssertNil(sut.currentFirstResponderField())
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_numberAmexInvalid_pm() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "378282246311111"
        card.number = number
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.errorImage(for: .amex)!.pngData()

        XCTAssertNotNil(sut.focusedTextFieldForLayout)
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == STPCardFieldType.number.rawValue)
        if let imgData {
            XCTAssertTrue(expectedImgData == imgData)
        }
    }

    func testSetCard_numberAndExpiration_pm() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "4242424242424242"
        card.number = number
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 50)
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .visa)?.pngData()

        XCTAssertNotNil(sut.focusedTextFieldForLayout)
        if let imgData {
            XCTAssertTrue(expectedImgData == imgData)
        }
        XCTAssertEqual(sut.numberField.text, number)
        XCTAssertEqual(sut.expirationField.text, "10/50")
        XCTAssertEqual(sut.cvcField.text!.count, Int(0))
        XCTAssertNil(sut.currentFirstResponderField())
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_partialNumberAndExpiration_pm() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "424242"
        card.number = number
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 50)
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .visa)?.pngData()

        XCTAssertNotNil(sut.focusedTextFieldForLayout)
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == STPCardFieldType.number.rawValue)
        if let imgData {
            XCTAssertTrue(expectedImgData == imgData)
        }
        XCTAssertEqual(sut.numberField.text, number)
        XCTAssertEqual(sut.expirationField.text, "10/50")
        XCTAssertEqual(sut.cvcField.text!.count, Int(0))
        XCTAssertNil(sut.currentFirstResponderField())
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_numberAndCVC_pm() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "378282246310005"
        let cvc = "123"
        card.number = number
        card.cvc = cvc
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .amex)?.pngData()

        XCTAssertNotNil(sut.focusedTextFieldForLayout)
        if let imgData {
            XCTAssertTrue(expectedImgData == imgData)
        }
        XCTAssertEqual(sut.numberField.text, number)
        XCTAssertEqual(sut.expirationField.text!.count, Int(0))
        XCTAssertEqual(sut.cvcField.text, cvc)
        XCTAssertNil(sut.currentFirstResponderField())
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_expirationAndCVC_pm() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let cvc = "123"
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 50)
        card.cvc = cvc
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .unknown)?.pngData()

        XCTAssertNotNil(sut.focusedTextFieldForLayout)
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == STPCardFieldType.number.rawValue)
        if let imgData {
            XCTAssertTrue(expectedImgData == imgData)
        }
        XCTAssertEqual(sut.numberField.text!.count, Int(0))
        XCTAssertEqual(sut.expirationField.text, "10/50")
        XCTAssertEqual(sut.cvcField.text, cvc)
        XCTAssertNil(sut.currentFirstResponderField())
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_completeCardCountryWithoutPostal_pm() {
        let sut = STPPaymentCardTextField()
        sut.countryCode = "BZ"
        let card = STPPaymentMethodCardParams()
        let number = "4242424242424242"
        let cvc = "123"
        card.number = number
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 50)
        card.cvc = cvc
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .visa)?.pngData()

        XCTAssertNotNil(sut.focusedTextFieldForLayout)
        if let imgData {
            XCTAssertTrue(expectedImgData == imgData)
        }
        XCTAssertEqual(sut.numberField.text, number)
        XCTAssertEqual(sut.expirationField.text, "10/50")
        XCTAssertEqual(sut.cvcField.text, cvc)
        XCTAssertNil(sut.currentFirstResponderField())
        XCTAssertTrue(sut.isValid)
    }

    func testSetCard_completeCardNoPostal_pm() {
        let sut = STPPaymentCardTextField()
        sut.postalCodeEntryEnabled = false
        let card = STPPaymentMethodCardParams()
        let number = "4242424242424242"
        let cvc = "123"
        card.number = number
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 50)
        card.cvc = cvc
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .visa)?.pngData()

        XCTAssertNotNil(sut.focusedTextFieldForLayout)
        if let imgData {
            XCTAssertTrue(expectedImgData == imgData)
        }
        XCTAssertEqual(sut.numberField.text, number)
        XCTAssertEqual(sut.expirationField.text, "10/50")
        XCTAssertEqual(sut.cvcField.text, cvc)
        XCTAssertNil(sut.currentFirstResponderField())
        XCTAssertTrue(sut.isValid)
    }

    func testSetCard_completeCard_pm() {
        let sut = STPPaymentCardTextField()
        let card = STPPaymentMethodCardParams()
        let number = "4242424242424242"
        let cvc = "123"
        card.number = number
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 50)
        card.cvc = cvc
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: STPPaymentMethodBillingDetails(postalCode: "90210", countryCode: "US"), metadata: nil)

        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .visa)?.pngData()

        XCTAssertNotNil(sut.focusedTextFieldForLayout)
        if let imgData {
            XCTAssertTrue(expectedImgData == imgData)
        }
        XCTAssertEqual(sut.numberField.text, number)
        XCTAssertEqual(sut.expirationField.text, "10/50")
        XCTAssertEqual(sut.cvcField.text, cvc)
        XCTAssertNil(sut.currentFirstResponderField())
        let isvalid = sut.isValid
        XCTAssertTrue(isvalid)

        let paymentMethodParams = sut.paymentMethodParams
        XCTAssertNotNil(paymentMethodParams)

        let sutCardParams = paymentMethodParams.card
        XCTAssertNotNil(sutCardParams)

        XCTAssertEqual(sutCardParams?.number, card.number)
        XCTAssertEqual(sutCardParams?.expMonth, card.expMonth)
        XCTAssertEqual(sutCardParams?.expYear, card.expYear)
        XCTAssertEqual(sutCardParams?.cvc, card.cvc)

        let sutBillingDetails = paymentMethodParams.billingDetails
        XCTAssertNotNil(sutBillingDetails)

        let sutAddress = sutBillingDetails?.address
        XCTAssertNotNil(sutAddress)

        XCTAssertEqual(sutAddress?.postalCode, "90210")
        XCTAssertEqual(sutAddress?.country, "US")
    }

    func testSetCard_empty_pm() {
        let sut = STPPaymentCardTextField()
        sut.numberField.text = "4242424242424242"
        sut.cvcField.text = "123"
        sut.expirationField.text = "10/50"
        let card = STPPaymentMethodCardParams()
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .unknown)?.pngData()

        XCTAssertNotNil(sut.focusedTextFieldForLayout)
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == STPCardFieldType.number.rawValue)
        if let imgData {
            XCTAssertTrue(expectedImgData == imgData)
        }
        XCTAssertEqual(sut.numberField.text!.count, Int(0))
        XCTAssertEqual(sut.expirationField.text!.count, Int(0))
        XCTAssertEqual(sut.cvcField.text!.count, Int(0))
        XCTAssertNil(sut.currentFirstResponderField())
        XCTAssertFalse(sut.isValid)
    }

    func testUsesPreferredNetworks() {
        STPAPIClient.shared.publishableKey = STPTestingDefaultPublishableKey
        let sut = STPPaymentCardTextField()
        sut.cbcEnabledOverride = true
        sut.preferredNetworks = [.visa]
        let card = STPPaymentMethodCardParams()
        card.number = "4973019750239993"
        card.expMonth = 12
        card.expYear = 43
        card.cvc = "123"
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        sut.paymentMethodParams = params
        let exp = expectation(description: "Wait for CBC load")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertEqual(sut.viewModel.cbcController.selectedBrand, .visa)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3.0)
    }

    func testOBOCBC() {
        STPAPIClient.shared.publishableKey = STPTestingDefaultPublishableKey
        let sut = STPPaymentCardTextField()
        sut.onBehalfOf = "acct_abc123"
        XCTAssertEqual(sut.viewModel.cbcController.onBehalfOf, "acct_abc123")
    }

    func testFourDigitCVCNotAllowedUnknownCBCCard() {
        STPAPIClient.shared.publishableKey = STPTestingDefaultPublishableKey
        let sut = STPPaymentCardTextField()
        sut.cbcEnabledOverride = true
        sut.preferredNetworks = [.visa]
        let card = STPPaymentMethodCardParams()
        card.number = "4973019750239993"
        card.expMonth = 12
        card.expYear = 43
        card.cvc = "1234"
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        sut.paymentMethodParams = params
        XCTAssertFalse(sut.isValid)
    }
}

// N.B. It is eexpected for setting the card params to generate API response errors
// because we are calling to the card metadata service without configuration STPAPIClient
class STPPaymentCardTextFieldUITests: XCTestCase {
    var window: UIWindow!
    var sut: STPPaymentCardTextField!

    override class func setUp() {
        super.setUp()
        STPAPIClient.shared.publishableKey = STPTestingDefaultPublishableKey
    }

    override func setUp() {
        super.setUp()
        window = UIWindow(frame: UIScreen.main.bounds)
        let textField = STPPaymentCardTextField(frame: window.bounds)
        window?.addSubview(textField)
        XCTAssertTrue(textField.numberField.canBecomeFirstResponder, "text field cannot become first responder")
        sut = textField
    }

    // MARK: - UI Tests

    func testSetCard_allFields_whileEditingNumber() {
        XCTAssertTrue(sut.numberField.becomeFirstResponder(), "text field is not first responder")
        let card = STPPaymentMethodCardParams()
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.address = STPPaymentMethodAddress()
        billingDetails.address!.postalCode = "90210"
        let number = "4242424242424242"
        let cvc = "123"
        card.number = number
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 50)
        card.cvc = cvc
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: billingDetails, metadata: nil)

        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .visa)?.pngData()

        XCTAssertNil(sut.focusedTextFieldForLayout)
        if let imgData {
            XCTAssertTrue(expectedImgData == imgData)
        }
        XCTAssertEqual(sut.numberField.text, number)
        XCTAssertEqual(sut.expirationField.text, "10/50")
        XCTAssertEqual(sut.cvcField.text, cvc)
        XCTAssertEqual(sut.postalCode, "90210")
        XCTAssertFalse(sut.isFirstResponder, "after `setCardParams:`, if all fields are valid, should resign firstResponder")
        XCTAssertTrue(sut.isValid)
    }

    func testSetCard_partialNumberAndExpiration_whileEditingExpiration() {
        XCTAssertTrue(sut.expirationField.becomeFirstResponder(), "text field is not first responder")
        let card = STPPaymentMethodCardParams()
        let number = "42"
        card.number = number
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 50)
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.cvcImage(for: .visa)?.pngData()

        XCTAssertNotNil(sut.focusedTextFieldForLayout)
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == STPCardFieldType.CVC.rawValue)
        if let imgData {
            XCTAssertTrue(expectedImgData == imgData)
        }
        XCTAssertEqual(sut.numberField.text, number)
        XCTAssertEqual(sut.expirationField.text, "10/50")
        XCTAssertEqual(sut.cvcField.text!.count, Int(0))
        XCTAssertTrue(sut.cvcField.isFirstResponder, "after `setCardParams:`, when firstResponder becomes valid, first invalid field should become firstResponder")
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_number_whileEditingCVC() {
        XCTAssertTrue(sut.cvcField.becomeFirstResponder(), "text field is not first responder")
        let card = STPPaymentMethodCardParams()
        let number = "4242424242424242"
        card.number = number
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.cvcImage(for: .visa)?.pngData()

        XCTAssertNotNil(sut.focusedTextFieldForLayout)
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == STPCardFieldType.CVC.rawValue)
        if let imgData {
            XCTAssertTrue(expectedImgData == imgData)
        }
        XCTAssertEqual(sut.numberField.text, number)
        XCTAssertEqual(sut.expirationField.text!.count, Int(0))
        XCTAssertEqual(sut.cvcField.text!.count, Int(0))
        XCTAssertTrue(sut.cvcField.isFirstResponder, "after `setCardParams:`, if firstResponder is invalid, it should remain firstResponder")
        XCTAssertFalse(sut.isValid)
    }

    func testSetCard_empty_whileEditingNumber() {
        sut.numberField.text = "4242424242424242"
        sut.cvcField.text = "123"
        sut.expirationField.text = "10/50"
        XCTAssertTrue(sut.numberField.becomeFirstResponder(), "text field is not first responder")
        let card = STPPaymentMethodCardParams()
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

        let imgData = sut.brandImageView.image?.pngData()
        let expectedImgData = STPPaymentCardTextField.brandImage(for: .unknown)?.pngData()

        XCTAssertNotNil(sut.focusedTextFieldForLayout)
        XCTAssertTrue(sut.focusedTextFieldForLayout?.intValue ?? 0 == STPCardFieldType.number.rawValue)
        if let imgData {
            XCTAssertTrue(expectedImgData! == imgData)
        }
        XCTAssertEqual(sut.numberField.text!.count, Int(0))
        XCTAssertEqual(sut.expirationField.text!.count, Int(0))
        XCTAssertEqual(sut.cvcField.text!.count, Int(0))
        XCTAssertTrue(sut.numberField.isFirstResponder, "after `setCardParams:` that clears the text fields, the first invalid field should become firstResponder")
        XCTAssertFalse(sut.isValid)
    }

    func testBecomeFirstResponder() {
        sut.postalCodeEntryEnabled = false
        XCTAssertTrue(sut.canBecomeFirstResponder)
        XCTAssertTrue(sut.becomeFirstResponder())
        XCTAssertTrue(sut.isFirstResponder)

        XCTAssertEqual(sut.numberField, sut.currentFirstResponderField())

        sut.becomeFirstResponder()
        XCTAssertEqual(
            sut.numberField,
            sut.currentFirstResponderField(),
            "Repeated calls to becomeFirstResponder should not change the firstResponder")

        sut.numberField.text = """
            4242\
            4242\
            4242\
            4242
            """

        // Don't unit test auto-advance from number field here because we don't know the cache state

        XCTAssertTrue(sut.cvcField.becomeFirstResponder())
        XCTAssertEqual(
            sut.cvcField,
            sut.currentFirstResponderField(),
            "We don't block other fields from becoming firstResponder")

        XCTAssertTrue(sut.becomeFirstResponder())
        XCTAssertEqual(
            sut.cvcField,
            sut.currentFirstResponderField(),
            "Calling becomeFirstResponder does not change the currentFirstResponder")

        sut.expirationField.text = "10/50"
        sut.cvcField.text = "123"

        sut.resignFirstResponder()
        XCTAssertTrue(sut.canBecomeFirstResponder)
        XCTAssertTrue(sut.becomeFirstResponder())

        XCTAssertEqual(
            sut.cvcField,
            sut.currentFirstResponderField(),
            "When all fields are valid, the last one should be the preferred firstResponder")

        sut.postalCodeEntryEnabled = true
        XCTAssertFalse(sut.isValid)

        sut.resignFirstResponder()
        XCTAssertTrue(sut.becomeFirstResponder())
        XCTAssertEqual(
            sut.postalCodeField,
            sut.currentFirstResponderField(),
            "When postalCodeEntryEnabled=YES, it should become firstResponder after other fields are valid")

        sut.expirationField.text = ""
        sut.resignFirstResponder()
        XCTAssertTrue(sut.becomeFirstResponder())
        XCTAssertEqual(
            sut.expirationField,
            sut.currentFirstResponderField(),
            "Moves firstResponder back to expiration, because it's not valid anymore")

        sut.expirationField.text = "10/50"
        sut.postalCodeField.text = "90210"

        sut.resignFirstResponder()
        XCTAssertTrue(sut.becomeFirstResponder())
        XCTAssertEqual(
            sut.postalCodeField,
            sut.currentFirstResponderField(),
            "When all fields are valid, the last one should be the preferred firstResponder")
    }

    func testShouldReturnCyclesThroughFields() {
        let delegate = PaymentCardTextFieldBlockDelegate()
        delegate.willEndEditingForReturn = { _ in
            XCTFail("Did not expect editing to end in this test")
        }
        sut.delegate = delegate

        sut.becomeFirstResponder()
        XCTAssertTrue(sut.numberField.isFirstResponder)

        XCTAssertFalse(sut.numberField.delegate!.textFieldShouldReturn!(sut.numberField), "shouldReturn = NO")
        XCTAssertTrue(sut.expirationField.isFirstResponder, "with side effect to move 1st responder to next field")

        XCTAssertFalse(sut.expirationField.delegate!.textFieldShouldReturn!(sut.expirationField), "shouldReturn = NO")
        XCTAssertTrue(sut.cvcField.isFirstResponder, "with side effect to move 1st responder to next field")

        XCTAssertFalse(sut.cvcField.delegate!.textFieldShouldReturn!(sut.cvcField), "shouldReturn = NO")
        XCTAssertTrue(sut.postalCodeField.isFirstResponder, "with side effect to move 1st responder to next field")

        XCTAssertFalse(sut.postalCodeField.delegate!.textFieldShouldReturn!(sut.postalCodeField), "shouldReturn = NO")
        XCTAssertTrue(sut.numberField.isFirstResponder, "with side effect to move 1st responder from last field to first invalid field")
    }

    func testShouldReturnCyclesThroughFieldsWithoutPostal() {
        let delegate = PaymentCardTextFieldBlockDelegate()
        delegate.willEndEditingForReturn = { _ in
            XCTFail("Did not expect editing to end in this test")
        }
        sut.delegate = delegate
        sut.postalCodeEntryEnabled = false

        sut.becomeFirstResponder()
        XCTAssertTrue(sut.numberField.isFirstResponder)

        XCTAssertFalse(sut.numberField.delegate!.textFieldShouldReturn!(sut.numberField), "shouldReturn = NO")

        XCTAssertTrue(sut.expirationField.isFirstResponder, "with side effect to move 1st responder to next field")

        XCTAssertFalse(sut.expirationField.delegate!.textFieldShouldReturn!(sut.expirationField), "shouldReturn = NO")
        XCTAssertTrue(sut.cvcField.isFirstResponder, "with side effect to move 1st responder to next field")

        XCTAssertFalse(sut.cvcField.delegate!.textFieldShouldReturn!(sut.cvcField), "shouldReturn = NO")
        XCTAssertTrue(sut.numberField.isFirstResponder, "with side effect to move 1st responder from last field to first invalid field")
    }

    func testShouldReturnDismissesWhenValidNoPostalCode() {
        var hasReturned = false
        var didEnd = false

        sut.postalCodeEntryEnabled = false
        sut.paymentMethodParams = STPPaymentMethodParams(card: STPFixtures.paymentMethodCardParams(), billingDetails: nil, metadata: nil)

        let delegate = PaymentCardTextFieldBlockDelegate()
        delegate.willEndEditingForReturn = { _ in
            XCTAssertFalse(didEnd, "willEnd is called before didEnd")
            XCTAssertFalse(hasReturned, "willEnd is only called once")
            hasReturned = true
        }

        delegate.didEndEditing = { _ in
            XCTAssertTrue(hasReturned, "didEndEditing should be called after willEnd")
            XCTAssertFalse(didEnd, "didEnd is only called once")
            didEnd = true
        }

        sut.delegate = delegate
        sut.becomeFirstResponder()
        XCTAssertTrue(sut.cvcField.isFirstResponder, "when textfield is filled out, default first responder is the last field")

        XCTAssertFalse(hasReturned, "willEndEditingForReturn delegate method should not have been called yet")

        XCTAssertFalse(sut.cvcField.delegate!.textFieldShouldReturn!(sut.cvcField), "shouldReturn = NO")

        XCTAssertNil(sut.currentFirstResponderField(), "Should have resigned first responder")
        XCTAssertTrue(hasReturned, "delegate method has been invoked")
        XCTAssertTrue(didEnd, "delegate method has been invoked")
    }

    func testShouldReturnDismissesWhenValid() {
        var hasReturned = false
        var didEnd = false

        sut.paymentMethodParams = STPPaymentMethodParams(card: STPFixtures.paymentMethodCardParams(), billingDetails: nil, metadata: nil)
        sut.postalCodeField.text = "90210"
        let delegate = PaymentCardTextFieldBlockDelegate()
        delegate.willEndEditingForReturn = { _ in
            XCTAssertFalse(didEnd, "willEnd is called before didEnd")
            XCTAssertFalse(hasReturned, "willEnd is only called once")
            hasReturned = true
        }

        delegate.didEndEditing = { _ in
            XCTAssertTrue(hasReturned, "didEndEditing should be called after willEnd")
            XCTAssertFalse(didEnd, "didEnd is only called once")
            didEnd = true
        }

        sut.delegate = delegate
        sut.becomeFirstResponder()
        XCTAssertTrue(sut.postalCodeField.isFirstResponder, "when textfield is filled out, default first responder is the last field")

        XCTAssertFalse(hasReturned, "willEndEditingForReturn delegate method should not have been called yet")
        XCTAssertFalse(sut.postalCodeField.delegate!.textFieldShouldReturn!(sut.postalCodeField), "shouldReturn = NO")

        XCTAssertNil(sut.currentFirstResponderField(), "Should have resigned first responder")
        XCTAssertTrue(hasReturned, "delegate method has been invoked")
        XCTAssertTrue(didEnd, "delegate method has been invoked")
    }

    func testValueUpdatesWhenDeletingOnEmptyField() {
        let card = STPPaymentMethodCardParams()
        let number = "4242424242424242"
        card.number = number
        sut.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        var hasChanged = false
        let delegate = PaymentCardTextFieldBlockDelegate()
        delegate.didChange = { textField in
            XCTAssertEqual(textField.numberField.text, "424242424242424")
            XCTAssertEqual(textField.cardNumber, "424242424242424")
            XCTAssertFalse(hasChanged, "didChange delegate method should not have been called yet")
            hasChanged = true
        }

        sut.delegate = delegate
        sut.becomeFirstResponder()
        sut.deleteBackward()
        XCTAssertEqual(sut.numberField.text, "424242424242424")
        XCTAssertEqual(sut.cardNumber, "424242424242424")
        XCTAssertTrue(hasChanged, "delegate method has been invoked")
    }
}
