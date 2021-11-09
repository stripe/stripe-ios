//
//  ScanStats.swift
//  CardScan
//
//  Created by Sam King on 11/13/18.
//
import CoreGraphics
import Foundation
import UIKit

public struct ScanStats {
    var startTime = Date()
    public var scans = 0
    public var flatDigitsRecognized = 0
    public var flatDigitsDetected = 0
    public var embossedDigitsRecognized = 0
    public var embossedDigitsDetected = 0
    public var torchOn = false
    public var orientation = "Portrait"
    public var success: Bool?
    public var endTime: Date?
    public var model: String?
    public var algorithm: String?
    public var bin: String?
    public var lastFlatBoxes: [CGRect]?
    public var lastEmbossedBoxes: [CGRect]?
    public var deviceType: String?
    public var numberRect: CGRect?
    public var expiryBoxes: [CGRect]?
    public var cardsDetected = 0
    public var permissionGranted: Bool?
    public var userCanceled: Bool = false
    
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
    
    public func toDictionaryForAnalytics() -> [String: Any] {
        return ["scans": self.scans,
                "cards_detected": self.cardsDetected,
                "torch_on": self.torchOn,
                "orientation": self.orientation,
                "success": self.success ?? false,
                "duration": self.duration(),
                "model": self.model ?? "unknown",
                "permission_granted": self.permissionGranted.map { $0 ? "granted" : "denied" } ?? "not_determined",
                "device_type": self.deviceType ?? "",
                "user_canceled": self.userCanceled]
    }
    
    
    public func duration() -> Double {
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
