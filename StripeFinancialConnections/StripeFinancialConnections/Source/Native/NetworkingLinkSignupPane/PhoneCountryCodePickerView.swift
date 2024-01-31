//
//  PhoneCountryCodePickerView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/30/24.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

protocol PhoneCountryCodePickerViewDelegate: AnyObject {
    
}

final class PhoneCountryCodePickerView: UIView, UIPickerViewDelegate, UIPickerViewDataSource {

    weak var delegate: PhoneCountryCodePickerViewDelegate?
    
    private lazy var pickerView: UIPickerView = {
        let pickerView = UIPickerView()
        pickerView.dataSource = self
        pickerView.delegate = self
//        pickerView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            pickerView.heightAnchor.constraint(equalToConstant: 100),
//        ])
        return pickerView
    }()

    init() {
        super.init(frame: .zero)
        clipsToBounds = true
        addSubview(pickerView)
//        addAndPinSubview(pickerView)
        
        let height: CGFloat = 150
        
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heightAnchor.constraint(
                equalToConstant: height
            ),
            pickerView.widthAnchor.constraint(equalTo: widthAnchor),
            pickerView.heightAnchor.constraint(greaterThanOrEqualToConstant: height),
            pickerView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        
//        backgroundColor = .backgroundOffset
//        layer.cornerRadius = 8
//        clipsToBounds = true
        
//        let horizontalStackView = UIStackView(
//            arrangedSubviews: [
//                flagLabel,
//                countryCodeLabel,
//            ]
//        )
//        horizontalStackView.axis = .horizontal
//        horizontalStackView.spacing = 8
//        horizontalStackView.isLayoutMarginsRelativeArrangement = true
//        horizontalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
//            top: 12,
//            leading: 12,
//            bottom: 12,
//            trailing: 12
//        )
//        addAndPinSubview(horizontalStackView)
//        
//        addAndPinSubview(textField)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

//    override func endEditing(_ force: Bool) -> Bool {
//        return super.endEditing(force)
//    }
    
    // MARK: - UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(
        _ pickerView: UIPickerView,
        numberOfRowsInComponent component: Int
    ) -> Int {
        return 10
    }

    // MARK: - UIPickerViewDelegate
    
    func pickerView(
        _ pickerView: UIPickerView,
        titleForRow row: Int,
        forComponent component: Int
    ) -> String? {
        return "Meow"
    }

    func pickerView(
        _ pickerView: UIPickerView,
        didSelectRow row: Int,
        inComponent component: Int
    ) {
        
    }
}

#if DEBUG

import SwiftUI

private struct PhoneCountryCodePickerViewUIViewRepresentable: UIViewRepresentable {

    let text: String

    func makeUIView(context: Context) -> PhoneCountryCodePickerView {
        PhoneCountryCodePickerView()
    }

    func updateUIView(
        _ PhoneCountryCodePickerView: PhoneCountryCodePickerView,
        context: Context
    ) {
        
    }
}

struct PhoneCountryCodePickerView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 14.0, *) {
            VStack(spacing: 16) {
                PhoneCountryCodePickerViewUIViewRepresentable(
                    text: ""
                )
//                .frame(width: 72, height: 48)

                Spacer()
            }
            .padding()
            .background(Color(UIColor.customBackgroundColor))
        }
    }
}

#endif
