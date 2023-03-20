import Foundation

enum ScanPerformance: Int {
    case fast
    case accurate
}

class ScanConfiguration: NSObject {
    var runOnOldDevices = false
    var setPreviouslyDeniedDevicesAsIncompatible = false
}
