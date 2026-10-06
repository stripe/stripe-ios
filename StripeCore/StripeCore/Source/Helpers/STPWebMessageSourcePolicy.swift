//
//  STPWebMessageSourcePolicy.swift
//  StripeCore
//

import Foundation

/// Authorizes WebKit bridge messages from one expected native source and configured HTTPS origins.
///
/// The expected source is held weakly so this policy cannot extend a WebView's lifetime.
/// Configured URLs contribute only their HTTPS scheme, host, and effective port; paths, queries,
/// and fragments are not part of an origin. WebKit reports port `0` for the default HTTPS port,
/// while an explicitly configured port `0` is invalid.
@_spi(STP) public final class STPWebMessageSourcePolicy {
    private struct Origin: Hashable {
        let scheme: String
        let host: String
        let port: Int

        init(scheme: String, host: String, port: Int) {
            self.scheme = scheme
            self.host = host
            self.port = port
        }

        init?(configuredURL: URL) {
            guard let scheme = configuredURL.scheme?.lowercased(),
                  scheme == "https",
                  let host = configuredURL.host?.lowercased(),
                  !host.isEmpty else {
                return nil
            }

            let port = configuredURL.port ?? 443
            guard (1...65_535).contains(port) else {
                return nil
            }

            self.init(scheme: scheme, host: host, port: port)
        }

        init?(reportedScheme: String, host: String, port: Int) {
            let scheme = reportedScheme.lowercased()
            let host = host.lowercased()
            guard scheme == "https",
                  !host.isEmpty,
                  (0...65_535).contains(port) else {
                return nil
            }

            self.init(scheme: scheme, host: host, port: port == 0 ? 443 : port)
        }
    }

    private weak var expectedSource: AnyObject?
    private let allowedOrigins: Set<Origin>

    @_spi(STP) public init(expectedSource: AnyObject, allowedOriginURLs: [URL]) {
        self.expectedSource = expectedSource
        let configuredOrigins = allowedOriginURLs.map(Origin.init(configuredURL:))
        self.allowedOrigins = configuredOrigins.allSatisfy { $0 != nil }
            ? Set(configuredOrigins.compactMap { $0 })
            : []
    }

    @_spi(STP) public func isAuthorized(source: AnyObject?, scheme: String, host: String, port: Int) -> Bool {
        guard let expectedSource,
              let source,
              source === expectedSource,
              let origin = Origin(reportedScheme: scheme, host: host, port: port) else {
            return false
        }
        return allowedOrigins.contains(origin)
    }
}
