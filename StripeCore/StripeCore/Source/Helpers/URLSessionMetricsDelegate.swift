//
//  URLSessionMetricsDelegate.swift
//  StripeCore
//
//  Created to measure network performance metrics
//

import Foundation

/// Network performance metrics for a single request
@_spi(STP) public struct NetworkMetrics {
    public let url: String
    public let totalTime: TimeInterval
    public let dnsLookupTime: TimeInterval?
    public let connectionTime: TimeInterval?
    public let tlsHandshakeTime: TimeInterval?
    public let requestTime: TimeInterval?
    public let serverProcessingTime: TimeInterval?
    public let responseDownloadTime: TimeInterval?
    public let isConnectionReused: Bool
    public let networkProtocol: String?

    /// Convert to analytics payload
    public func analyticsPayload(prefix: String = "") -> [String: Any] {
        var payload: [String: Any] = [:]

        // Convert all times to milliseconds and round to whole numbers
        payload["\(prefix)total_time_ms"] = Int(totalTime * 1000)
        if let dnsTime = dnsLookupTime {
            payload["\(prefix)dns_time_ms"] = Int(dnsTime * 1000)
        }
        if let connTime = connectionTime {
            payload["\(prefix)connection_time_ms"] = Int(connTime * 1000)
        }
        if let tlsTime = tlsHandshakeTime {
            payload["\(prefix)tls_time_ms"] = Int(tlsTime * 1000)
        }
        if let serverTime = serverProcessingTime {
            payload["\(prefix)server_time_ms"] = Int(serverTime * 1000)
        }

        payload["\(prefix)connection_reused"] = isConnectionReused
        payload["\(prefix)protocol"] = networkProtocol

        return payload
    }
}

/// A delegate that captures detailed network timing metrics for debugging performance issues
@_spi(STP) public class URLSessionMetricsDelegate: NSObject, URLSessionTaskDelegate {

    /// Callback for when metrics are collected
    public var metricsHandler: ((NetworkMetrics) -> Void)?

    /// Storage for the most recent metrics (for Elements/Sessions call)
    @_spi(STP) public private(set) var lastElementsSessionMetrics: NetworkMetrics?

    public override init() {
        super.init()
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        let structuredMetrics = extractMetrics(from: metrics)

        // Store if this is an Elements/Sessions call
        if let url = task.currentRequest?.url?.absoluteString,
           url.contains("/v1/elements/sessions") {
            lastElementsSessionMetrics = structuredMetrics
        }

        // Call handler if set
        if let structuredMetrics = structuredMetrics {
            metricsHandler?(structuredMetrics)
        }
    }

    private func extractMetrics(from metrics: URLSessionTaskMetrics) -> NetworkMetrics? {
        guard let transactionMetrics = metrics.transactionMetrics.first,
              let fetchStart = transactionMetrics.fetchStartDate,
              let responseEnd = transactionMetrics.responseEndDate else {
            return nil
        }

        let totalTime = responseEnd.timeIntervalSince(fetchStart)

        // DNS lookup time
        let dnsLookupTime: TimeInterval? = {
            guard let start = transactionMetrics.domainLookupStartDate,
                  let end = transactionMetrics.domainLookupEndDate else {
                return nil
            }
            return end.timeIntervalSince(start)
        }()

        // Connection time (total)
        let connectionTime: TimeInterval? = {
            guard let start = transactionMetrics.connectStartDate,
                  let end = transactionMetrics.connectEndDate else {
                return nil
            }
            return end.timeIntervalSince(start)
        }()

        // TLS handshake time
        let tlsHandshakeTime: TimeInterval? = {
            guard let start = transactionMetrics.secureConnectionStartDate,
                  let end = transactionMetrics.connectEndDate else {
                return nil
            }
            return end.timeIntervalSince(start)
        }()

        // Request time
        let requestTime: TimeInterval? = {
            guard let start = transactionMetrics.requestStartDate,
                  let end = transactionMetrics.requestEndDate else {
                return nil
            }
            return end.timeIntervalSince(start)
        }()

        // Server processing time (TTFB)
        let serverProcessingTime: TimeInterval? = {
            guard let requestEnd = transactionMetrics.requestEndDate,
                  let responseStart = transactionMetrics.responseStartDate else {
                return nil
            }
            return responseStart.timeIntervalSince(requestEnd)
        }()

        // Response download time
        let responseDownloadTime: TimeInterval? = {
            guard let start = transactionMetrics.responseStartDate else {
                return nil
            }
            return responseEnd.timeIntervalSince(start)
        }()

        return NetworkMetrics(
            url: metrics.transactionMetrics.first?.request.url?.absoluteString ?? "unknown",
            totalTime: totalTime,
            dnsLookupTime: dnsLookupTime,
            connectionTime: connectionTime,
            tlsHandshakeTime: tlsHandshakeTime,
            requestTime: requestTime,
            serverProcessingTime: serverProcessingTime,
            responseDownloadTime: responseDownloadTime,
            isConnectionReused: transactionMetrics.isReusedConnection,
            networkProtocol: transactionMetrics.networkProtocolName
        )
    }
}
