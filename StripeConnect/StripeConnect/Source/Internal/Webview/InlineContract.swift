//
//  InlineContract.swift
//  StripeConnect
//

import CoreGraphics
import Foundation

/// Validates the values Connect.js sends for inline components and the windows it opens as native sheets
enum InlineContract {
    static let maxHeight: Double = 10_000

    private static let maxSheetIdLength = 64
    private static let osSheetParam = "os_sheet"
    private static let osSheetIdParam = "os_sheet_id"
    private static let accessoryLayerPathPrefix = "/accessory_layer_"
    private static let accessoryLayerPathSuffix = ".html"

    /// Returns `height` in CSS pixels clamped to the range Connect.js sends, or nil if it isn't a number
    static func clampedHeight(_ height: Double) -> CGFloat? {
        guard height.isFinite else { return nil }
        return CGFloat(min(max(height, 0), maxHeight))
    }

    /// Sheet ids match `^[A-Za-z0-9-]{1,64}$`
    private static func isValidSheetId(_ sheetId: String) -> Bool {
        (1...maxSheetIdLength).contains(sheetId.utf8.count)
            && sheetId.utf8.allSatisfy { isASCIIAlphanumeric($0) || $0 == UInt8(ascii: "-") }
    }

    /// Whether a window asks to be shown as a sheet, whether or not it's a valid one
    static func isSheetRequest(_ url: URL) -> Bool {
        hashParamPairs(url)?.contains { $0.name == osSheetParam } == true
    }

    /// Returns the sheet id if `url` is a window Connect.js opened to show as a native sheet, or nil if it isn't.
    /// The window must be an accessory layer page on the exact scheme, host, and port of `componentURL`.
    static func sheetId(fromWindowURL url: URL, componentURL: URL) -> String? {
        guard url.user == nil,
              url.password == nil,
              let scheme = url.scheme,
              let host = url.host,
              isOrigin(scheme: scheme, host: host, port: url.port, of: componentURL),
              isAccessoryLayerPath(url),
              let params = hashParams(url),
              params[osSheetParam] == "true",
              let sheetId = params[osSheetIdParam],
              isValidSheetId(sheetId) else {
            return nil
        }
        return sheetId
    }

    /// Whether a frame's security origin is exactly the origin of `componentURL`
    static func isOrigin(scheme: String, host: String, port: Int, of componentURL: URL) -> Bool {
        // WebKit reports 0 for a scheme's default port.
        isOrigin(scheme: scheme, host: host, port: port == 0 ? nil : port, of: componentURL)
    }

    private static func isOrigin(scheme: String, host: String, port: Int?, of componentURL: URL) -> Bool {
        scheme.caseInsensitiveCompare(componentURL.scheme ?? "") == .orderedSame
            && host.caseInsensitiveCompare(componentURL.host ?? "") == .orderedSame
            && port == componentURL.port
    }

    // Connect.js serves accessory layers from its origin root, not the SDK page's versioned folder.
    private static func isAccessoryLayerPath(_ url: URL) -> Bool {
        guard let path = URLComponents(url: url, resolvingAgainstBaseURL: false)?.percentEncodedPath,
              path.hasPrefix(accessoryLayerPathPrefix),
              path.hasSuffix(accessoryLayerPathSuffix) else {
            return false
        }
        let hash = path.utf8
            .dropFirst(accessoryLayerPathPrefix.utf8.count)
            .dropLast(accessoryLayerPathSuffix.utf8.count)
        return !hash.isEmpty && hash.allSatisfy(isASCIIAlphanumeric)
    }

    /// Parses a hash formatted like a query string, or returns nil if it's missing or repeats a name
    private static func hashParams(_ url: URL) -> [String: String]? {
        guard let pairs = hashParamPairs(url) else { return nil }
        var params: [String: String] = [:]
        for pair in pairs {
            guard params.updateValue(pair.value, forKey: pair.name) == nil else { return nil }
        }
        return params
    }

    private static func hashParamPairs(_ url: URL) -> [(name: String, value: String)]? {
        guard let fragment = URLComponents(url: url, resolvingAgainstBaseURL: false)?.percentEncodedFragment,
              !fragment.isEmpty else {
            return nil
        }
        var pairs: [(name: String, value: String)] = []
        for pair in fragment.split(separator: "&") {
            let parts = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard let name = decodeHashParam(parts[0]),
                  let value = parts.count > 1 ? decodeHashParam(parts[1]) : "" else {
                return nil
            }
            pairs.append((name: name, value: value))
        }
        return pairs
    }

    private static func decodeHashParam(_ value: Substring) -> String? {
        value.removingPercentEncoding
    }

    private static func isASCIIAlphanumeric(_ byte: UInt8) -> Bool {
        (UInt8(ascii: "a")...UInt8(ascii: "z")).contains(byte)
            || (UInt8(ascii: "A")...UInt8(ascii: "Z")).contains(byte)
            || (UInt8(ascii: "0")...UInt8(ascii: "9")).contains(byte)
    }
}
