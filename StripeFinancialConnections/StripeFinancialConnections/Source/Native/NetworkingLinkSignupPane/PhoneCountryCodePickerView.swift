//
//  PhoneCountryCodePickerView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/30/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol PhoneCountryCodePickerViewDelegate: AnyObject {
    func phoneCountryCodePickerView(
        _ pickerView: PhoneCountryCodePickerView,
        didSelectCountryCode countryCode: String
    )
}

final class PhoneCountryCodePickerView: UIView, UIPickerViewDelegate, UIPickerViewDataSource {

    private let height: CGFloat = 250

    private lazy var pickerView: UIPickerView = {
        let pickerView = UIPickerView()
        pickerView.dataSource = self
        pickerView.delegate = self
        return pickerView
    }()
    private let rowItems: [CountryCodeRowItem]
    private var selectedRow: Int {
        didSet {
            delegate?.phoneCountryCodePickerView(
                self,
                didSelectCountryCode: selectedCountryCode
            )
        }
    }
    var selectedCountryCode: String {
        return rowItems[selectedRow].countryCode
    }

    weak var delegate: PhoneCountryCodePickerViewDelegate?

    init(defaultCountryCode: String?) {
        let locale = Locale.current
        let rowItems = CreateCountryCodeRowItems(locale: locale)
        let defaultCountryCode = defaultCountryCode ?? locale.stp_regionCode ?? "US"
        self.rowItems = rowItems
        self.selectedRow = IndexInCountryCodeRowItems(
            rowItems,
            forCountryCode: defaultCountryCode
        ) ?? 0
        super.init(frame: .zero)
        clipsToBounds = true
        addSubview(pickerView)

        translatesAutoresizingMaskIntoConstraints = false
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: height),
            pickerView.widthAnchor.constraint(equalTo: widthAnchor),
            // UIPickerView defines its own height so, to avoid breaking
            // constraints/layout, we center it within the view, but
            // `clipsToBounds` its edges
            pickerView.heightAnchor.constraint(greaterThanOrEqualToConstant: height),
            pickerView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        // adjusted pickerview to selected row
        if pickerView.selectedRow(inComponent: 0) != selectedRow {
            pickerView.reloadComponent(0)
            selectRow(selectedRow)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // fixes a bug where height was not respected when put
    // into `textField.inputView` unless this was overridden
    override var intrinsicContentSize: CGSize {
        var intrinsicContentSize = super.intrinsicContentSize
        intrinsicContentSize.height = height
        return intrinsicContentSize
    }

    func selectCountryCode(_ countryCode: String) {
        guard let row = IndexInCountryCodeRowItems(
            rowItems,
            forCountryCode: countryCode
        ) else {
            return
        }
        selectRow(row)
        selectedRow = row
    }

    private func selectRow(_ row: Int) {
        pickerView.selectRow(row, inComponent: 0, animated: false)
    }

    // MARK: - UIPickerViewDataSource

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(
        _ pickerView: UIPickerView,
        numberOfRowsInComponent component: Int
    ) -> Int {
        return rowItems.count
    }

    // MARK: - UIPickerViewDelegate

    func pickerView(
        _ pickerView: UIPickerView,
        titleForRow row: Int,
        forComponent component: Int
    ) -> String? {
        let rowItem = rowItems[row]
        return rowItem.displayTitle
    }

    func pickerView(
        _ pickerView: UIPickerView,
        didSelectRow row: Int,
        inComponent component: Int
    ) {
        selectedRow = row
    }
}

private func IndexInCountryCodeRowItems(
    _ countryCodeRowItems: [CountryCodeRowItem],
    forCountryCode countryCode: String
) -> Int? {
    return countryCodeRowItems.firstIndex(
        where: { $0.countryCode == countryCode }
    )
}

private struct CountryCodeRowItem {
    let displayTitle: String
    let countryCode: String
}

private func CreateCountryCodeRowItems(locale: Locale) -> [CountryCodeRowItem] {
    let countryCodes = locale.sortedByTheirLocalizedNames(
        PhoneNumber.Metadata.allMetadata.map({ $0.regionCode })
    )
    return countryCodes.map { countryCode in
        let countryFlag = String.countryFlagEmoji(for: countryCode) ?? ""              // 🇺🇸
        let countryName = locale.localizedString(forRegionCode: countryCode) ?? countryCode          // United States
        let phonePrefix = PhoneNumber.Metadata.metadata(for: countryCode)?.prefix ?? ""   // +1
        return CountryCodeRowItem(
            displayTitle: "\(countryFlag) \(countryName) (\(phonePrefix))",
            countryCode: countryCode
        )
    }
}

#if DEBUG

import SwiftUI

private struct PhoneCountryCodePickerViewUIViewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> PhoneCountryCodePickerView {
        PhoneCountryCodePickerView(defaultCountryCode: nil)
    }

    func updateUIView(
        _ phoneCountryCodePickerView: PhoneCountryCodePickerView,
        context: Context
    ) {}
}

struct PhoneCountryCodePickerView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 14.0, *) {
            VStack(spacing: 0) {
                PhoneCountryCodePickerViewUIViewRepresentable()
                Spacer()
            }
            .padding(.horizontal, 40)
        }
    }
}

#endif
