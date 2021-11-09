import Foundation

@objc public enum ScanPerformance: Int {
    case fast
    case accurate
}

@objc public class ScanConfiguration: NSObject {
    @objc public var runOnOldDevices = false
    @objc public var setPreviouslyDeniedDevicesAsIncompatible = false
}
