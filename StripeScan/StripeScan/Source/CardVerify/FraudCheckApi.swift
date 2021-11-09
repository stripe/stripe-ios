import DeviceCheck
import UIKit

@objc public class FraudCheckApi: NSObject {
    static func getSdkVersion(for bundle: Bundle?) -> String? {
        guard let bundle = bundle else { return nil }
        return bundle.infoDictionary?["CFBundleShortVersionString"].flatMap { $0 as? String }
    }
    
    static func deviceType() -> String? {
        var systemInfo = utsname()
        uname(&systemInfo)
        var deviceType = ""
        for char in Mirror(reflecting: systemInfo.machine).children {
            guard let charDigit = (char.value as? Int8) else {
                return nil
            }
            
            if charDigit == 0 {
                break
            }
            
            deviceType += String(UnicodeScalar(UInt8(charDigit)))
        }
        
        return deviceType
    }
    
    static func getDeviceParameters(deviceCheckToken: String?) -> [String: Any] {
        let version = ProcessInfo().operatingSystemVersion
        let osVersion = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        
        //TODO:
        //"locale": "",
        //"carrier": "",
        //"safety_net": ""
        var device: [String: Any] = ["platform": "ios",
                                     "os_version": osVersion,
                                     "ids": [ "vendor_id": UIDevice.current.identifierForVendor?.uuidString]]
        device["type"] = deviceType()
        device["device_check_token"] = deviceCheckToken
        return device
    }
    
    static func getModelVersions() -> [String: Any] {
        let sdkVersion = getSdkVersion(for: Bouncer.getBundle()) ?? "unknown"
        return ["ocr": "sdk_\(sdkVersion)"]
    }
        
    static func cardVerify(scanObject: CardVerifyFraudData.ScanObject, scanStats: [String: Any], cardChallenged: CardVerifyFraudData.CardChallenged, debugForceError: String?, completion: @escaping ((_ payload: String?) -> Void)) {

    }
}
