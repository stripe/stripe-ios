//
//  Buttons.swift
//  FruitStore
//

import Foundation
import SwiftUI

struct ExamplePaymentButtonView: View {
    var text: String
    
    var body: some View {
        HStack {
            Text(text).fontWeight(.bold)
        }
        .frame(minWidth: 200)
        .padding()
        .foregroundColor(.white)
        .background(Color.blue)
        .cornerRadius(6)
        .accessibility(identifier: "Buy button")
    }
}

struct FruitBuyButtonView: View {
    var fruit: Fruit
    
    var body: some View {
        HStack {
            Text("\(fruit.emoji)")
        }
        .padding()
        .background(Color(.white))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.blue, lineWidth: 2)
        )
        .accessibility(identifier: "Buy \(fruit.emoji)")
    }
}


struct BuyFruitButtonView: View {
    var body: some View {
        Text("Buy")
            .bold()
            .font(.system(size: 16, weight: .regular, design: .rounded))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .foregroundColor(.white)
            .background(ForegroundColor)
            .cornerRadius(30.0)
    }
}

struct ProButtonView: View {
    let enabled: Bool
    
    var body: some View {
        if enabled {
            Text("PRO")
                .bold()
                .font(.footnote)
                .padding(2)
                .foregroundColor(.white)
                .background(Color(.black))
                .cornerRadius(3.0)
        } else {
            Text("PRO")
                .bold()
                .font(.footnote)
                .padding(2)
                .foregroundColor(.white)
                .background(Color(.systemGray2))
                .cornerRadius(3.0)
        }
    }
}


struct BuyCoinsButtonView: View {
    var body: some View {
        Text("Buy coins")
            .bold()
            .font(.system(size: 16, weight: .regular, design: .rounded))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .foregroundColor(.white)
            .background(ForegroundColor)
            .cornerRadius(30.0)
    }
}

struct LogoutButtonView: View {
    var body: some View {
        Text("LOG OUT")
            .bold()
            .font(.footnote)
            .padding(2)
            .foregroundColor(.white)
            .background(Color(.black))
            .cornerRadius(3.0)
    }
}



struct Button_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BuyFruitButtonView()
            BuyCoinsButtonView()
        }
    }
}
