/*
 Copyright © 2020 Apple Inc.

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Abstract:
A button that hosts PKPaymentButton from Apple's Fruta example app.
*/

import SwiftUI
import PassKit

struct PaymentButton: View {
    var action: () -> Void
    
    var height: CGFloat {
        #if os(macOS)
        return 30
        #else
        return 45
        #endif
    }
    
    var body: some View {
        Representable(action: action)
            .frame(minWidth: 100, maxWidth: 400)
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .accessibility(label: Text("Buy with Apple Pay"))
    }
}

extension PaymentButton {
    #if os(iOS)
    typealias ViewRepresentable = UIViewRepresentable
    #else
    typealias ViewRepresentable = NSViewRepresentable
    #endif
    
    struct Representable: ViewRepresentable {
        var action: () -> Void
        
        init(action: @escaping () -> Void) {
            self.action = action
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(action: action)
        }
        
        #if os(iOS)
        func makeUIView(context: Context) -> UIView {
            context.coordinator.button
        }
        
        func updateUIView(_ rootView: UIView, context: Context) {
            context.coordinator.action = action
        }
        #else
        func makeNSView(context: Context) -> NSView {
            context.coordinator.button
        }
        
        func updateNSView(_ rootView: NSView, context: Context) {
            context.coordinator.action = action
        }
        #endif
    }
    
    class Coordinator: NSObject {
        var action: () -> Void
        var button = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .automatic)
        
        init(action: @escaping () -> Void) {
            self.action = action
            super.init()
            #if os(iOS)
            button.addTarget(self, action: #selector(callback(_:)), for: .touchUpInside)
            #else
            button.action = #selector(callback(_:))
            button.target = self
            #endif
        }
        
        @objc
        func callback(_ sender: Any) {
            action()
        }
    }
}

struct PaymentButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PaymentButton(action: {})
                .padding()
                .preferredColorScheme(.light)
            PaymentButton(action: {})
                .padding()
                .preferredColorScheme(.dark)
        }
        .previewLayout(.sizeThatFits)
    }
}
