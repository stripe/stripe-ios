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

class ExampleLinkStandaloneComponentViewModel: ObservableObject {
    @Published var linkController: LinkController?
    @Published var error: String?
}

@available(iOS 16.0, *)
struct ExampleLinkStandaloneComponent: View {

    @ObservedObject var model = ExampleLinkStandaloneComponentViewModel()

    var body: some View {
        Group {
            if let linkController = model.linkController {
                ExampleLinkStandaloneComponentContent(linkController: linkController)
            } else if let error = model.error {
                Text(error)
            } else {
                ExampleLoadingView()
            }
        }
        .onAppear {
            STPAPIClient.shared.publishableKey = "pk_test_51Rtc1uHi8weFL2MI0Bk69MoHZv5Dr1uBAjM23ZuvZdbSfZ9hb8BtoyRTsdVwZGtm6XPuMyNdAXp9Kqf3oGGHQzws00ro5dRhat"

            Task {
                do {
                    let controller = try await LinkController.create(mode: .payment)
                    model.linkController = controller
                } catch {
                    model.error = error.localizedDescription
                }
            }
        }
    }
}

@available(iOS 16.0, *)
struct ExampleLinkStandaloneComponentContent: View {
    private let email: String = "email@email.com"

    @State private var selectedCarType: CarType = CarType.basic
    @State private var hasPresentedLink = false
    @State private var paymentMethodPreview: LinkController.PaymentMethodPreview?
    @State private var showingPaymentSheet = false
    @State private var showingCreditCardForm = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    @StateObject var linkController: LinkController

    // Map region centered on San Francisco
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7845, longitude: -122.4263),
        span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
    )

    var body: some View {
        VStack(spacing: 0) {
            // Map view with route - takes remaining space above car options
            RouteMapView(region: $region)
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
                    if linkController.paymentMethodPreview != nil {
                        presentLink()
                    } else {
                        showingPaymentSheet = true
                    }
                }) {
                    HStack(spacing: 20) {
                        if let paymentMethodPreview = linkController.paymentMethodPreview {
                            Image(uiImage: paymentMethodPreview.icon)
                                .resizable()
                                .frame(width: 28, height: 28)
                        } else {
                            Image(systemName: "creditcard")
                                .foregroundColor(.gray)
                                .font(.title2)
                                .frame(width: 32, height: 32)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            if let paymentMethodPreview = linkController.paymentMethodPreview {
                                Text(paymentMethodPreview.label)
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                if let sublabel = paymentMethodPreview.sublabel {
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
                Button {
                    Task {
                        do {
                            let paymentMethod = try await linkController.createPaymentMethod()
                            alertTitle = "Success"
                            alertMessage = "Created \(paymentMethod.stripeId)"
                            showingAlert = true
                        } catch {
                            alertTitle = "Error"
                            alertMessage = error.localizedDescription
                            showingAlert = true
                        }
                    }
                } label: {
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
                .opacity(linkController.paymentMethodPreview == nil ? 0.8 : 1)
                .disabled(linkController.paymentMethodPreview == nil)
            }
            .padding()
            .background(Color(.systemBackground))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
        }
        .sheet(isPresented: $showingPaymentSheet) {
            PaymentMethodSheet(
                email: email,
                linkController: linkController,
                onCreditCardTap: { showingCreditCardForm = true }
            )
            .presentationDetents([.large])
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            Task {
                do {
                    let isExistingLinkConsumer = try await linkController.lookupConsumer(with: email)
                    print("Existing Link consumer? \(isExistingLinkConsumer)")
                } catch {
                    print("Failed to lookup Link consumer: \(error.localizedDescription)")
                }
            }
        }
    }

    private func presentLink() {
        guard let viewController = findViewController() else {
            return
        }

        Task {
            let paymentMethodPreview = await linkController.collectPaymentMethod(from: viewController, with: email)
            self.paymentMethodPreview = paymentMethodPreview
        }
    }
}

// MARK: - Route Map View
@available(iOS 16.0, *)
struct RouteMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.setRegion(region, animated: false)

        // Add route overlay using GPX coordinates
        let routeCoordinates = createRouteFromGPX()
        let polyline = MKPolyline(coordinates: routeCoordinates, count: routeCoordinates.count)
        mapView.addOverlay(polyline)

        // Add start and end markers
        let startAnnotation = MKPointAnnotation()
        startAnnotation.coordinate = routeCoordinates.first!
        startAnnotation.title = "Pickup"
        mapView.addAnnotation(startAnnotation)

        let endAnnotation = MKPointAnnotation()
        endAnnotation.coordinate = routeCoordinates.last!
        endAnnotation.title = "Destination"
        mapView.addAnnotation(endAnnotation)

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func createRouteFromGPX() -> [CLLocationCoordinate2D] {
        // GPX coordinates from the provided file (1.88 km route in San Francisco)
        return [
            CLLocationCoordinate2D(latitude: 37.77796, longitude: -122.42981),
            CLLocationCoordinate2D(latitude: 37.77827, longitude: -122.42987),
            CLLocationCoordinate2D(latitude: 37.77851, longitude: -122.42992),
            CLLocationCoordinate2D(latitude: 37.77878, longitude: -122.42998),
            CLLocationCoordinate2D(latitude: 37.77886, longitude: -122.43),
            CLLocationCoordinate2D(latitude: 37.77894, longitude: -122.43001),
            CLLocationCoordinate2D(latitude: 37.77948, longitude: -122.43012),
            CLLocationCoordinate2D(latitude: 37.77979, longitude: -122.43018),
            CLLocationCoordinate2D(latitude: 37.7798, longitude: -122.43012),
            CLLocationCoordinate2D(latitude: 37.77985, longitude: -122.42974),
            CLLocationCoordinate2D(latitude: 37.77988, longitude: -122.42954),
            CLLocationCoordinate2D(latitude: 37.77991, longitude: -122.42931),
            CLLocationCoordinate2D(latitude: 37.77993, longitude: -122.42914),
            CLLocationCoordinate2D(latitude: 37.77997, longitude: -122.42876),
            CLLocationCoordinate2D(latitude: 37.77999, longitude: -122.42862),
            CLLocationCoordinate2D(latitude: 37.78001, longitude: -122.42844),
            CLLocationCoordinate2D(latitude: 37.78008, longitude: -122.42791),
            CLLocationCoordinate2D(latitude: 37.78009, longitude: -122.42785),
            CLLocationCoordinate2D(latitude: 37.7801, longitude: -122.42772),
            CLLocationCoordinate2D(latitude: 37.78018, longitude: -122.42715),
            CLLocationCoordinate2D(latitude: 37.78019, longitude: -122.42704),
            CLLocationCoordinate2D(latitude: 37.7802, longitude: -122.42696),
            CLLocationCoordinate2D(latitude: 37.78025, longitude: -122.42659),
            CLLocationCoordinate2D(latitude: 37.78028, longitude: -122.42634),
            CLLocationCoordinate2D(latitude: 37.7804, longitude: -122.42538),
            CLLocationCoordinate2D(latitude: 37.78041, longitude: -122.42531),
            CLLocationCoordinate2D(latitude: 37.78056, longitude: -122.42418),
            CLLocationCoordinate2D(latitude: 37.78061, longitude: -122.42375),
            CLLocationCoordinate2D(latitude: 37.78068, longitude: -122.42318),
            CLLocationCoordinate2D(latitude: 37.78074, longitude: -122.42274),
            CLLocationCoordinate2D(latitude: 37.78082, longitude: -122.42211),
            CLLocationCoordinate2D(latitude: 37.78094, longitude: -122.42115),
            CLLocationCoordinate2D(latitude: 37.781, longitude: -122.42066),
            CLLocationCoordinate2D(latitude: 37.78101, longitude: -122.42059),
            CLLocationCoordinate2D(latitude: 37.78102, longitude: -122.42051),
            CLLocationCoordinate2D(latitude: 37.78104, longitude: -122.42036),
            CLLocationCoordinate2D(latitude: 37.78105, longitude: -122.42028),
            CLLocationCoordinate2D(latitude: 37.78124, longitude: -122.41882),
            CLLocationCoordinate2D(latitude: 37.78125, longitude: -122.41872),
            CLLocationCoordinate2D(latitude: 37.78133, longitude: -122.4181),
            CLLocationCoordinate2D(latitude: 37.78145, longitude: -122.41718),
            CLLocationCoordinate2D(latitude: 37.78154, longitude: -122.4172),
            CLLocationCoordinate2D(latitude: 37.78238, longitude: -122.41736),
            CLLocationCoordinate2D(latitude: 37.78331, longitude: -122.41755),
            CLLocationCoordinate2D(latitude: 37.78378, longitude: -122.41765),
            CLLocationCoordinate2D(latitude: 37.78388, longitude: -122.41767),
            CLLocationCoordinate2D(latitude: 37.78424, longitude: -122.41774),
            CLLocationCoordinate2D(latitude: 37.78471, longitude: -122.41783),
            CLLocationCoordinate2D(latitude: 37.78518, longitude: -122.41793),
            CLLocationCoordinate2D(latitude: 37.78531, longitude: -122.41685),
        ]
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: RouteMapView

        init(_ parent: RouteMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.systemBlue
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let identifier = "RouteAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }

            if annotation.title == "Pickup" {
                annotationView?.image = UIImage(systemName: "mappin.circle.fill")?.withTintColor(.systemGreen, renderingMode: .alwaysOriginal)
            } else if annotation.title == "Destination" {
                annotationView?.image = UIImage(systemName: "mappin.circle.fill")?.withTintColor(.systemRed, renderingMode: .alwaysOriginal)
            }

            return annotationView
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
    let email: String
    var linkController: LinkController
    var onCreditCardTap: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Payment options list
                VStack(spacing: 0) {
                    // Add credit card row (interactive)
                    NavigationLink(destination: CreditCardFormView(linkController: linkController)) {
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
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    .padding(.top)

                    // Pay with Link row (interactive)
                    Button(action: presentLink) {
                        HStack(spacing: 16) {
                            Image(uiImage: LinkController.linkIcon)
                                .resizable()
                                .frame(width: 28, height: 28)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Pay with Link")
                                    .font(.headline)
                                    .fontWeight(.medium)

                                if !email.isEmpty {
                                    Text("Continue as \(email)")
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

        STPAPIClient.shared.publishableKey = "pk_test_51Rtc1uHi8weFL2MI0Bk69MoHZv5Dr1uBAjM23ZuvZdbSfZ9hb8BtoyRTsdVwZGtm6XPuMyNdAXp9Kqf3oGGHQzws00ro5dRhat"

        Task {
            let paymentMethodPreview = await linkController.collectPaymentMethod(from: viewController, with: email)
            if paymentMethodPreview != nil {
                DispatchQueue.main.async {
                    dismiss()
                }
            }
        }
    }
}

@available(iOS 16.0, *)
struct CreditCardFormView: View {
    @Environment(\.dismiss) private var dismiss

    var linkController: LinkController

    @State private var cardNumber = ""
    @State private var expiryDate = ""
    @State private var cvc = ""

    @State private var showingAlert: Bool = false
    @State private var alertText: String = ""

    var body: some View {
        VStack(spacing: 20) {
            // Card number field
            VStack(alignment: .leading, spacing: 8) {
                Text("Card Number")
                    .font(.headline)
                    .foregroundColor(.primary)

                TextField("1234 5678 9012 3456", text: $cardNumber)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
            }

            // Expiry date and CVC row
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Expiry Date")
                        .font(.headline)
                        .foregroundColor(.primary)

                    TextField("MM/YY", text: $expiryDate)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("CVC")
                        .font(.headline)
                        .foregroundColor(.primary)

                    TextField("123", text: $cvc)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }
            }

            Spacer()

            // Save card button
            Button {
                alertText = "Not yet implemented"
                showingAlert = true
            } label: {
                Text("Save Card")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(25)
            }
        }
        .padding()
        .navigationTitle("Add Credit Card")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Link signup", isPresented: $showingAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(alertText)
        }
    }
}

// MARK: - Supporting Types

enum CarType: CaseIterable {
    case basic
    case comfort
    case van

    var displayName: String {
        switch self {
        case .basic:
            return "Basic"
        case .comfort:
            return "Comfort"
        case .van:
            return "Van"
        }
    }

    var description: String {
        switch self {
        case .basic:
            return "Affordable ride"
        case .comfort:
            return "Extra legroom"
        case .van:
            return "Seats 6 passengers"
        }
    }

    var price: Double {
        switch self {
        case .basic:
            return 12.50
        case .comfort:
            return 18.75
        case .van:
            return 25.00
        }
    }

    var eta: String {
        switch self {
        case .basic:
            return "2 min"
        case .comfort:
            return "4 min"
        case .van:
            return "6 min"
        }
    }

    var iconName: String {
        switch self {
        case .basic:
            return "car.fill"
        case .comfort:
            return "car.circle.fill"
        case .van:
            return "bus.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .basic:
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
