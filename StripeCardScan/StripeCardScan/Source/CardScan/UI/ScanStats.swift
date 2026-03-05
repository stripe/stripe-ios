//
//  ScanStats.swift
//  CardScan
//
//  Created by Sam King on 11/13/18.
//
import Foundation

struct ScanStats {
    var scans = 0
    var torchOn = false
    var orientation = "Portrait"
    var success: Bool?
    var endTime: Date?
    var model: String?
    var deviceType: String?
    var permissionGranted: Bool?
    var userCanceled: Bool = false

    init() {
        var systemInfo = utsname()
        uname(&systemInfo)
        var deviceType = ""
        for char in Mirror(reflecting: systemInfo.machine).children {
            guard let charDigit = (char.value as? Int8) else {
                return
            }

            if charDigit == 0 {
                break
            }

            deviceType += String(UnicodeScalar(UInt8(charDigit)))
        }

        self.deviceType = deviceType
    }

}
