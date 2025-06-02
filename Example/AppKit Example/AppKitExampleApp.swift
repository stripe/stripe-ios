//
//  AppKitExampleApp.swift
//  AppKit Example
//
//  Created by Stripe SDK for macOS AppKit support.
//  Copyright © 2024 Stripe, Inc. All rights reserved.
//

import AppKit
import StripePaymentSheet
@_spi(STP) import StripeUICore

@main
class AppKitExampleApp: NSApplication {

    override func finishLaunching() {
        super.finishLaunching()

        // Create main window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "Stripe AppKit Example"
        window.center()

        // Create main view controller
        let mainViewController = MainViewController()
        window.contentViewController = mainViewController

        window.makeKeyAndOrderFront(nil)
    }
}

class MainViewController: NSViewController {

    private var paymentSheet: PaymentSheet?

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false

        // Title label
        let titleLabel = NSTextField(labelWithString: "Stripe AppKit Example")
        titleLabel.font = NSFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.alignment = .center

        // Description label
        let descriptionLabel = NSTextField(labelWithString: "This example demonstrates how to use Stripe SDK in a native macOS AppKit application.")
        descriptionLabel.font = NSFont.systemFont(ofSize: 14)
        descriptionLabel.alignment = .center
        descriptionLabel.maximumNumberOfLines = 0
        descriptionLabel.lineBreakMode = .byWordWrapping

        // Payment button
        let paymentButton = NSButton(title: "Start Payment", target: self, action: #selector(startPayment))
        paymentButton.bezelStyle = .rounded
        paymentButton.controlSize = .large

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(descriptionLabel)
        stackView.addArrangedSubview(paymentButton)

        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.widthAnchor.constraint(lessThanOrEqualToConstant: 400),
            descriptionLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
    }

    @objc private func startPayment() {
        // Example payment configuration
        // In a real app, you would get this from your backend
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "AppKit Example"

        // Create PaymentSheet
        // Note: In a real implementation, you would need to:
        // 1. Create a PaymentIntent on your backend
        // 2. Get the client secret
        // 3. Pass it to PaymentSheet

        let alert = NSAlert()
        alert.messageText = "Payment Integration"
        alert.informativeText = "In a real app, you would integrate with your backend to create a PaymentIntent and present the payment sheet."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
