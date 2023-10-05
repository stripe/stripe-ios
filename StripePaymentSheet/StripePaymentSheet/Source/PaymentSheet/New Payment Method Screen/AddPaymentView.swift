//
//  AddPaymentView.swift
//  StripePaymentSheet
//
//  Created by Eduardo Urias on 10/4/23.
//

@_spi(STP) import StripeUICore
import SwiftUI

@_spi(STP) public struct AddPaymentView: View {
    let cardNumberElement = TextFieldElement(configuration: TextFieldElement.PANConfiguration())
    let cvcElement = TextFieldElement(configuration: TextFieldElement.CVCConfiguration { .visa })

    public var body: some View {
        HStack {
            VStack {
                cardNumberElement.swiftUIView
                cvcElement.swiftUIView
                Spacer()
            }
        }
    }
}

#Preview {
    AddPaymentView()
}
