import Foundation

@objc public class Bouncer: NSObject  {
    public static var bundleIdentifier = "com.stripe.stripe-scan"
    public static var namedBundle = "StripeScan"
    public static var namedBundleExtension = "bundle"
    
    @objc public static var cardVerifyBundle: Bundle?
    
    // This is the configuration CardVerify users should use
    static func configuration() -> ScanConfiguration {
        let configuration = ScanConfiguration()
        configuration.runOnOldDevices = true
        return configuration
    }
    
    // Call this method before scanning any cards
    @objc static public func configure(apiKey: String, useExperimentalScreenDetectionModel: Bool = false) {
        CSBundle.bundleIdentifier = bundleIdentifier
        CSBundle.namedBundle = namedBundle
        if #available(iOS 11.2, *) {
            ScanBaseViewController.configure(apiKey: apiKey)
        }
    }
    
    @objc public static var useFlashFlow = false
    
    @objc static public func isCompatible() -> Bool {
        if #available(iOS 11.2, *) {
            return ScanBaseViewController.isCompatible(configuration: configuration())
        } else {
            return false
        }
    }
        
    public static func getBundle() -> Bundle? {
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
