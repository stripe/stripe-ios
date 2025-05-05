//
//  CustomerView.swift
//  FruitStore
//

import Foundation
import StoreKit
import SwiftUI

@available(iOS 14.0, *)
struct CustomerView: View {
    let customer: Customer
    @EnvironmentObject var model: FruitModel
    @State private var animationState = false
    @State private var proEnabled = false

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(customer.name)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(TextColor)
                        .onTapGesture {
                            model.logout()
                        }
                    Text("\(customer.wallet) coins")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(TextColor)
//                    Button("Log out") {
//                        model.logout()
//                    }
                }
                Spacer()
                if model.loading {
                    ProgressView()
                        .padding(.trailing, 6)
                        .padding(.top, 12)
                }
                if SKPaymentQueue.canMakePayments() {
                    Button {
                        model.openRefillPage()
                    } label: {
                        BuyCoinsButtonView()
                    }.onOpenURL { url in
                        model.didCompleteRefill(url: url)
                    }
                }
            }
            .padding(.bottom, 12)
            FruitBowlView(customer: customer)
        }
    }
}

struct FruitBowlView: View {
    let customer: Customer
    @EnvironmentObject var model: FruitModel
    @State private var animationState = false
    @State private var proEnabled = false

    var body: some View {
        VStack(alignment: .leading) {
            Text("Your fruit bowl")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(TextColor)
                .padding(.top, 24)
                .padding(.horizontal, 24)
            if proEnabled && customer.hasProSubscription {
//                LinearGradient(gradient: Gradient(colors: [.purple, .blue, .red, .orange]),
//                               startPoint: animationState ? .topLeading : .bottomLeading,
//                               endPoint: animationState ? .bottomTrailing : .topTrailing)
//                    .hueRotation(.degrees(animationState ? 90 : 0))
//                    .onAppear(perform: {
//                        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
//                            animationState.toggle()
//                        }
//                    })
//                    .mask(Text(customer.purchasedString)
//                            .font(.system(size: 32))
//                    )
            } else {
                if let purchasedString = customer.purchasedString {
                    Text(purchasedString)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, maxHeight: 240)
//                        .padding(.top, 60)
//                        .padding(.bottom, 100)
                        .padding(.horizontal, 12)
                        .font(.system(size: 48))
                        .minimumScaleFactor(0.01)
                } else {
                    VStack {
                        Text("No fruit")
                            .font(.system(size: 24, weight: .medium, design: .rounded))
                            .foregroundColor(Color(.systemGray))
                            .multilineTextAlignment(.center)
                        Text("Buy some at the fruit stand")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(Color(.systemGray))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 240)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(24.0)
    }
}

fileprivate extension Customer {
    var purchasedString: String? {
        let emojiString = purchased.map({ $0.emoji }).joined()
        return emojiString.isEmpty ? nil : emojiString
    }
}

@available(iOS 14.0, *)
struct CustomerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ZStack {
            BackgroundColor
                .ignoresSafeArea()
            CustomerView(customer: Customer(name: "Katie Bell", wallet: 85, purchased: [Fruit(emoji: "🍒"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍒"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍒"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊"), Fruit(emoji: "🍊")], hasProSubscription: false))
                .environmentObject(FruitModel())
            }
            ZStack {
            BackgroundColor
                .ignoresSafeArea()
            CustomerView(customer: Customer(name: "Katie Bell", wallet: 85, purchased: [], hasProSubscription: false))
                .environmentObject(FruitModel())
            }
            ZStack {
            BackgroundColor
                .ignoresSafeArea()
            CustomerView(customer: Customer(name: "Katie Bell", wallet: 85, purchased: [Fruit(emoji: "🍒"), Fruit(emoji: "🍊")], hasProSubscription: false))
                .environmentObject(FruitModel())
            }
        }
    }
}
