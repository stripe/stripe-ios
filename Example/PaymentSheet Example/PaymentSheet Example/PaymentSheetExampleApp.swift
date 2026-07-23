//
//  PaymentSheetExampleApp.swift
//  PaymentSheet Example
//

import StripePaymentSheet
import SwiftUI
import UIKit

@main
struct PaymentSheetExampleApp: App {
    var body: some Scene {
        WindowGroup {
            EmbeddedPaymentElementMultiSceneProbeView()
                .onOpenURL { url in
                    _ = StripeAPI.handleURLCallback(with: url)
                }
        }
    }
}

struct EmbeddedPaymentElementMultiSceneProbeView: View {
    @State private var sceneID = "unknown"
    @State private var connectedSceneCount = UIApplication.shared.connectedScenes.count
    @State private var sceneRequestError: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Scene \(sceneID)")
                        Spacer()
                        Text("\(connectedSceneCount) connected")
                    }
                    .font(.caption)
                    .monospacedDigit()

                    if let sceneRequestError {
                        Text(sceneRequestError)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(UIColor.secondarySystemBackground))
                .background(
                    WindowSceneIDReader { sceneID in
                        self.sceneID = String(sceneID.prefix(8)).uppercased()
                        refreshConnectedSceneCount()
                    }
                )

                MyEmbeddedCheckoutView()
            }
            .navigationBarTitle("EPE SwiftUI", displayMode: .inline)
            .navigationBarItems(
                trailing: Button(action: openAdditionalScene) {
                    Image(systemName: "plus.square.on.square")
                }
                .accessibilityLabel("Open another window")
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            refreshConnectedSceneCount()
        }
    }

    private func openAdditionalScene() {
        sceneRequestError = nil

        guard UIApplication.shared.supportsMultipleScenes else {
            sceneRequestError = "Multiple scenes are unavailable on this device."
            return
        }

        let activity = NSUserActivity(activityType: "com.stripe.paymentsheet.example.epe-multi-scene")
        activity.title = "EPE SwiftUI"

        UIApplication.shared.requestSceneSessionActivation(
            nil,
            userActivity: activity,
            options: nil
        ) { error in
            DispatchQueue.main.async {
                sceneRequestError = error.localizedDescription
                refreshConnectedSceneCount()
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            refreshConnectedSceneCount()
        }
    }

    private func refreshConnectedSceneCount() {
        connectedSceneCount = UIApplication.shared.connectedScenes.count
    }
}

private struct WindowSceneIDReader: UIViewRepresentable {
    let onSceneIDChange: (String) -> Void

    func makeUIView(context: Context) -> WindowSceneIDReportingView {
        let view = WindowSceneIDReportingView()
        view.onSceneIDChange = onSceneIDChange
        return view
    }

    func updateUIView(_ uiView: WindowSceneIDReportingView, context: Context) {
        uiView.onSceneIDChange = onSceneIDChange
        uiView.reportSceneID()
    }
}

private final class WindowSceneIDReportingView: UIView {
    var onSceneIDChange: ((String) -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        reportSceneID()
    }

    func reportSceneID() {
        guard let sceneID = window?.windowScene?.session.persistentIdentifier else {
            return
        }

        DispatchQueue.main.async { [onSceneIDChange] in
            onSceneIDChange?(sceneID)
        }
    }
}
