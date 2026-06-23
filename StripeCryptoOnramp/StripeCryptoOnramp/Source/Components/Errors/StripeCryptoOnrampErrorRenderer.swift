//
//  StripeCryptoOnrampErrorRenderer.swift
//  StripeCryptoOnramp
//

import Foundation

/// Renders rich Crypto Onramp developer diagnostics with a consistent visual grammar.
enum StripeCryptoOnrampErrorRenderer {

    /// Renders a developer-facing message from concrete-error content and shared metadata.
    ///
    /// - Parameters:
    ///   - developerBody: The main diagnostic content owned by the concrete error.
    ///   - code: A stable code identifying this error.
    ///   - nextStep: A suggested action for resolving the error.
    ///   - docURL: Documentation for this error, if available.
    ///   - sdkVersions: SDK versions included in developer diagnostics, including Stripe iOS and any additional wrapper SDK versions.
    ///   - diagnosticContext: Local SDK context included in developer diagnostics.
    static func render(
        developerBody: String,
        code: String,
        nextStep: String,
        docURL: URL?,
        sdkVersions: [SDKVersion] = [],
        diagnosticContext: DiagnosticContext? = nil
    ) -> String {
        let renderedDeveloperBody: String
        if let diagnosticContext {
            renderedDeveloperBody = developerBodyWithContext(
                summary: developerBody,
                contextTitle: "Request Context:",
                contextLines: diagnosticContextLines(diagnosticContext)
            )
        } else {
            renderedDeveloperBody = developerBody
        }

        return render(
            developerBody: renderedDeveloperBody,
            code: code,
            nextStep: nextStep,
            docURLString: docURL?.absoluteString,
            sdkVersions: diagnosticContext?.sdkVersions ?? sdkVersions
        )
    }

    static func renderAPIErrorDeveloperMessage(
        context: APIErrorContext,
        diagnosticContext: DiagnosticContext,
        summary: String,
        code: String,
        nextStep: String
    ) -> String {
        return render(
            developerBody: developerBodyWithContext(
                summary: summary,
                contextTitle: "Request Context:",
                contextLines: requestContextLines(context, diagnosticContext: diagnosticContext)
            ),
            code: code,
            nextStep: nextStep,
            docURL: context.docURL,
            sdkVersions: diagnosticContext.sdkVersions
        )
    }

    private static func render(
        developerBody: String,
        code: String,
        nextStep: String,
        docURLString: String?,
        sdkVersions: [SDKVersion]
    ) -> String {
        var lines = [
            developerBody,
            "",
            "Code: \(code)",
            "Next step: \(nextStep)",
        ]

        if let docURLString {
            lines.append("Docs: \(docURLString)")
        }

        lines.append("SDK: \(sdkVersionDescription(sdkVersions: sdkVersions))")

        return lines.joined(separator: "\n")
    }

    private static func sdkVersionDescription(sdkVersions: [SDKVersion]) -> String {
        let normalizedSDKVersions = sdkVersions.isEmpty ? [.stripeIOS] : sdkVersions
        return normalizedSDKVersions.map(\.debugDescription).joined(separator: ", ")
    }

    private static func developerBodyWithContext(
        summary: String,
        contextTitle: String,
        contextLines: [String]
    ) -> String {
        guard !contextLines.isEmpty else {
            return summary
        }

        return ([
            summary,
            "",
            contextTitle,
        ] + contextLines.map { "  \($0)" }).joined(separator: "\n")
    }

    private static func diagnosticContextLines(_ diagnosticContext: DiagnosticContext) -> [String] {
        return [
            "operation: \(diagnosticContext.operation)",
            diagnosticContext.appPackageName.map { "app_id: \($0)" },
            diagnosticContext.mode.map { "mode: \($0)" },
        ].compactMap { $0 }
    }

    private static func requestContextLines(_ context: APIErrorContext, diagnosticContext: DiagnosticContext) -> [String] {
        return diagnosticContextLines(diagnosticContext) + [
            context.reason.map { "reason: \($0)" },
            context.requestID.map { "request_id: \($0)" },
            context.apiErrorType.map { "type: \($0)" },
        ].compactMap { $0 }
    }
}
