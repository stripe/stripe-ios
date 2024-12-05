//
//  TraceSymbolsParser.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2024-10-22.
//

import Foundation

enum TraceSymbolsParser {
    /// Get the current call stack as an `CallStacktrace` array representaion.
    /// Removes the first `callsiteDepth` traces from the stack.
    /// These traces are usually meta traces from classes calling the parser.
    /// i.e. removes `TraceSymbolsParser.current` from the stack trace
    static func current(callsiteDepth: Int = 0) -> [SentryTrace] {
        let callStackSymbols: [String] = Array(Thread.callStackSymbols.dropFirst(callsiteDepth))
        return callStackSymbols.compactMap { symbols in
            Self.parse(symbols: symbols)
        }
    }

    /// Parses a line of `Thread.callStackSymbols` to `CallStackTrace`.
    /// - `symbols`: Input which follows the `DLADDR` format.
    /// ```
    /// // {depth} {fname} {fbase} {sname} + {saddr}
    /// (number with radix 10) (string) (number with radix 16) (string) + (number with radix 10)
    /// ```
    /// This extracts `fname` into the `module`, and `sname` into the `functions.`
    static func parse(symbols: String) -> SentryTrace? {
        // Split the input string by whitespaces and filter out empty components
        let components = symbols.split(whereSeparator: \.isWhitespace).filter { !$0.isEmpty }
        guard components.indices.contains(3) else {
            return nil // Invalid symbol, not enough components.
        }
        // The `module` is the second component
        let module = String(components[1])

        // The `function` is everything from the fourth component up to but not including the "+"
        let functionComponents = components[3...]
        let functionString = functionComponents.joined(separator: " ")

        // Find the index of the "+" symbol in the original string
        guard let plusIndex = functionString.range(of: "+")?.lowerBound else {
            return nil // "+" symbol not found.
        }

        // Extract the final function string from the joined components, trimmed and until the "+"
        let functionEndIndex = symbols.distance(from: symbols.startIndex, to: plusIndex)
        let function = String(functionString.prefix(functionEndIndex)).trimmingCharacters(in: .whitespaces)
        return SentryTrace(module: module, function: function)
    }
}
