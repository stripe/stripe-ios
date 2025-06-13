//
//  ShippingModels.swift
//  WebViewBridge2
//
//  Created for handling shipping rates and addresses
//

import Foundation

// MARK: - Shipping Address Model
struct ShippingAddress: Codable {
    let address1: String?
    let address2: String?
    let city: String?
    let companyName: String?
    let countryCode: String
    let email: String?
    let firstName: String?
    let lastName: String?
    let phone: String?
    let postalCode: String?
    let provinceCode: String // State/Province code
    
    // Initialize from dictionary (for JavaScript bridge)
    init?(from dictionary: [String: Any]) {
        guard let address1 = dictionary["address1"] as? String,
              let city = dictionary["city"] as? String,
              let countryCode = dictionary["countryCode"] as? String,
              let postalCode = dictionary["postalCode"] as? String,
              let provinceCode = dictionary["provinceCode"] as? String else {
            return nil
        }
        
        self.address1 = address1
        self.address2 = dictionary["address2"] as? String
        self.city = city
        self.companyName = dictionary["companyName"] as? String
        self.countryCode = countryCode
        self.email = dictionary["email"] as? String
        self.firstName = dictionary["firstName"] as? String
        self.lastName = dictionary["lastName"] as? String
        self.phone = dictionary["phone"] as? String
        self.postalCode = postalCode
        self.provinceCode = provinceCode
    }
    
    init(provinceCode: String, countryCode: String) {
        self.address1 = nil
        self.address2 = nil
        self.city = nil
        self.companyName = nil
        self.countryCode = countryCode
        self.provinceCode = provinceCode
        self.email = nil
        self.firstName = nil
        self.lastName = nil
        self.phone = nil
        self.postalCode = nil
    }
        
}

// MARK: - Shipping Rate Model
struct ShippingRate: Codable {
    let id: String
    let displayName: String
    let amount: Int
    let deliveryEstimate: String
    
    // Convert to dictionary for JavaScript bridge
    var asDictionary: [String: Any] {
        return [
            "id": id,
            "displayName": displayName,
            "amount": amount,
            "deliveryEstimate": deliveryEstimate
        ]
    }
}

// MARK: - Line Item Model
struct LineItem: Codable {
    let name: String
    let amount: Int
    
    // Convert to dictionary for JavaScript bridge
    var asDictionary: [String: Any] {
        return [
            "name": name,
            "amount": amount
        ]
    }
}

// MARK: - Shipping Response Model
struct ShippingResponse {
    let merchantDecision: String
    let lineItems: [LineItem]?
    let shippingRates: [ShippingRate]?
    let totalAmount: Int?
    let error: String?
    
    // Success response
    static func accepted(lineItems: [LineItem], shippingRates: [ShippingRate], totalAmount: Int) -> ShippingResponse {
        return ShippingResponse(
            merchantDecision: "accepted",
            lineItems: lineItems,
            shippingRates: shippingRates,
            totalAmount: totalAmount,
            error: nil
        )
    }
    
    // Rejection response
    static func rejected(error: String) -> ShippingResponse {
        return ShippingResponse(
            merchantDecision: "rejected",
            lineItems: nil,
            shippingRates: nil,
            totalAmount: nil,
            error: error
        )
    }
    
    // Convert to dictionary for JavaScript bridge
    var asDictionary: [String: Any] {
        var dict: [String: Any] = ["merchantDecision": merchantDecision]
        
        if let lineItems = lineItems {
            dict["lineItems"] = lineItems.map { $0.asDictionary }
        }
        
        if let shippingRates = shippingRates {
            dict["shippingRates"] = shippingRates.map { $0.asDictionary }
        }
        
        if let totalAmount = totalAmount {
            dict["totalAmount"] = totalAmount
        }
        
        if let error = error {
            dict["error"] = error
        }
        
        return dict
    }
}

// MARK: - Shipping Service
class ShippingService {
    static let shared = ShippingService()
    
    private let baseURL = "https://unexpected-dune-list.glitch.me"
    private let session = URLSession.shared
    
    private init() {}
    
    // Fetch shipping rates from the API - now async
    func fetchShippingRates(for address: ShippingAddress) async throws -> [ShippingRate] {
        // Build URL with query parameters
        guard var components = URLComponents(string: "\(baseURL)/shipping") else {
            throw NSError(domain: "ShippingService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        components.queryItems = [
            URLQueryItem(name: "state", value: address.provinceCode),
            URLQueryItem(name: "country", value: address.countryCode)
        ]
        
        guard let url = components.url else {
            throw NSError(domain: "ShippingService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL with parameters"])
        }
        
        print("📦 Fetching shipping rates from: \(url)")
        
        do {
            let (data, _) = try await session.data(from: url)
            
            // The API returns an array of shipping rates
            let rates = try JSONDecoder().decode([ShippingRate].self, from: data)
            print("✅ Fetched \(rates.count) shipping rates")
            return rates
        } catch {
            print("❌ Failed to fetch/decode shipping rates: \(error)")
            // Try to print the raw response for debugging if it's a decoding error
            if let urlError = error as? URLError {
                print("URL Error: \(urlError)")
            }
            throw error
        }
    }
    
    // Calculate shipping with business logic - now async
    func calculateShipping(for address: ShippingAddress) async throws -> ShippingResponse {
        // Check if we can ship to this location
        if address.provinceCode == "AK" || address.provinceCode == "HI" {
            return .rejected(error: "Sorry, we don't ship to Alaska or Hawaii")
        }
        
        do {
            // Fetch shipping rates from the API
            let rates = try await fetchShippingRates(for: address)
            
            // Default line items (you might want to make this dynamic)
            let lineItems = [
                LineItem(name: "Golden Potato", amount: 500),
                LineItem(name: "Silver Potato", amount: 345),
                LineItem(name: "Tax", amount: 200)
            ]
            
            // Calculate total amount (items + default shipping)
            let itemsTotal = lineItems.reduce(0) { $0 + $1.amount }
            let defaultShippingAmount = rates.first?.amount ?? 0
            let totalAmount = itemsTotal + defaultShippingAmount
            
            return .accepted(
                lineItems: lineItems,
                shippingRates: rates,
                totalAmount: totalAmount
            )
        } catch {
            print("❌ Failed to fetch shipping rates: \(error)")
            // Fallback to hardcoded rates if API fails
            let fallbackRates = [
                ShippingRate(id: "standard", displayName: "Standard Shipping", amount: 0, deliveryEstimate: "5-7 Business Days"),
                ShippingRate(id: "express", displayName: "Express Shipping", amount: 800, deliveryEstimate: "2-3 Business Days")
            ]
            
            let lineItems = [
                LineItem(name: "Golden Potato", amount: 500),
                LineItem(name: "Silver Potato", amount: 345),
                LineItem(name: "Tax", amount: 200)
            ]
            
            let totalAmount = 1045 // Default total
            
            return .accepted(
                lineItems: lineItems,
                shippingRates: fallbackRates,
                totalAmount: totalAmount
            )
        }
    }
} 
