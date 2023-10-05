//
//  TextFieldSwiftUIView.swift
//  StripeUICore
//
//  Created by Eduardo Urias on 10/4/23.
//

import SwiftUI

@_spi(STP) public struct TextFieldSwiftUIView: UIViewRepresentable {
    @_spi(STP) public typealias UIViewType = TextFieldView

    @State var viewModel: TextFieldElement.ViewModel
    var delegate: TextFieldViewDelegate

    @_spi(STP) public init(
        viewModel: TextFieldElement.ViewModel,
        delegate: TextFieldViewDelegate
    ) {
        _viewModel = State(initialValue: viewModel)
        self.delegate = delegate
    }

    public func makeUIView(context: Context) -> TextFieldView {
        let view = TextFieldView(
            viewModel: viewModel,
            delegate: delegate
        )
//        view.translatesAutoresizingMaskIntoConstraints = true
//        view.setContentHuggingPriority(.required, for: .vertical)

        return view
    }

    public func updateUIView(_ uiView: TextFieldView, context: Context) {
        uiView.delegate = delegate
        uiView.updateUI(with: viewModel)
    }
}

@_spi(STP)
public struct TextFieldSwiftUIView_Previews: PreviewProvider {
    class MyDelegate: TextFieldViewDelegate {
        func textFieldViewDidUpdate(view: TextFieldView) {
            print("Did update")
        }

        func textFieldViewContinueToNextField(view: TextFieldView) {
            print("Continue to next")
        }
    }

    public static var previews: some View {
        let viewModel = TextFieldElement.ViewModel(
            placeholder: "Placeholder",
            accessibilityLabel: "AxLabel",
            attributedText: NSAttributedString(string: "Test"),
            keyboardProperties: .init(
                type: .numberPad,
                textContentType: nil,
                autocapitalization: .none
            ),
            validationState: .valid,
            accessoryView: nil,
            shouldShowClearButton: false,
            theme: ElementsUITheme.default
        )
        return TextFieldSwiftUIView(viewModel: viewModel, delegate: MyDelegate())
            .frame(width: .infinity)
    }
}
