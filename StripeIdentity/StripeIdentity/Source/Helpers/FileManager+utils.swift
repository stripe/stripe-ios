//
//  FileManager+utils.swift
//  StripeIdentity
//
//  Created by Kenneth Ackerson on 8/20/25.
//

extension FileManager {
    func cachesDirectoryURL() -> URL {
        let cachesDirectory: URL
        if #available(iOS 16.0, *) {
            cachesDirectory = URL.cachesDirectory
        } else {
            let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
            cachesDirectory = paths.first ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        }
        
        return cachesDirectory
    }
}
