import Foundation

class Bouncer: NSObject  {
    static var bundleIdentifier = "com.stripe.stripe-scan"
    static var namedBundle = "StripeScan"
    static var namedBundleExtension = "bundle"
    
    static var cardVerifyBundle: Bundle?
    
    // This is the configuration CardVerify users should use
    static func configuration() -> ScanConfiguration {
        let configuration = ScanConfiguration()
        configuration.runOnOldDevices = true
        return configuration
    }
    
    // Call this method before scanning any cards
    static  func configure(apiKey: String, useExperimentalScreenDetectionModel: Bool = false) {
        CSBundle.bundleIdentifier = bundleIdentifier
        CSBundle.namedBundle = namedBundle
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
        
    static func getBundle() -> Bundle? {
        if let bundle = cardVerifyBundle {
            return bundle
        }

        if let bundle = Bundle(identifier: bundleIdentifier) {
            return bundle
        }
        
        // as a fall back try getting a named bundle for cases when we deploy as source
        guard let bundleUrl = Bundle(for: Bouncer.self).url(forResource: namedBundle, withExtension: namedBundleExtension)  else {
            return nil
        }
        
        return Bundle(url: bundleUrl)
    }
}
