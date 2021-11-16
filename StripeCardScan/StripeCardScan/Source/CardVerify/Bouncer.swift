import Foundation

class Bouncer: NSObject  {
    
    // This is the configuration CardVerify users should use
    static func configuration() -> ScanConfiguration {
        let configuration = ScanConfiguration()
        configuration.runOnOldDevices = true
        return configuration
    }
    
    // Call this method before scanning any cards
    static  func configure(apiKey: String, useExperimentalScreenDetectionModel: Bool = false) {
        if #available(iOS 11.2, *) {
            ScanBaseViewController.configure(apiKey: apiKey)
        }
    }
    
    static var useFlashFlow = false
    
    static  func isCompatible() -> Bool {
        if #available(iOS 11.2, *) {
            return ScanBaseViewController.isCompatible(configuration: configuration())
        } else {
            return false
        }
    }
}
