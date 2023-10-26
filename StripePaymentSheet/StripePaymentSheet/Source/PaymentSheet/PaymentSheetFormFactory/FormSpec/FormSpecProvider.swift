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
    static var shared: FormSpecProvider = FormSpecProvider()
    fileprivate var formSpecs: [String: FormSpec] = [:]

    /// Loading from disk should take place on this serial queue.
    private lazy var formSpecsUpdateQueue: DispatchQueue = {
        DispatchQueue(label: "com.stripe.Form.FormSpecProvider", qos: .userInitiated)
    }()

    var isLoaded: Bool {
        return !formSpecs.isEmpty
    }

    /// Loads the JSON form spec from disk into memory
    func load(completion: ((Bool) -> Void)? = nil) {
        formSpecsUpdateQueue.async { [weak self] in
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            do {
                let data = try Data(contentsOf: formSpecsURL)
                let decodedFormSpecs = try decoder.decode([FormSpec].self, from: data)
                self?.formSpecs = Dictionary(uniqueKeysWithValues: decodedFormSpecs.map { ($0.type, $0) })
                completion?(true)
            } catch {
                completion?(false)
                return
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
                guard !containsUnknownNextActions(formSpec: decodedFormSpec) else {
                    STPAnalyticsClient.sharedClient.logLUXEUnknownActionsFailure()
                    decodedSuccessfully = false
                    continue
                }
                self.formSpecs[decodedFormSpec.type] = decodedFormSpec
            } catch {
                STPAnalyticsClient.sharedClient.logLUXESpecSerilizeFailure(error: error)
                decodedSuccessfully = false
            }
        }
        return decodedSuccessfully
    }

    func formSpec(for paymentMethodType: String) -> FormSpec? {
        assert(!formSpecs.isEmpty, "formSpec(for:) was called before loading form specs JSON!")
        return formSpecs[paymentMethodType]
    }

    func nextActionSpec(for paymentMethodType: String) -> FormSpec.NextActionSpec? {
        return formSpecs[paymentMethodType]?.nextActionSpec
    }

    func containsUnknownNextActions(formSpec: FormSpec) -> Bool {
        if let nextActionSpec = formSpec.nextActionSpec {
            for (_, nextActionStatusValue) in nextActionSpec.confirmResponseStatusSpecs {
                if case .unknown = nextActionStatusValue.type {
                    return true
                }
            }
            if let postConfirmSpecs = nextActionSpec.postConfirmHandlingPiStatusSpecs {
                for (_, nextActionStatusValue) in postConfirmSpecs {
                    if case .unknown = nextActionStatusValue.type {
                        return true
                    }
                }
            }
        }
        return false
    }
}
