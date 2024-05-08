//
//  PaymentsListView.swift
//  StripeConnect Example
//
//  Created by Mel Ludowise on 5/7/24.
//

import SwiftUI

struct PaymentsListView: View {
    struct Charge: Decodable, Identifiable {
        let id: String
        let description: String?
        let amount: Int
        let currency: String
    }
    struct Response: Decodable {
        let data: [Charge]
    }

    let account: String
    let onSelection: (_ chargeId: String) -> Void
    @State var charges: [Charge]?

    var body: some View {
        NavigationView {
            Group {
                if let charges, charges.isEmpty {
                    Text("This account has no charges")
                } else if let charges {
                    List {
                        ForEach(charges) { charge in
                            Button {
                                onSelection(charge.id)
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(charge.id)
                                    charge.description.map(Text.init)
                                    HStack {
                                        Text("\(charge.amount)")
                                        Text(charge.currency)
                                        Spacer()
                                    }
                                }
                                .foregroundColor(Color(uiColor: .label))
                            }
                        }
                    }
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Select a charge")
            .navigationBarTitleDisplayMode(.inline)
        }
        .environment(\.horizontalSizeClass, .compact)
        .onAppear {
            Task {
                var components = URLComponents(string: "https://stripe-connect-example.glitch.me/charges")!
                components.queryItems = [
                    .init(name: "account", value: account)
                ]
                let request = URLRequest(url: components.url!)

                do {
                    // Fetch the AccountSession client secret
                    let (data, _) = try await URLSession.shared.data(for: request)
                    let response = try JSONDecoder().decode(Response.self, from: data)
                    self.charges = response.data
                } catch {
                    UIApplication.shared.showToast(message: error.localizedDescription)
                }
            }
        }
    }
}
