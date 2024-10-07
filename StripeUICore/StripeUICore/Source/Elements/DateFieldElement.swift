//
//  DateFieldElement.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 10/1/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

/**
 A textfield whose input view is a `UIDatePicker`
 */
@_spi(STP) public class DateFieldElement {
    public typealias DidUpdateSelectedDate = (Date) -> Void
    struct DateEmptyError: ElementValidationError {
        var localizedDescription: String = STPLocalizedString(
            "Date is empty.",
            "Error message for empty date."
        )
    }

    weak public var delegate: ElementDelegate?
    private(set) lazy var datePickerView: UIDatePicker = {
        let picker = UIDatePicker()
        if #available(iOS 13.4, *) {
            picker.preferredDatePickerStyle = .wheels
        }
        picker.datePickerMode = .date
        picker.addTarget(self, action: #selector(didSelectDate), for: .valueChanged)
        return picker
    }()
    private(set) lazy var pickerFieldView: PickerFieldView = {
        let pickerFieldView = PickerFieldView(
            label: label,
            shouldShowChevron: false,
            pickerView: datePickerView,
            delegate: self,
            theme: theme
        )
        return pickerFieldView
    }()

    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    public private(set) var selectedDate: Date? {
        didSet {
            updateDisplayText()
        }
    }
    private var previouslySelectedDate: Date?
    public var validationState: ElementValidationState {
        if selectedDate != nil {
            return .valid
        } else {
            return .invalid(error: DateEmptyError(), shouldDisplay: false)
        }
    }
    public var didUpdate: DidUpdateSelectedDate?

    private let label: String?
    private let theme: ElementsAppearance

    /**
     - Parameters:
       - label: The label of this picker
       - defaultDate: If this field should be prefilled before the user interacts with it, then provide a default date to display initially.
       - minimumDate: The minimum date that can be selected
       - maximumDate: The maximum date that can be selected
       - locale: The locale to use to format the date into display text and configure the date picker
       - timeZone: The timeZone to use to format the date into display text and configure the date picker
       - didUpdate: Called when the user has selected a new date.
       - theme: Theme for the element

     - Note:
       - If a minimum or maximum date is provided and `defaultDate` is outside of of that range, then the given default is ignored.
       - `didUpdate` is not called if the user does not change their input before hitting "Done"
     */
    public init(
        label: String? = nil,
        defaultDate: Date? = nil,
        minimumDate: Date? = nil,
        maximumDate: Date? = nil,
        locale: Locale = .current,
        timeZone: TimeZone = .current,
        theme: ElementsAppearance = .default,
        customDateFormatter: DateFormatter? = nil,
        didUpdate: DidUpdateSelectedDate? = nil
    ) {
        self.label = label
        self.theme = theme
        if let customDateFormatter = customDateFormatter {
            self.dateFormatter = customDateFormatter
        }
        dateFormatter.locale = locale
        dateFormatter.timeZone = timeZone

        datePickerView.locale = locale
        datePickerView.timeZone = timeZone
        datePickerView.minimumDate = minimumDate
        datePickerView.maximumDate = maximumDate
        if let defaultDate = DateFieldElement.dateWithinBounds(defaultDate, min: minimumDate, max: maximumDate) {
            datePickerView.date = defaultDate
            selectedDate = defaultDate
            updateDisplayText()
        }

        self.previouslySelectedDate = defaultDate
        self.didUpdate = didUpdate
    }

    // MARK: - Internal Methods

    @objc func didSelectDate() {
        selectedDate = datePickerView.date
    }

    private func updateDisplayText() {
        let selectedDate = selectedDate.map { dateFormatter.string(from: $0) }
        pickerFieldView.displayText = NSAttributedString(string: selectedDate ?? "")
    }
}

// MARK: Element

extension DateFieldElement: Element {
    public var collectsUserInput: Bool { true }

    public var view: UIView {
        return pickerFieldView
    }

    public func beginEditing() -> Bool {
        return pickerFieldView.becomeFirstResponder()
    }
}

// MARK: - PickerFieldViewDelegate

extension DateFieldElement: PickerFieldViewDelegate {
    func didBeginEditing(_ pickerFieldView: PickerFieldView) {
        selectedDate = datePickerView.date
    }

    func didFinish(_ pickerFieldView: PickerFieldView, shouldAutoAdvance: Bool) {
        if previouslySelectedDate != selectedDate,
            let selectedDate = selectedDate
        {
            didUpdate?(selectedDate)
            previouslySelectedDate = selectedDate
            delegate?.didUpdate(element: self)
        }
        if shouldAutoAdvance {
            delegate?.continueToNextField(element: self)
        }
    }

    func didCancel(_ pickerFieldView: PickerFieldView) {
        // no-op
    }
}

// MARK: - Private Helpers

private extension DateFieldElement {
    /// Returns the date if it is within the min & max bounds, when applicable. Otherwise returns nil
    static func dateWithinBounds(
        _ date: Date?,
        min: Date?,
        max: Date?
    ) -> Date? {
        guard let date = date else {
            return nil
        }

        if let min = min,
            date < min
        {
            return nil
        }

        if let max = max,
            date > max
        {
            return nil
        }

        return date
    }
}
