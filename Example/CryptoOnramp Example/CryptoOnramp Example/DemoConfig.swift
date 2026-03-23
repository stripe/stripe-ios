import Foundation

enum DemoConfig {

    /// Whether passwordless demo mode is enabled (i.e., a demo password is configured).
    static var isPasswordlessEnabled: Bool {
        guard let password = passwordlessPassword else { return false }
        return !password.isEmpty
    }

    /// The password to use behind the scenes when passwordless mode is enabled.
    static var passwordlessPassword: String? {
        Bundle.main.infoDictionary?["DemoPasswordlessPassword"] as? String
    }

    /// The set of emails allowed in passwordless mode, lowercased.
    static var allowedEmails: Set<String> {
        guard let raw = Bundle.main.infoDictionary?["DemoPasswordlessEmails"] as? String else {
            return []
        }
        let emails = raw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            .filter { !$0.isEmpty }
        return Set(emails)
    }

    /// Returns `true` if the given email is on the passwordless allowlist.
    /// Supports plus-addressing: if `alice@stripe.com` is allowed,
    /// `alice+something@stripe.com` also matches.
    static func isEmailAllowed(_ email: String) -> Bool {
        let normalized = email.lowercased()
        if allowedEmails.contains(normalized) {
            return true
        }
        return allowedEmails.contains(normalizeEmail(normalized))
    }

    /// Strips the `+…` suffix from the local part of an email address.
    /// e.g. `alice+test@stripe.com` → `alice@stripe.com`
    private static func normalizeEmail(_ email: String) -> String {
        guard let atIndex = email.lastIndex(of: "@"),
              let plusIndex = email.firstIndex(of: "+"),
              plusIndex < atIndex
        else {
            return email
        }
        return String(email[email.startIndex..<plusIndex]) + String(email[atIndex...])
    }
}
