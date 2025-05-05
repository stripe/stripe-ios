//
//  ContentView.swift
//  FruitStore
//

import SwiftUI

let BackgroundColor = Color(.sRGB, red: 253/255, green: 232/255, blue: 225/255, opacity: 1.0)
let ForegroundColor = Color(.sRGB, red: 231/255, green: 91/255, blue: 47/255, opacity: 1.0)
let TextColor = Color(.sRGB, red: 60/255, green: 66/255, blue: 87/255, opacity: 1.0)
let SecondaryButtonColor = Color(.sRGB, red: 199/255, green: 69/255, blue: 28/255, opacity: 1.0)

@available(iOS 14.0, *)
struct AppView: View {
    @StateObject var model = FruitModel()
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        ZStack {
            BackgroundColor
                .ignoresSafeArea()
            VStack {
                if let customer = model.customer {
                    CustomerView(customer: customer)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    StoreView()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    Spacer()
                    if let error = model.lastError {
                        ErrorView(error: error)
                            .padding()
                    }
                } else {
                    SigninView()
                }
            }
        }
        .onAppear { model.updateFromServer(force: false) }
        .onChange(of: scenePhase) { newScenePhase in
            if newScenePhase == .active {
                // Refresh the Customer if needed when the app is foregrounded.
                model.updateFromServer(force: false)
            }
          }
        .environmentObject(model)
    }
}

struct ErrorView: View {
    let error: ServerError

    var body: some View {
        Text("⚠️ \(error.localizedDescription)")
            .bold()
            .font(.system(.subheadline, design: .rounded))
            .foregroundColor(TextColor)
            .multilineTextAlignment(.center)
    }
}

@available(iOS 14.0, *)
struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ZStack {
                BackgroundColor.ignoresSafeArea()
                VStack {
                    CustomerView(customer: Customer(name: "Katie Bell", wallet: 85, purchased: [Fruit(emoji: "🍒"), Fruit(emoji: "🍊")], hasProSubscription: false))
                        .padding(.horizontal, 10)
                        .environmentObject(FruitModel())
                    Spacer()
                    StoreView()
                        .padding(.horizontal, 10)
                        .environmentObject(FruitModel())
                }
            }

        }
    }
}
