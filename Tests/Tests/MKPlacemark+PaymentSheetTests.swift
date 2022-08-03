//
//  MKPlacemark+PaymentSheetTests.swift
//  StripeiOS Tests
//
//  Created by Nick Porter on 6/13/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest
@testable import Stripe
import MapKit
import Contacts

class MKPlacemark_PaymentSheetTests: XCTestCase {
    
    // All address dictionaries are based on an actual placemark of an `MKLocalSearchCompletion`
    
    func testAsAddress_UnitedStates() {
        // Search string used to generate address dictionary: "4 Pennsylvania Pl"
        let addressDictionary = [CNPostalAddressStreetKey: "4 Pennsylvania Plaza",
                                 CNPostalAddressStateKey: "NY",
                                CNPostalAddressCountryKey: "United States",
                         CNPostalAddressISOCountryCodeKey: "US",
                                   CNPostalAddressCityKey: "New York",
                                 "SubThoroughfare": "4",
                             CNPostalAddressPostalCodeKey: "10001",
                                 "Thoroughfare": "Pennsylvania Plaza",
                            CNPostalAddressSubLocalityKey: "Manhattan",
                  CNPostalAddressSubAdministrativeAreaKey: "New York County",
                                 "Name": "4 Pennsylvania Plaza"] as [String : Any]
        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(),
                                    addressDictionary: addressDictionary)
        let expectedAddress = PaymentSheet.Address(city: "New York",
                                                   country: "US",
                                                   line1: "4 Pennsylvania Plaza",
                                                   line2: nil,
                                                   postalCode: "10001",
                                                   state: "NY")
        
        XCTAssertEqual(placemark.asAddress, expectedAddress)
    }
    
    func testAsAddress_Canada() {
        // Search string used to generate address dictionary: "40 Bay St To"
        let addressDictionary = [CNPostalAddressStreetKey: "40 Bay St",
                                 CNPostalAddressStateKey: "ON",
                         CNPostalAddressISOCountryCodeKey: "CA",
                                CNPostalAddressCountryKey: "Canada",
                                   CNPostalAddressCityKey: "Toronto",
                                 "SubThoroughfare": "40",
                             CNPostalAddressPostalCodeKey: "M5J 2X2",
                                 "Thoroughfare": "Bay St",
                            CNPostalAddressSubLocalityKey: "Downtown Toronto",
                  CNPostalAddressSubAdministrativeAreaKey: "SubAdministrativeArea",
                                 "Name": "40 Bay St"] as [String : Any]
        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(),
                                    addressDictionary: addressDictionary)
        let expectedAddress = PaymentSheet.Address(city: "Toronto",
                                                   country: "CA",
                                                   line1: "40 Bay St",
                                                   line2: nil,
                                                   postalCode: "M5J 2X2",
                                                   state: "ON")
        
        XCTAssertEqual(placemark.asAddress, expectedAddress)
    }
    
    func testAsAddress_Germany() {
        // Search string used to generate address dictionary: "Rüsternallee 14"
        let addressDictionary = [CNPostalAddressStreetKey: "Rüsternallee 14",
                         CNPostalAddressISOCountryCodeKey: "DE",
                                CNPostalAddressCountryKey: "Germany",
                                   CNPostalAddressCityKey: "Berlin",
                             CNPostalAddressPostalCodeKey: "14050",
                                 "SubThoroughfare": "14",
                                 "Thoroughfare": "Rüsternallee",
                            CNPostalAddressSubLocalityKey: "Charlottenburg-Wilmersdorf",
                  CNPostalAddressSubAdministrativeAreaKey: "Berlin",
                                 "Name": "Rüsternallee 14"] as [String : Any]
        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(),
                                    addressDictionary: addressDictionary)
        let expectedAddress = PaymentSheet.Address(city: "Berlin",
                                                   country: "DE",
                                                   line1: "Rüsternallee 14",
                                                   line2: nil,
                                                   postalCode: "14050",
                                                   state: nil)
        
        XCTAssertEqual(placemark.asAddress, expectedAddress)
    }
    
    func testAsAddress_Brazil() {
        // Search string used to generate address dictionary: "Avenida Paulista 500"
        let addressDictionary = [CNPostalAddressStreetKey: "Avenida Paulista, 500",
                                 CNPostalAddressStateKey: "SP",
                         CNPostalAddressISOCountryCodeKey: "BR",
                                CNPostalAddressCountryKey: "Brazil",
                                   CNPostalAddressCityKey: "Paulínia",
                                 "SubThoroughfare": "500",
                             CNPostalAddressPostalCodeKey: "13145-089",
                                 "Thoroughfare": "Avenida Paulista",
                            CNPostalAddressSubLocalityKey: "Jardim Planalto",
                                 "Name": "Avenida Paulista, 500"] as [String : Any]
        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(),
                                    addressDictionary: addressDictionary)
        let expectedAddress = PaymentSheet.Address(city: "Paulínia",
                                                   country: "BR",
                                                   line1: "Avenida Paulista, 500",
                                                   line2: nil,
                                                   postalCode: "13145-089",
                                                   state: "SP")
 
        XCTAssertEqual(placemark.asAddress, expectedAddress)
    }
    
    func testAsAddress_Japan() {
        // Search string used to generate address dictionary: "Nagatacho 2"
        let addressDictionary = [CNPostalAddressStreetKey: "Nagatacho 2-Chōme",
                                 CNPostalAddressStateKey: "Tokyo",
                         CNPostalAddressISOCountryCodeKey: "JP",
                                CNPostalAddressCountryKey: "Japan",
                                   CNPostalAddressCityKey: "Chiyoda",
                                 "Thoroughfare": "Nagatacho 2-Chōme",
                            CNPostalAddressSubLocalityKey: "Nagatacho",
                                 "Name": "Nagatacho 2-Chōme"] as [String : Any]
        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(),
                                    addressDictionary: addressDictionary)
        let expectedAddress = PaymentSheet.Address(city: "Chiyoda",
                                                   country: "JP",
                                                   line1: "Nagatacho 2-Chōme",
                                                   line2: nil,
                                                   postalCode: nil,
                                                   state: "Tokyo")
        
        XCTAssertEqual(placemark.asAddress, expectedAddress)
    }
    
    func testAsAddress_Australia() {
        // Search string used to generate address dictionary: "488 George St Syd"
        let addressDictionary = [CNPostalAddressStreetKey: "488 George St",
                                 CNPostalAddressStateKey: "NSW",
                         CNPostalAddressISOCountryCodeKey: "AU",
                                CNPostalAddressCountryKey: "Australia",
                                   CNPostalAddressCityKey: "Sydney",
                             CNPostalAddressPostalCodeKey: "2000",
                                 "SubThoroughfare": "488",
                                 "Thoroughfare": "George St",
                  CNPostalAddressSubAdministrativeAreaKey: "Sydney",
                                 "Name": "488 George St"] as [String : Any]
        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(),
                                    addressDictionary: addressDictionary)
        let expectedAddress = PaymentSheet.Address(city: "Sydney",
                                                   country: "AU",
                                                   line1: "488 George St",
                                                   line2: nil,
                                                   postalCode: "2000",
                                                   state: "NSW")
        
        XCTAssertEqual(placemark.asAddress, expectedAddress)
    }
    
}
