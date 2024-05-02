//
//  HCaptchaDebugInfo.m
//  HCaptcha
//
//  Copyright © 2024 HCaptcha. All rights reserved.
//

// TODO(davide): This is so lurky, delete it
//
//import Foundation
//import CommonCrypto
//import ObjectiveC.runtime
//import UIKit
//
//extension String {
//    func jsSanitize() -> String {
//        return self.replacingOccurrences(of: ".", with: "_")
//    }
//}
//
//private func updateInfoFor(_ image: String, _ ctx: UnsafeMutablePointer<CC_MD5_CTX>, depth: UInt32 = 16) {
//    var count: UInt32 = 0
//    if let imagePtr = (image as NSString).utf8String {
//        let classes = objc_copyClassNamesForImage(imagePtr, &count)
//        for cls in UnsafeBufferPointer<UnsafePointer<CChar>>(start: classes, count: Int(min(depth, count))) {
//            CC_MD5_Update(ctx, cls, CC_LONG(strlen(cls)))
//        }
//        classes?.deallocate()
//    }
//}
//
//private func getFinalHash(_ ctx: UnsafeMutablePointer<CC_MD5_CTX>) -> String {
//    var digest: [UInt8] = Array(repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
//    CC_MD5_Final(&digest, ctx)
//    let hexDigest = digest.map { String(format: "%02hhx", $0) }.joined()
//    return hexDigest
//}
//
//private func bundleShortVersion() -> String {
//    let sdkBundle = Bundle(for: HCaptchaDebugInfo.self)
//    let sdkBundleShortVer = sdkBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
//    return sdkBundleShortVer?.jsSanitize() ?? "unknown"
//}
//
//class HCaptchaDebugInfo {
//
//    public static let json: String = HCaptchaDebugInfo.buildDebugInfoJson()
//
//    private class func buildDebugInfoJson() -> String {
//        let failsafeJson = "[]"
//        let encoder = JSONEncoder()
//        guard let jsonData = try? encoder.encode(buildDebugInfo()) else { return failsafeJson }
//        guard let json = String(data: jsonData, encoding: .utf8) else { return failsafeJson }
//        return json
//    }
//
//    private class func buildDebugInfo() -> [String] {
//        let depth: UInt32 = 16
//        var depsCount = 0
//        var sysCount = 0
//        let depsCtx = UnsafeMutablePointer<CC_MD5_CTX>.allocate(capacity: 1)
//        let sysCtx = UnsafeMutablePointer<CC_MD5_CTX>.allocate(capacity: 1)
//        let appCtx = UnsafeMutablePointer<CC_MD5_CTX>.allocate(capacity: 1)
//        CC_MD5_Init(depsCtx)
//        CC_MD5_Init(sysCtx)
//        CC_MD5_Init(appCtx)
//
//        for framework in Bundle.allFrameworks {
//            guard let frameworkPath = URL(string: framework.bundlePath) else { continue }
//            let frameworkBin = frameworkPath.deletingPathExtension().lastPathComponent
//            let image = frameworkPath.appendingPathComponent(frameworkBin).absoluteString
//            let systemFramework = image.contains("/Library/PrivateFrameworks/") ||
//                                  image.contains("/System/Library/Frameworks/")
//
//            if systemFramework && sysCount < depth {
//                sysCount += 1
//            } else if !systemFramework && depsCount < depth {
//                depsCount += 1
//            } else if sysCount < depth || depsCount < depth {
//                continue
//            } else {
//                break
//            }
//
//            let md5Ctx = systemFramework ? sysCtx : depsCtx
//            updateInfoFor(image, md5Ctx)
//        }
//
//        if let executablePath = Bundle.main.executablePath {
//            updateInfoFor(executablePath, appCtx)
//        }
//
//        let depsHash = getFinalHash(depsCtx)
//        let sysHash = getFinalHash(sysCtx)
//        let appHash = getFinalHash(appCtx)
//        let iver = UIDevice.current.systemVersion.jsSanitize()
//
//        return [
//            "sys_\(String(describing: sysHash))",
//            "deps_\(String(describing: depsHash))",
//            "app_\(String(describing: appHash))",
//            "iver_\(String(describing: iver))",
//            "sdk_\(bundleShortVersion())"
//        ]
//    }
//}
