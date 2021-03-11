//
//  STPBSBNumberValidator.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 3/5/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

class STPBSBNumberValidator: STPNumericStringValidator {
    class func validationState(forText text: String) -> STPTextValidationState {
        let numericText = self.sanitizedNumericString(for: text)
        if numericText.count == 0 {
            return .empty
        } else if numericText.count > kBSBNumberLength {
            return .invalid
        } else {
            if !self._isPossibleValidBSBNumber(numericText) {
                return .invalid
            } else {
                return (numericText.count == kBSBNumberLength) ? .complete : .incomplete
            }
        }
    }

    @objc(formattedSanitizedTextFromString:) class func formattedSanitizedText(from string: String)
        -> String?
    {
        var numericText = self.sanitizedNumericString(for: string).stp_safeSubstring(
            to: kBSBNumberLength)
        if numericText.count >= kBSBNumberDashIndex {
            numericText.insert(
                contentsOf: "-",
                at: numericText.index(numericText.startIndex, offsetBy: kBSBNumberDashIndex))
        }

        return numericText
    }

    class func identity(forText text: String) -> String? {
        return self._data(forText: text)?["name"] as? String
    }

    class func icon(forText text: String?) -> UIImage {

        let iconName = self._data(forText: text ?? "")?["icon"] as? String
        if let iconName = iconName {
            return STPImageLibrary.safeImageNamed(iconName, templateIfAvailable: false)
        } else {
            return STPImageLibrary.safeImageNamed("stp_icon_bank", templateIfAvailable: false)
        }
    }

    class func _isPossibleValidBSBNumber(_ text: String) -> Bool {
        if text.count == 0 || self.identity(forText: text) != nil {
            // this is faster than iterating through keys so try it first
            return true
        } else {
            let bsbData = self._BSBData()
            for key in bsbData.keys {
                guard let key = key as? String else {
                    continue
                }
                if key.count > text.count && key.hasPrefix(text) {
                    return true
                }
            }
            return false
        }

    }

    static let _BSBDataSBSBData: [AnyHashable: Any] = {
        var bsbData: [AnyHashable: Any] = [:]
        if let url = STPBundleLocator.stripeResourcesBundle.url(
            forResource: "au_becs_bsb", withExtension: "json"),
            let inputStream = InputStream.init(url: url)
        {
            inputStream.open()
            if let jsonData = try? JSONSerialization.jsonObject(with: inputStream, options: [])
                as? [AnyHashable: Any]
            {
                bsbData = jsonData
            }
            inputStream.close()
        }
        return bsbData
    }()

    class func _BSBData() -> [AnyHashable: Any] {
        if let key = STPAPIClient.shared.publishableKey, key.contains("_test_") {
            var editedBSBData = _BSBDataSBSBData
            // Add Stripe Test Bank
            editedBSBData["00"] = [
                "name": "Stripe Test Bank",
                "icon": "stripe",
            ]
            return editedBSBData
        }

        return _BSBDataSBSBData
    }

    static let _dataSBSBKeyLengths: [Int] = {
        var keyLengths = Set<Int>()
        for (bsbKey, _) in _BSBData() {
            if let bsbKey = bsbKey as? String {
                keyLengths.insert(bsbKey.count)
            }
        }
        let orderedKeyLengths = [Int](keyLengths).sorted().reversed()
        return [Int](orderedKeyLengths)
    }()

    class func _data(forText text: String) -> [AnyHashable: Any]? {

        let bsbData = self._BSBData()

        for keyLength in _dataSBSBKeyLengths {
            let subString = text.stp_safeSubstring(to: keyLength)
            if let data = bsbData[subString] {
                return data as? [AnyHashable: Any]
            }
        }

        return nil
    }
}

private let kBSBNumberLength = Int(6)
private let kBSBNumberDashIndex = String.IndexDistance(3)
