//
//  LinkPayoutsDemoView.swift
//  PaymentSheet Example
//

import AuthenticationServices
import SwiftUI

@available(iOS 15.0, *)
struct LinkPayoutsDemoView: View {
    @State private var callbackURL: URL?
    @State private var errorMessage: String?
    @State private var isLoading = false

    private let onboardingURL = URL(
        string: "http://qa-onboarding.link.com/onboard?publishable_key=123&client_secret=1234&platform=ios&test_result=success"
    )!
    private let callbackScheme = "stripe-auth"

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Link Payouts Demo")
                .font(.title)
                .fontWeight(.bold)

            Button {
                launchFlow()
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Launch flow")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .disabled(isLoading)
            .padding(.horizontal, 32)

            if let callbackURL = callbackURL {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Callback URL received:")
                        .font(.headline)

                    Text(callbackURL.absoluteString)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding(.horizontal, 32)
            }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.body)
                    .foregroundColor(.red)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
        .navigationTitle("Link Payouts")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func launchFlow() {
        callbackURL = nil
        errorMessage = nil
        isLoading = true

        let session = ASWebAuthenticationSession(
            url: onboardingURL,
            callbackURLScheme: callbackScheme
        ) { url, error in
            isLoading = false

            if let error = error as? ASWebAuthenticationSessionError,
               error.code == .canceledLogin {
                errorMessage = "Flow was cancelled"
                return
            }

            if let error = error {
                errorMessage = "Error: \(error.localizedDescription)"
                return
            }

            if let url = url {
                callbackURL = url
            }
        }

        session.prefersEphemeralWebBrowserSession = true
        session.presentationContextProvider = WebAuthPresentationContextProvider.shared

        session.start()
    }
}

private class WebAuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = WebAuthPresentationContextProvider()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        return keyWindow ?? ASPresentationAnchor()
    }
}

@available(iOS 15.0, *)
struct LinkPayoutsDemoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LinkPayoutsDemoView()
        }
    }
}
