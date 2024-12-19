//
//  SentryStacktrace.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2024-10-22.
//

import Foundation

/// https://develop.sentry.dev/sdk/data-model/event-payloads/stacktrace/
struct SentryTrace: Encodable, Equatable {
    let module: String?
    let file: String?
    let function: String
    let lineno: Int?

    init(module: String? = nil, file: String? = nil, function: String, lineno: Int? = nil) {
        self.module = module
        self.file = file
        self.function = function
        self.lineno = lineno
    }

    enum CodingKeys: CodingKey {
        case module
        case file
        case function
        case lineno
    }

    // Custom encoder to only encode non-nil properties.
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.module, forKey: .module)
        try container.encodeIfPresent(self.file, forKey: .file)
        try container.encode(self.function, forKey: .function)
        try container.encodeIfPresent(self.lineno, forKey: .lineno)
    }
}

struct SentryStacktrace: Encodable {
    let frames: [SentryTrace]

    static func capture(
        filePath: String = #file,
        function: String = #function,
        line: Int = #line,
        callsiteDepth: Int = 1
    ) -> [SentryTrace] {
        var traces: [SentryTrace] = []
        if let file = filePath.components(separatedBy: "/").last {
            // Start with a Root trace, which includes the file, function, and lineno.
            traces.append(SentryTrace(
                file: file,
                function: function,
                lineno: line
            ))
        }

        // Add all other traces by adding 1 to the callsite depth. This removes the meta call
        // to `SentryStacktrace.capture` from the stacktrace.
        let callStackTrace = TraceSymbolsParser.current(callsiteDepth: callsiteDepth + 1)
        traces.append(contentsOf: callStackTrace)
        return traces
    }
}
