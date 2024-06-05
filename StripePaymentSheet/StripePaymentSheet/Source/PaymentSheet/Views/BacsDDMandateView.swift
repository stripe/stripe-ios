//
//  BacsDDMandateView.swift
//  StripePaymentSheet
//
//  Created by David Estes on 9/6/23.
//

@_spi(STP) import StripeUICore
import SwiftUI
import UIKit

// Reusing these colors from Link:
private let headerColor = Color(UIColor.linkPrimaryText)
private let secondaryTextColor = Color(UIColor.linkSecondaryText)

private var borderColor = Color(.dynamic(
    light: UIColor(red: 0.878, green: 0.902, blue: 0.922, alpha: 1),
    dark: UIColor(red: 0.471, green: 0.471, blue: 0.502, alpha: 0.36)
))

private var backgroundColor = Color(.dynamic(
    light: UIColor(red: 0.965, green: 0.973, blue: 0.980, alpha: 1.0),
    dark: UIColor(red: 0.455, green: 0.455, blue: 0.502, alpha: 0.18)
))

private let shadow1Color = Color(red: 18/255, green: 42/255, blue: 66/255, opacity: 0.04)
private let shadow2Color = Color(red: 0/255, green: 0/255, blue: 0/255, opacity: 0.04)

struct BacsDDMandateView: View {
    let email: String
    let name: String
    let sortCode: String
    let accountNumber: String

    let confirmAction: () -> Void
    let cancelAction: () -> Void

    var mandateInfo: String {
      """
      An email will be sent to \(email) within three business days to confirm the setup of this debit instruction.

      Additionally, you will receive two days advance notice via email of any amount to be debited under this instruction. Payments will show as 'Stripe' on your bank statement.
      """
    }

    let addressInfo = """
Stripe, 7th Floor The Bower Warehouse
207-211 Old St, London EC1V 9NR
support@stripe.com
"""

    var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Confirm your Direct Debit details")
                        .foregroundColor(headerColor)
                        .font(.title)
                        .fontWeight(.medium)
                    BacsDDMandateAccountInfoView(email: email, name: name, sortCode: sortCode, accountNumber: accountNumber)
                        .padding([.bottom])
                    Text(mandateInfo)
                        .multilineTextAlignment(.leading)
                        .padding([.bottom])
                    HStack {
                        Text("Your payments are protected by the [Direct Debit Guarantee](https://stripe.com/legal/bacs-direct-debit-guarantee).")
                            .multilineTextAlignment(.leading)
                            .padding([.trailing])
                        SwiftUI.Image(uiImage: Image.bacsdd_logo.makeImage(template: false))
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 94)
                    }
                    .padding([.bottom])
                    Text(addressInfo)
                        .multilineTextAlignment(.leading)
                }
            }
            Spacer()
            HStack {
                Button(action: cancelAction, label: {
                    ButtonView(text: "Modify Details",
                               foregroundColor: Color.black,
                               backgroundColor: Color.white,
                               strokeWidth: 1
                    )
                })
                Button(action: confirmAction, label: {
                    ButtonView(text: "Confirm",
                               foregroundColor: Color.white,
                               backgroundColor: Color.blue,
                               strokeWidth: 0
                    )
                })
            }
        }
        .foregroundColor(secondaryTextColor)
        .padding(18)

    }
}

private struct ButtonView: View {
    let text: String
    let foregroundColor: Color
    let backgroundColor: Color
    let strokeWidth: CGFloat

    var body: some View {
        Text(text)
            .font(.callout)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(5)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                                 .stroke(borderColor, lineWidth: strokeWidth)
            )
            .shadow(color: shadow1Color, radius: 6, x: 0, y: 3)
            .shadow(color: shadow2Color, radius: 3, x: 0, y: 1)
    }
}

struct BacsDDMandateAccountInfoView: View {
    let email: String
    let name: String
    let sortCode: String
    let accountNumber: String

    var body: some View {
        VStack {
            HStack {
                Text("Email")
                    .fontWeight(.medium)
                Spacer()
                Text(verbatim: email)
            }
            HStack {
                Text("Name on account")
                    .fontWeight(.medium)
                Spacer()
                Text(name)
            }
            HStack {
                Text("Sort code")
                    .fontWeight(.medium)
                Spacer()
                Text(sortCode)
            }
            HStack {
                Text("Account number")
                    .fontWeight(.medium)
                Spacer()
                Text(accountNumber)
            }
        }
        .foregroundColor(secondaryTextColor)
        .padding()
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
            .stroke(borderColor, lineWidth: 1)
        )
        .cornerRadius(5)
    }
}

struct BacsDDMandateView_Previews: PreviewProvider {
    static var previews: some View {
        BacsDDMandateView(email: "j.diaz@example.com", name: "Jane Diaz", sortCode: "10-88-00", accountNumber: "00012345", confirmAction: {}, cancelAction: {})
    }
}
