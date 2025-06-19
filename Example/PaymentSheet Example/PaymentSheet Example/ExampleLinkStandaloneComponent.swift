//
//  ExampleLinkStandaloneComponent.swift
//  PaymentSheet Example
//
//  Created by Till Hellmund on 6/19/25.
//

import MapKit
import SwiftUI

@_spi(STP) import StripePaymentSheet
@_spi(STP) import StripeUICore

@available(iOS 16.0, *)
struct ExampleLinkStandaloneComponent: View {
    @State private var selectedCarType: CarType = CarType.bolt
    @State private var hasPresentedLink = false
    @State private var paymentOption: PaymentSheet.FlowController.PaymentOptionDisplayData?
    @State private var showingPaymentSheet = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    @StateObject private var linkController = LinkController.create()

    // Map region centered on San Francisco
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        VStack(spacing: 0) {
            // Map view - takes remaining space above car options
            Map(coordinateRegion: $region)
                .ignoresSafeArea(.container, edges: .top)

            // Car options section
            VStack(alignment: .leading, spacing: 16) {
                Text("Choose your ride")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    .padding(.top)

                VStack(spacing: 12) {
                    ForEach(CarType.allCases, id: \.self) { carType in
                        CarOptionRow(
                            carType: carType,
                            isSelected: selectedCarType == carType,
                            action: { selectedCarType = carType }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(Color(.systemBackground))

            // Fixed footer - always visible at bottom
            VStack(spacing: 16) {
                // Payment method row
                Button(action: {
                    if linkController.paymentOption != nil {
                        presentLink()
                    } else {
                        showingPaymentSheet = true
                    }
                }) {
                    HStack(spacing: 20) {
                        if let paymentOption = linkController.paymentOption {
                            Image(uiImage: paymentOption.image)
                                .frame(width: 40, height: 40)
                        } else {
                            Image(systemName: "creditcard")
                                .foregroundColor(.gray)
                                .font(.title2)
                                .frame(width: 32, height: 32)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            if let paymentOption = linkController.paymentOption {
                                Text(paymentOption.labels.label)
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                if let sublabel = paymentOption.labels.sublabel {
                                    Text(sublabel)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("Choose payment method")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())

                // Confirm order button
                Button(action: {
                    linkController.createPaymentMethod { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let paymentMethod):
                                alertTitle = "Success"
                                alertMessage = paymentMethod.stripeId
                                showingAlert = true
                            case .failure(let error):
                                alertTitle = "Error"
                                alertMessage = error.localizedDescription
                                showingAlert = true
                            }
                        }
                    }
                }) {
                    HStack {
                        Text("Confirm order")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text(String(format: "$%.2f", selectedCarType.price))
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.black)
                    .cornerRadius(25)
                }
                .disabled(linkController.paymentOption == nil)
            }
            .padding()
            .background(Color(.systemBackground))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
        }
        .sheet(isPresented: $showingPaymentSheet) {
            PaymentMethodSheet(linkController: linkController)
                .presentationDetents([.fraction(0.35)])
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            STPAPIClient.shared.publishableKey = "pk_test_51HvTI7Lu5o3P18Zp6t5AgBSkMvWoTtA0nyA7pVYDqpfLkRtWun7qZTYCOHCReprfLM464yaBeF72UFfB7cY9WG4a00ZnDtiC2C"

            linkController.lookupConsumer(with: "email@email.com") {
                print("Existing Link consumer? \(linkController.isExistingLinkConsumer)")
            }
        }
    }

    private func presentLink() {
        guard let viewController = findViewController() else {
            return
        }

        linkController.present(from: viewController, with: "email@email.com") {
            self.paymentOption = linkController.paymentOption
        }
    }
}

// MARK: - Supporting Views
@available(iOS 16.0, *)
struct CarOptionRow: View {
    let carType: CarType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: carType.iconName)
                    .foregroundColor(carType.iconColor)
                    .font(.title)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(carType.displayName)
                        .font(.headline)
                        .fontWeight(.medium)
                    Text(carType.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "$%.2f", carType.price))
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text(carType.eta)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }
            .padding()
            .background(isSelected ? Color(.systemBlue).opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
@available(iOS 16.0, *)
struct PaymentMethodSheet: View {
    @Environment(\.dismiss) private var dismiss
    var linkController: LinkController

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Payment options list
                VStack(spacing: 0) {
                    // Add credit card row (non-interactive)
                    HStack(spacing: 16) {
                        Image(systemName: "creditcard")
                            .foregroundColor(.gray)
                            .font(.title2)
                            .frame(width: 32, height: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Add credit card")
                                .font(.headline)
                                .fontWeight(.medium)
                            Text("Visa, Mastercard, Amex")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top)

                    // Pay with Link row (interactive)
                    Button(action: presentLink) {
                        HStack(spacing: 16) {
                            Image(uiImage: Image.link_icon.makeImage())
                                .frame(width: 40, height: 40)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Pay with Link")
                                    .font(.headline)
                                    .fontWeight(.medium)

                                if linkController.isExistingLinkConsumer {
                                    Text("Log in as email@email.com")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    .padding(.top, 12)

                    Spacer()
                }
            }
            .navigationTitle("Add payment method")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func presentLink() {
        guard let viewController = findViewController() else {
            return
        }

        STPAPIClient.shared.publishableKey = "pk_test_51HvTI7Lu5o3P18Zp6t5AgBSkMvWoTtA0nyA7pVYDqpfLkRtWun7qZTYCOHCReprfLM464yaBeF72UFfB7cY9WG4a00ZnDtiC2C"

        linkController.present(from: viewController, with: "email@email.com") {
            DispatchQueue.main.async {
                dismiss()
            }
        }
    }
}

// MARK: - Supporting Types

enum CarType: CaseIterable {
    case bolt
    case comfort
    case van

    var displayName: String {
        switch self {
        case .bolt:
            return "Bolt"
        case .comfort:
            return "Comfort"
        case .van:
            return "Van"
        }
    }

    var description: String {
        switch self {
        case .bolt:
            return "Affordable ride"
        case .comfort:
            return "Extra legroom"
        case .van:
            return "Seats 6 passengers"
        }
    }

    var price: Double {
        switch self {
        case .bolt:
            return 12.50
        case .comfort:
            return 18.75
        case .van:
            return 25.00
        }
    }

    var eta: String {
        switch self {
        case .bolt:
            return "2 min"
        case .comfort:
            return "4 min"
        case .van:
            return "6 min"
        }
    }

    var iconName: String {
        switch self {
        case .bolt:
            return "car.fill"
        case .comfort:
            return "car.circle.fill"
        case .van:
            return "bus.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .bolt:
            return .blue
        case .comfort:
            return .green
        case .van:
            return .orange
        }
    }
}

private func findViewController() -> UIViewController? {
    let keyWindow = UIApplication.shared.windows.filter { $0.isKeyWindow }.first
    var topController = keyWindow?.rootViewController
    while let presentedViewController = topController?.presentedViewController {
        topController = presentedViewController
    }
    return topController
}

struct ExampleLinkStandaloneComponent_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 16.0, *) {
            ExampleLinkStandaloneComponent()
        } else {
            // Fallback on earlier versions
        }
    }
}
