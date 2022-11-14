//
//  ScanStats.swift
//  CardScan
//
//  Created by Sam King on 11/13/18.
//
import CoreGraphics
import Foundation
import UIKit

struct ScanStats {
    var startTime = Date()
    var scans = 0
    var flatDigitsRecognized = 0
    var flatDigitsDetected = 0
    var embossedDigitsRecognized = 0
    var embossedDigitsDetected = 0
    var torchOn = false
    var orientation = "Portrait"
    var success: Bool?
    var endTime: Date?
    var model: String?
    var algorithm: String?
    var bin: String?
    var lastFlatBoxes: [CGRect]?
    var lastEmbossedBoxes: [CGRect]?
    var deviceType: String?
    var numberRect: CGRect?
    var expiryBoxes: [CGRect]?
    var cardsDetected = 0
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

    func toDictionaryForAnalytics() -> [String: Any] {
        return [
            "scans": self.scans,
            "cards_detected": self.cardsDetected,
            "torch_on": self.torchOn,
            "orientation": self.orientation,
            "success": self.success ?? false,
            "duration": self.duration(),
            "model": self.model ?? "unknown",
            "permission_granted": self.permissionGranted.map { $0 ? "granted" : "denied" }
                ?? "not_determined",
            "device_type": self.deviceType ?? "",
            "user_canceled": self.userCanceled,
        ]
    }

    func duration() -> Double {
        guard let endTime = self.endTime else {
            return 0.0
        }

        return endTime.timeIntervalSince(self.startTime)
    }

    func image(from base64String: String?) -> UIImage? {
        guard let string = base64String else {
            return nil
        }

        return Data(base64Encoded: string).flatMap { UIImage(data: $0) }
    }
}
