//
//  ExampleLinkStandaloneComponent.swift
//  PaymentSheet Example
//
//  Created by Till Hellmund on 6/19/25.
//

import SwiftUI

struct ExampleLinkStandaloneComponent: View {
    var body: some View {
        VStack {
            Spacer()
            Text("Link")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

struct ExampleLinkStandaloneComponent_Previews: PreviewProvider {
    static var previews: some View {
        ExampleLinkStandaloneComponent()
    }
}
