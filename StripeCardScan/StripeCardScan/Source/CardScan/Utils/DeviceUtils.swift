//
//  DeviceUtils.swift
//  CardScan
//
//  Created by Jaime Park on 4/15/21.
//

import CoreTelephony
import Foundation
import UIKit

struct ClientIdsUtils {
    static let vendorId: String? = getVendorId()
    
    static internal func getVendorId() -> String? {
        return UIDevice.current.identifierForVendor?.uuidString
    }
}

struct DeviceUtils {
    static let name: String = getDeviceType()
    static let build: String = getBuildVersion()
    static let bootCount: Int? = nil
    static let locale: String? = getDeviceLocale()
    static let carrier: String? = getCarrier()
    static let networkOperator: String? = nil
    static let phoneType: Int? = nil
    static let phoneCount: Int? = nil
    
    static let osVersion: String = getOsVersion()
    static let platform: String = "ios"
    
    static internal func getDeviceType() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        var deviceType = ""
        for char in Mirror(reflecting: systemInfo.machine).children {
            guard let charDigit = (char.value as? Int8) else {
                return ""
            }
            
            if charDigit == 0 {
                break
            }
            
            deviceType += String(UnicodeScalar(UInt8(charDigit)))
        }
        
        return deviceType
    }
    
    static internal func getBuildVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleVersion"].flatMap { $0 as? String } ?? "0000"
    }
    
    static internal func getDeviceLocale() -> String? {
        return NSLocale.preferredLanguages.first
    }

    static func getVendorId() -> String {
        return UIDevice.current.identifierForVendor?.uuidString ?? ""
    }
    
    static internal func getCarrier() -> String? {
        let networkInfo = CTTelephonyNetworkInfo()
        guard let firstNamedCarrier = networkInfo.serviceSubscriberCellularProviders?.first( where: { $0.value.carrierName != nil })?.value else {
            return nil
        }

        return firstNamedCarrier.carrierName
    }
    
    static internal func getOsVersion() -> String {
        let version = ProcessInfo().operatingSystemVersion
        let osVersion = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        return osVersion
    }
}
