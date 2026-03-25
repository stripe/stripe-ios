//
//  FormSpecProvider.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 2/21/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

// Intentionally force-unwrap since PaymentSheet requires this file to exist
private let formSpecsURL = StripePaymentSheetBundleLocator.resourcesBundle.url(forResource: "form_specs", withExtension: ".json")!

/// Provides FormSpecs for a given a payment method type.
/// - Note: You must `load(completion:)` to load the specs json file into memory before calling `formSpec(for:)`
/// - To overwrite any of these specs use load(from:)
class FormSpecProvider {
    enum Error: Swift.Error {
        case failedToLoadSpecs
        case formSpecsNotReady
    }
    static var shared: FormSpecProvider = FormSpecProvider()
    fileprivate var formSpecs: [String: FormSpec] = [:]

    /// Loading from disk should take place on this serial queue.
    private let formSpecsUpdateQueue = DispatchQueue(label: "com.stripe.Form.FormSpecProvider", qos: .userInitiated)

    var isLoaded: Bool {
        return !formSpecs.isEmpty
    }

    var hasLoadedFromDisk: Bool = false

    /// Loads the JSON form spec from disk into memory
    func load(completion: ((Bool) -> Void)? = nil) {
        formSpecsUpdateQueue.async { [weak self] in
            if self?.hasLoadedFromDisk == true {
                completion?(true)
                return
            }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            do {
                let data = try Data(contentsOf: formSpecsURL)
                let decodedFormSpecs = try decoder.decode([FormSpec].self, from: data)
                self?.formSpecs = Dictionary(uniqueKeysWithValues: decodedFormSpecs.map { ($0.type, $0) })
                self?.hasLoadedFromDisk = true
                completion?(true)
            } catch {
                let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetError,
                                                  error: Error.failedToLoadSpecs)
                STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
                completion?(false)
                return
            }
        }
    }
    
    func load() async {
        await withCheckedContinuation { continuation in
            load { _ in
                continuation.resume()
            }
        }
    }

    /// Allows overwriting of formSpecs given a NSDictionary.  Typically, the specs comes
    /// from the sessions endpoint.
    func loadFrom(_ formSpecsAny: Any) -> Bool {
        guard let formSpecs = formSpecsAny as? [NSDictionary] else {
            STPAnalyticsClient.sharedClient.logLUXESerializeFailure()
            return false
        }

        var decodedSuccessfully = true
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        for formSpec in formSpecs {
            do {
                let data = try JSONSerialization.data(withJSONObject: formSpec)
                let decodedFormSpec = try decoder.decode(FormSpec.self, from: data)
                self.formSpecs[decodedFormSpec.type] = decodedFormSpec
            } catch {
                STPAnalyticsClient.sharedClient.logLUXESpecSerilizeFailure(error: error)
                decodedSuccessfully = false
            }
        }
        return decodedSuccessfully
    }

    func formSpec(for paymentMethodType: String) -> FormSpec? {
        if formSpecs.isEmpty {
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetError,
                                              error: Error.formSpecsNotReady,
                                              additionalNonPIIParams: ["payment_method_type": paymentMethodType])
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
        }
        stpAssert(!formSpecs.isEmpty, "formSpec(for:) was called before loading form specs JSON!")
        return formSpecs[paymentMethodType]
    }
}
