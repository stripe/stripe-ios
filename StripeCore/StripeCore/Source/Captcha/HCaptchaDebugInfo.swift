//
//  HCaptchaDebugInfo.m
//  HCaptcha
//
//  Copyright © 2024 HCaptcha. All rights reserved.
//

import CryptoKit
import Foundation
import ObjectiveC.runtime
import UIKit

extension String {
    func jsSanitize() -> String {
        return self.replacingOccurrences(of: ".", with: "_")
    }
}

private func updateInfoFor(_ image: String, _ ctx: inout Insecure.MD5, depth: UInt32 = 16) {
    var count: UInt32 = 0
    if let imagePtr = (image as NSString).utf8String {
        let classes = objc_copyClassNamesForImage(imagePtr, &count)
        for cls in UnsafeBufferPointer<UnsafePointer<CChar>>(start: classes, count: Int(min(depth, count))) {
            ctx.update(bufferPointer: .init(start: cls, count: strlen(cls)))
        }
        classes?.deallocate()
    }
}

private func getFinalHash(_ ctx: inout Insecure.MD5) -> String {
    let digest = ctx.finalize()
    let hexDigest = digest.map { String(format: "%02hhx", $0) }.joined()
    return hexDigest
}

private func bundleShortVersion() -> String {
    let sdkBundle = Bundle(for: HCaptchaDebugInfo.self)
    let sdkBundleShortVer = sdkBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    return sdkBundleShortVer?.jsSanitize() ?? "unknown"
}

class HCaptchaDebugInfo {

    static let json: String = HCaptchaDebugInfo.buildDebugInfoJson()

    private class func buildDebugInfoJson() -> String {
        let failsafeJson = "[]"
        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(buildDebugInfo()) else { return failsafeJson }
        guard let json = String(data: jsonData, encoding: .utf8) else { return failsafeJson }
        return json
    }

    private class func buildDebugInfo() -> [String] {
        let depth: UInt32 = 16
        var depsCount = 0
        var sysCount = 0
        var depsCtx = Insecure.MD5()
        var sysCtx = Insecure.MD5()
        var appCtx = Insecure.MD5()

        for framework in Bundle.allFrameworks {
            guard let frameworkPath = URL(string: framework.bundlePath) else { continue }
            let frameworkBin = frameworkPath.deletingPathExtension().lastPathComponent
            let image = frameworkPath.appendingPathComponent(frameworkBin).absoluteString
            let systemFramework = image.contains("/Library/PrivateFrameworks/") ||
                                  image.contains("/System/Library/Frameworks/")

            if systemFramework && sysCount < depth {
                sysCount += 1
            } else if !systemFramework && depsCount < depth {
                depsCount += 1
            } else if sysCount < depth || depsCount < depth {
                continue
            } else {
                break
            }

            var md5Ctx = systemFramework ? sysCtx : depsCtx
            updateInfoFor(image, &md5Ctx)
        }

        if let executablePath = Bundle.main.executablePath {
            updateInfoFor(executablePath, &appCtx)
        }

        let depsHash = getFinalHash(&depsCtx)
        let sysHash = getFinalHash(&sysCtx)
        let appHash = getFinalHash(&appCtx)
        let iver = UIDevice.current.systemVersion.jsSanitize()

        return [
            "sys_\(String(describing: sysHash))",
            "deps_\(String(describing: depsHash))",
            "app_\(String(describing: appHash))",
            "iver_\(String(describing: iver))",
            "sdk_\(bundleShortVersion())",
        ]
    }
}
