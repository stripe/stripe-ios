//
//  STPTemplatedNetworkStubbing.swift
//  StripePaymentsTestUtils
//
//  Created by Eric Geniesse on 7/31/24.
//

import Foundation
import OHHTTPStubs
@testable@_spi(STP) import StripePayments

public struct STPTemplateVariables {
    var paymentMethod: STPPaymentMethodType
    var paymentIntent: String
    var clientSecret: String
    var amount: Int
    var currency: String
    
    // Convert the structured properties to a dictionary
    // for easier replacement in the JSON template
    var asDictionary: [String: String] {
        return [
            "{{paymentMethod}}": paymentMethod.identifier,
            "{{amount}}": String(amount),
            "{{currency}}": currency,
            "{{paymentIntent}}": paymentIntent,
            "{{clientSecret}}": clientSecret,
        ]
    }
    
    // Adding a public initializer
    public init(
        paymentMethod: STPPaymentMethodType,
        amount: Int = 5099,
        currency: String = "USD",
        paymentIntent: String = "pi_3PePOhKG6vc7r7YC1Pw6dbvN",
        clientSecret: String = "pi_3PePOhKG6vc7r7YC1Pw6dbvN_secret_GxrAcmHUHALTePgjypUIyYIF4"
    ) {
        self.paymentMethod = paymentMethod
        self.amount = amount
        self.currency = currency
        self.paymentIntent = paymentIntent
        self.clientSecret = clientSecret
    }
}

public func configureSTPTemplatedNetworkStubs(
    variables: STPTemplateVariables,
    templateDir: String
) throws {

    if networkMocksAreDisabled() {
        return
    }

    let templateDirPath = resolveResourcesDirectoryPath(relativePath: templateDir)
    let jsonTemplates = try FileManager.default.contentsOfDirectory(atPath: templateDirPath).sorted(by: >)
    
    // For each of the templates, configure a mock
    for template in jsonTemplates where template.hasSuffix(".json") {
        // Read the file contents
        let filePath = URL(fileURLWithPath: templateDirPath).appendingPathComponent(template).path
        var fileContents = try String(contentsOfFile: filePath, encoding: .utf8)
        
        // Replace all the templated values with the pre-configured variables.
        variables.asDictionary.forEach { placeholder, value in
            fileContents = fileContents.replacingOccurrences(of: placeholder, with: value)
        }
        // Attempt JSON parsing to ensure validity
        let jsonData = fileContents.data(using: .utf8)!
        let parsedConfig = try JSONSerialization.jsonObject(with: jsonData, options: []) as! [String: Any]
        
        // Extract the information we need out of the hydrated JSON template
        guard let urlExpression = parsedConfig["url"] as? String,
              let httpMethod = parsedConfig["httpMethod"] as? String,
              let statusCode = parsedConfig["statusCode"] as? Int32,
              let headers = parsedConfig["headers"] as? [String: String],
              let bodyObject = parsedConfig["body"],
              let bodyData = try? JSONSerialization.data(withJSONObject: bodyObject, options: []) else {
            throw EncodingError.invalidValue(parsedConfig, EncodingError.Context(codingPath: [], debugDescription: "Error: JSON structure doesn't match expected format"))
        }
        var stub: HTTPStubsDescriptor?

        // Setup the HTTP mock!
        stub = HTTPStubs.stubRequests(passingTest: {(request) -> Bool in
            // Optionally add request validation here...
            if (request.httpMethod != httpMethod) {
                return false
            }
            
            // If there is a ULR in the request, check to see if it matches the configured regex
            if let requestUrl = request.url?.absoluteString {
                if (requestUrl.range(of: urlExpression, options: .regularExpression) == nil) {
                    print("Unable to match URL")
                    print(requestUrl)
                    print(urlExpression)
                    print(template)
                }
                return requestUrl.range(of: urlExpression, options: .regularExpression) != nil
            }

            
            // There is no URL configured somehow.
            return false
        }, withStubResponse: { (request) -> HTTPStubsResponse in
            // Since there are some requests made to the same URL that require a different
            // response, we rely on the stub creation ordering, then shedding stubs as
            // they are used.
            HTTPStubs.removeStub(stub!)
            
            // If the matcher returned "true", return the pre-configured response.
            return HTTPStubsResponse(
                data: bodyData,
                statusCode: statusCode,
                headers: headers
            )
        })
    }
}
