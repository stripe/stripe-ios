//
//  ExampleLinkStandaloneComponent.swift
//  PaymentSheet Example
//
//  Created by Till Hellmund on 6/19/25.
//

import MapKit
@_spi(STP) import StripePaymentSheet
import SwiftUI

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
            // Top half - Map
            Map(coordinateRegion: $region)
                .frame(height: UIScreen.main.bounds.height * 0.5)

            // Bottom half - Car options and payment
            VStack(spacing: 0) {
                // Car options - takes up space as needed
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
                }

                Spacer()

                // Fixed footer - always visible
                VStack(spacing: 16) {
                    // Payment method row
                    Button(action: {
                        showingPaymentSheet = true
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Payment method")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if let paymentOption = paymentOption {
                                    Text(paymentOption.labels.sublabel ?? paymentOption.label)
                                        .font(.headline)
                                        .foregroundColor(.primary)
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
                }
                .padding()
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
            }
            .background(Color(.systemBackground))
        }
        .sheet(isPresented: $showingPaymentSheet) {
            PaymentMethodSheet()
                .presentationDetents([.medium])
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }

    private func presentLink() {
        guard let viewController = findViewController() else {
            return
        }

        STPAPIClient.shared.publishableKey = "pk_test_51HvTI7Lu5o3P18Zp6t5AgBSkMvWoTtA0nyA7pVYDqpfLkRtWun7qZTYCOHCReprfLM464yaBeF72UFfB7cY9WG4a00ZnDtiC2C"

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

    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                Text("Payment method")
                    .font(.title2)
                    .fontWeight(.medium)
                Spacer()
            }
            .navigationTitle("Payment")
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
