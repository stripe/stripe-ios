//
//  StoreView.swift
//  FruitStore
//

import Foundation
import SwiftUI

struct StoreView: View {
    @EnvironmentObject var model: FruitModel

    let forSale = [Fruit(emoji: "🍊"),
                   Fruit(emoji: "🍒"),
                   Fruit(emoji: "🍉"), ]

    var body: some View {
        VStack(alignment: .leading) {
            Text("The fruit stand")
                .foregroundColor(TextColor)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .padding(.top, 24)
                .padding(.horizontal, 24)
            HStack {
                ForEach(forSale, id: \.self.emoji) { fruit in
                    VStack {
                        Text(fruit.emoji)
                            .font(.system(size: 48))
                        Text(fruit.name)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(TextColor)
                        Text("10 coins")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(TextColor)
                        Button {
                            model.buy(fruit)
                        } label: {
                            BuyFruitButtonView()
                                .padding()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
        }
        .frame(idealWidth: .infinity, maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(24.0)
    }
}

@available(iOS 15.0, *)
struct StoreView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ZStack {
                BackgroundColor.ignoresSafeArea()
                VStack {
                    CustomerView(customer: Customer(name: "Katie Bell", wallet: 85, purchased: [], hasProSubscription: false))
                        .padding(.horizontal, 20)
                        .environmentObject(FruitModel())
                    StoreView()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .environmentObject(FruitModel())
                    Spacer()
                }
            }

            ZStack {
                BackgroundColor.ignoresSafeArea()
                VStack {
                    CustomerView(customer: Customer(name: "Katie Bell", wallet: 85, purchased: [Fruit(emoji: "🍒"), Fruit(emoji: "🍊")], hasProSubscription: false))
                        .padding(.horizontal, 20)
                        .environmentObject(FruitModel())
                    StoreView()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .environmentObject(FruitModel())
                    Spacer()
                }
            }

        }
    }
}
