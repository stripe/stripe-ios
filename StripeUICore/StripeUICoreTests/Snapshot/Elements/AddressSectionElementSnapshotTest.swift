//
//  AddressSectionElementSnapshotTest.swift
//  StripeUICoreTests
//
//  Created by Yuki Tokuhiro on 7/28/22.
//

import FBSnapshotTestCase
import StripeCoreTestUtils
@_spi(STP) @testable import StripeUICore

class AddressSectionElementSnapshotTest: FBSnapshotTestCase {
    let dummyAddressSpecProvider: AddressSpecProvider = {
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(format: "ACSZP", require: "AZ", cityNameType: .post_town, stateNameType: .state, zip: "", zipNameType: .pin),
        ]
        return specProvider
    }()
    
    override func setUp() {
        super.setUp()
//        recordMode = true
    }

    func test_billing_address_same_as_shipping() throws {
        let sut = AddressSectionElement(
            addressSpecProvider: dummyAddressSpecProvider,
            defaults: .init(address: .init(city: "San Francisco", country: "US", line1: "510 Townsend St.", line2: nil, postalCode: "94102", state: "California")),
            additionalFields: .init(
                billingSameAsShippingCheckbox: .enabled(isOptional: false)
            )
        )
        sut.view.autosizeHeight(width: 300)
        STPSnapshotVerifyView(sut.view)
    }
}
