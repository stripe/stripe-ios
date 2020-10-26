//
//  STPAddressViewModel.swift
//  Stripe
//
//  Created by Jack Flintermann on 4/21/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Contacts
import CoreLocation
import UIKit

protocol STPAddressViewModelDelegate: class {
  func addressViewModelDidChange(_ addressViewModel: STPAddressViewModel)
  func addressViewModel(_ addressViewModel: STPAddressViewModel, addedCellAt index: Int)
  func addressViewModel(_ addressViewModel: STPAddressViewModel, removedCellAt index: Int)
  func addressViewModelWillUpdate(_ addressViewModel: STPAddressViewModel)
  func addressViewModelDidUpdate(_ addressViewModel: STPAddressViewModel)
}

class STPAddressViewModel: STPAddressFieldTableViewCellDelegate {
  private(set) var addressCells: [STPAddressFieldTableViewCell] = []
  weak var delegate: STPAddressViewModelDelegate?

  var addressFieldTableViewCountryCode: String? = Locale.autoupdatingCurrent.regionCode ?? "" {
    didSet {
      updatePostalCodeCellIfNecessary()
      if let addressFieldTableViewCountryCode = addressFieldTableViewCountryCode {
        for cell in addressCells {
          cell.delegateCountryCodeDidChange(countryCode: addressFieldTableViewCountryCode)
        }
      }
    }
  }

  var address: STPAddress {
    get {
      let address = STPAddress()
      for cell in addressCells {

        switch cell.type {
        case .name:
          address.name = cell.contents
        case .line1:
          address.line1 = cell.contents
        case .line2:
          address.line2 = cell.contents
        case .city:
          address.city = cell.contents
        case .state:
          address.state = cell.contents
        case .zip:
          address.postalCode = cell.contents
        case .country:
          address.country = cell.contents
        case .email:
          address.email = cell.contents
        case .phone:
          address.phone = cell.contents
        }
      }
      // Prefer to use the contents of STPAddressFieldTypeCountry, but fallback to
      // `addressFieldTableViewCountryCode` if nil (important for STPBillingAddressFieldsPostalCode)
      address.country = address.country ?? addressFieldTableViewCountryCode
      return address
    }
    set(address) {
      if let country = address.country {
        addressFieldTableViewCountryCode = country
      }

      for cell in addressCells {
        switch cell.type {
        case .name:
          cell.contents = address.name
        case .line1:
          cell.contents = address.line1
        case .line2:
          cell.contents = address.line2
        case .city:
          cell.contents = address.city
        case .state:
          cell.contents = address.state
        case .zip:
          cell.contents = address.postalCode
        case .country:
          cell.contents = address.country
        case .email:
          cell.contents = address.email
        case .phone:
          cell.contents = address.phone
        }
      }
    }
  }

  /* The default value of availableCountries is nil, which will allow all known countries. */
  var availableCountries: Set<String>?

  var isValid: Bool {
    if isBillingAddress {
      if requiredBillingAddressFields == .postalCode {
        return true  // The AddressViewModel is only for address fields. Determining whether the postal code is present is up to the STPCardTextFieldViewModel.
      } else {
        return address.containsRequiredFields(requiredBillingAddressFields)
      }

    } else {
      if let requiredShippingAddressFields = requiredShippingAddressFields {
        return address.containsRequiredShippingAddressFields(requiredShippingAddressFields)
      }
      return false
    }
  }

  // The default value of availableCountries is nil, which will allow all known countries.
  init(
    requiredBillingFields requiredBillingAddressFields: STPBillingAddressFields,
    availableCountries: Set<String>? = nil
  ) {
    isBillingAddress = true
    self.availableCountries = availableCountries
    self.requiredBillingAddressFields = requiredBillingAddressFields
    switch requiredBillingAddressFields {
    case .none:
      addressCells = []
    case .zip, .postalCode:
      addressCells = []  // Postal code cell will be added later if necessary
    case .full:
      addressCells = [
        STPAddressFieldTableViewCell(type: .name, contents: "", lastInList: false, delegate: self),
        STPAddressFieldTableViewCell(type: .line1, contents: "", lastInList: false, delegate: self),
        STPAddressFieldTableViewCell(type: .line2, contents: "", lastInList: false, delegate: self),
        STPAddressFieldTableViewCell(
          type: .country, contents: addressFieldTableViewCountryCode, lastInList: false,
          delegate: self),
        // Postal code cell will be added here later if necessary
        STPAddressFieldTableViewCell(type: .city, contents: "", lastInList: false, delegate: self),
        STPAddressFieldTableViewCell(type: .state, contents: "", lastInList: true, delegate: self),
      ]
    case .name:
      addressCells = [
        STPAddressFieldTableViewCell(type: .name, contents: "", lastInList: true, delegate: self)
      ]
    default:
      fatalError()
    }
    commonInit()
  }

  init(
    requiredShippingFields requiredShippingAddressFields: Set<STPContactField>,
    availableCountries: Set<String>? = nil
  ) {
    isBillingAddress = false
    self.availableCountries = availableCountries
    self.requiredShippingAddressFields = requiredShippingAddressFields
    var cells: [STPAddressFieldTableViewCell] = []

    if requiredShippingAddressFields.contains(STPContactField.name) {
      cells.append(
        STPAddressFieldTableViewCell(type: .name, contents: "", lastInList: false, delegate: self))
    }
    if requiredShippingAddressFields.contains(.emailAddress) {
      cells.append(
        STPAddressFieldTableViewCell(type: .email, contents: "", lastInList: false, delegate: self))
    }
    if requiredShippingAddressFields.contains(STPContactField.postalAddress) {
      var postalCells = [
        STPAddressFieldTableViewCell(type: .name, contents: "", lastInList: false, delegate: self),
        STPAddressFieldTableViewCell(type: .line1, contents: "", lastInList: false, delegate: self),
        STPAddressFieldTableViewCell(type: .line2, contents: "", lastInList: false, delegate: self),
        STPAddressFieldTableViewCell(
          type: .country, contents: addressFieldTableViewCountryCode, lastInList: false,
          delegate: self),
        // Postal code cell will be added here later if necessary
        STPAddressFieldTableViewCell(type: .city, contents: "", lastInList: false, delegate: self),
        STPAddressFieldTableViewCell(type: .state, contents: "", lastInList: false, delegate: self),
      ]
      if requiredShippingAddressFields.contains(.name) {
        postalCells.remove(at: 0)
      }
      cells.append(contentsOf: postalCells.compactMap { $0 })
    }
    if requiredShippingAddressFields.contains(.phoneNumber) {
      cells.append(
        STPAddressFieldTableViewCell(type: .phone, contents: "", lastInList: false, delegate: self))
    }
    if let lastCell = cells.last {
      lastCell.lastInList = true
    }
    addressCells = cells
    commonInit()
  }

  private func cell(at index: Int) -> STPAddressFieldTableViewCell? {
    guard index > 0,
      index < addressCells.count
    else {
      return nil
    }
    return addressCells[index]
  }

  private var isBillingAddress = false
  private var requiredBillingAddressFields: STPBillingAddressFields = .none
  private var requiredShippingAddressFields: Set<STPContactField>?
  private var showingPostalCodeCell = false
  private var geocodeInProgress = false

  private func commonInit() {
    if let countryCode = Locale.autoupdatingCurrent.regionCode {
      addressFieldTableViewCountryCode = countryCode
    } else {
      addressFieldTableViewCountryCode = ""
    }
    updatePostalCodeCellIfNecessary()
  }

  private func updatePostalCodeCellIfNecessary() {
    delegate?.addressViewModelWillUpdate(self)
    let shouldBeShowingPostalCode = STPPostalCodeValidator.postalCodeIsRequired(
      forCountryCode: addressFieldTableViewCountryCode)

    if shouldBeShowingPostalCode && !showingPostalCodeCell {
      if containsStateAndPostalFields() {
        // Add before city
        let zipFieldIndex = addressCells.firstIndex(where: { $0.type == .city }) ?? 0

        var mutableAddressCells = addressCells
        mutableAddressCells.insert(
          STPAddressFieldTableViewCell(type: .zip, contents: "", lastInList: false, delegate: self),
          at: zipFieldIndex)
        addressCells = mutableAddressCells
        delegate?.addressViewModel(self, addedCellAt: zipFieldIndex)
        delegate?.addressViewModelDidChange(self)
      }
    } else if !shouldBeShowingPostalCode && showingPostalCodeCell {
      if containsStateAndPostalFields() {
        if let zipFieldIndex = addressCells.firstIndex(where: { $0.type == .zip }) {

          var mutableAddressCells = addressCells
          mutableAddressCells.remove(at: zipFieldIndex)
          addressCells = mutableAddressCells
          delegate?.addressViewModel(self, removedCellAt: zipFieldIndex)
          delegate?.addressViewModelDidChange(self)
        }
      }
    }
    showingPostalCodeCell = shouldBeShowingPostalCode
    delegate?.addressViewModelDidUpdate(self)
  }

  private func containsStateAndPostalFields() -> Bool {
    if isBillingAddress {
      return requiredBillingAddressFields == .full
    } else {
      return requiredShippingAddressFields?.contains(.postalAddress) ?? false
    }
  }

  func updateCityAndState(fromZipCodeCell zipCell: STPAddressFieldTableViewCell?) {

    let zipCode = zipCell?.contents

    if geocodeInProgress || zipCode == nil || !(zipCell?.textField?.validText ?? false)
      || !(addressFieldTableViewCountryCode == "US")
    {
      return
    }

    var cityCell: STPAddressFieldTableViewCell?
    var stateCell: STPAddressFieldTableViewCell?
    for cell in addressCells {
      if cell.type == .city {
        cityCell = cell
      } else if cell.type == .state {
        stateCell = cell
      }
    }

    if (cityCell == nil && stateCell == nil)
      || ((cityCell?.contents?.count ?? 0) > 0 || (stateCell?.contents?.count ?? 0) > 0)
    {
      // Don't auto fill if either have text already
      // Or if neither are non-nil
      return
    } else {
      geocodeInProgress = true
      let geocoder = CLGeocoder()

      let onCompletion: CLGeocodeCompletionHandler = { placemarks, error in
        stpDispatchToMainThreadIfNecessary({
          if (placemarks?.count ?? 0) > 0 && error == nil {
            let placemark = placemarks?.first
            if (cityCell?.contents?.count ?? 0) == 0 && (stateCell?.contents?.count ?? 0) == 0
              && (zipCell?.contents == zipCode)
            {
              // Check contents again to make sure they're still empty
              // And that zipcode hasn't changed to something else
              cityCell?.contents = placemark?.locality
              stateCell?.contents = placemark?.administrativeArea
            }
          }
          self.geocodeInProgress = false
        })
      }

      let address = CNMutablePostalAddress()
      address.postalCode = zipCode ?? ""
      address.isoCountryCode = addressFieldTableViewCountryCode ?? ""

      geocoder.geocodePostalAddress(
        address,
        completionHandler: onCompletion)
    }
  }

  private func cell(after cell: STPAddressFieldTableViewCell?) -> STPAddressFieldTableViewCell? {
    guard let cell = cell,
      let cellIndex = addressCells.firstIndex(of: cell),
      cellIndex + 1 < addressCells.count
    else {
      return nil
    }
    return addressCells[cellIndex + 1]
  }

  func addressFieldTableViewCellDidUpdateText(_ cell: STPAddressFieldTableViewCell?) {
    delegate?.addressViewModelDidChange(self)
  }

  func addressFieldTableViewCellDidReturn(_ cell: STPAddressFieldTableViewCell?) {
    _ = self.cell(after: cell)?.becomeFirstResponder()
  }

  func addressFieldTableViewCellDidEndEditing(_ cell: STPAddressFieldTableViewCell?) {
    if cell?.type == .zip {
      updateCityAndState(fromZipCodeCell: cell)
    }
  }

}
