//
//  SavedPaymentMethodsSheetDelegate.swift
//  StripePaymentSheet
//

@_spi(PrivateBetaSavedPaymentMethodsSheet) public protocol SavedPaymentMethodsSheetDelegate: AnyObject {
    func didFinish(with paymentOptionSelection: SavedPaymentMethodsSheet.PaymentOptionSelection?)
    func didCancel()
    func didFail(with error: SavedPaymentMethodsSheetError)
}
