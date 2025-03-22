//
//  ToastManager.swift
//  StripeConnect Example
//
//  Created by Chris Mays on 3/20/25.
//

import SwiftUI
import UIKit

struct ToastMessage: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let createdAt = Date()
}

class ToastManager: ObservableObject {
    static let shared = ToastManager()
    @Published var toasts: [ToastMessage] = []
    private let displayDuration: TimeInterval = 20.0
    private var toastWindow: UIWindow?

    private func setupWindowIfNeeded() {
        guard toastWindow == nil else { return }

        let window = UIWindow()
        window.backgroundColor = .clear
        window.windowLevel = .alert + 1
        window.isUserInteractionEnabled = false
        window.accessibilityIdentifier = "ToastWindow"
        if let windowScene = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .first as? UIWindowScene {
            window.windowScene = windowScene
        }

        let rootVC = UIHostingController(
            rootView: ToastContainerView().environmentObject(self)
        )
        rootVC.view.backgroundColor = .clear
        window.rootViewController = rootVC
        rootVC.view.isAccessibilityElement = true
        window.isHidden = false
        toastWindow = window
    }

    func show(_ message: String) {
        setupWindowIfNeeded()
        let toast = ToastMessage(message: message)

        DispatchQueue.main.async {
            self.toasts.append(toast)
            DispatchQueue.main.asyncAfter(deadline: .now() + self.displayDuration) {
                self.removeToast(toast)
            }
        }
    }

    private func removeToast(_ toast: ToastMessage) {
        DispatchQueue.main.async {
            withAnimation {
                if let index = self.toasts.firstIndex(of: toast) {
                    self.toasts.remove(at: index)
                }
            }
        }
    }
}

struct ToastContainerView: View {
    @EnvironmentObject var toastManager: ToastManager

    var body: some View {
        VStack {
            Spacer()

            ForEach(toastManager.toasts) { toast in
                Text(toast.message)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.7))
                    )
                    .accessibilityIdentifier(toast.message)
                    .foregroundColor(.white)
                    .font(.system(size: 14))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            .padding(.bottom, 16)
        }
        .animation(.easeInOut, value: toastManager.toasts)
    }
}
