//
//  NSMutableURLRequest+StripeTest.swift
//  StripeCoreTests
//
//  Created by Ben Guo on 4/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
import XCTest

class NSMutableURLRequest_StripeTest: XCTestCase {
    func testAddParametersToURL_noQuery() {
        var request: URLRequest?
        if let url = URL(string: "https://example.com") {
            request = URLRequest(url: url)
        }
        request?.stp_addParameters(toURL: [
            "foo": "bar",
        ])

        XCTAssertEqual(request?.url?.absoluteString, "https://example.com?foo=bar")
    }

    func testAddParametersToURL_hasQuery() {
        var request: URLRequest?
        if let url = URL(string: "https://example.com?a=b") {
            request = URLRequest(url: url)
        }
        request?.stp_addParameters(toURL: [
            "foo": "bar",
        ])

        XCTAssertEqual(request?.url?.absoluteString, "https://example.com?a=b&foo=bar")
    }

    func testAddParametersToURL_iOS17UrlEncoding() {
        var request: URLRequest?
        if let url = URL(string: "https://example.com") {
            request = URLRequest(url: url)
        }

        request?.stp_addParameters(toURL: params)
        let cert0: String = params["certificates"]!["0"]!
        let cert1: String = params["certificates"]!["1"]!
        // Should succeed when running on iOS 16 *and* iOS 17:
        XCTAssertEqual(
            request?.url?.absoluteString.removingPercentEncoding,
            "https://example.com?certificates[0]=\(cert0)&certificates[1]=\(cert1)"
        )
    }

    let params = ["certificates": [
      "0": "MIID/jCCA6OgAwIBAgIINITLaqFSgg4wCgYIKoZIzj0EAwIwgYAxNDAyBgNVBAMMK0FwcGxlIFdvcmxkd2lkZSBEZXZlbG9wZXIgUmVsYXRpb25zIENBIC0gRzIxJjAkBgNVBAsMHUFwcGxlIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MRMwEQYDVQQKDApBcHBsZSBJbmMuMQswCQYDVQQGEwJVUzAeFw0yMjA2MDYxNzUyNDNaFw0yNDA3MDUxNzUyNDJaMGwxMjAwBgNVBAMMKWVjYy1jcnlwdG8tc2VydmljZXMtZW5jaXBoZXJtZW50X1VDNi1QUk9EMRQwEgYDVQQLDAtpT1MgU3lzdGVtczETMBEGA1UECgwKQXBwbGUgSW5jLjELMAkGA1UEBhMCVVMwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAASzCVyQGX3syyW2aI6nyfNQe+vjjzjU4rLO0ZiWiVZZSmEzYfACFI8tuDFiDLv9XWrHEeX0/yNtGVjwAzpanWb/o4ICGDCCAhQwDAYDVR0TAQH/BAIwADAfBgNVHSMEGDAWgBSEtoTMOoZichZZlOgao71I3zrfCzBHBggrBgEFBQcBAQQ7MDkwNwYIKwYBBQUHMAGGK2h0dHA6Ly9vY3NwLmFwcGxlLmNvbS9vY3NwMDMtYXBwbGV3d2RyY2EyMDUwggEdBgNVHSAEggEUMIIBEDCCAQwGCSqGSIb3Y2QFATCB/jCBwwYIKwYBBQUHAgIwgbYMgbNSZWxpYW5jZSBvbiB0aGlzIGNlcnRpZmljYXRlIGJ5IGFueSBwYXJ0eSBhc3N1bWVzIGFjY2VwdGFuY2Ugb2YgdGhlIHRoZW4gYXBwbGljYWJsZSBzdGFuZGFyZCB0ZXJtcyBhbmQgY29uZGl0aW9ucyBvZiB1c2UsIGNlcnRpZmljYXRlIHBvbGljeSBhbmQgY2VydGlmaWNhdGlvbiBwcmFjdGljZSBzdGF0ZW1lbnRzLjA2BggrBgEFBQcCARYqaHR0cDovL3d3dy5hcHBsZS5jb20vY2VydGlmaWNhdGVhdXRob3JpdHkvMDYGA1UdHwQvMC0wK6ApoCeGJWh0dHA6Ly9jcmwuYXBwbGUuY29tL2FwcGxld3dkcmNhMi5jcmwwHQYDVR0OBBYEFI5aYtQKaJCRpvI1Dgh+Ra4x2iCrMA4GA1UdDwEB/wQEAwIDKDASBgkqhkiG92NkBicBAf8EAgUAMAoGCCqGSM49BAMCA0kAMEYCIQCuAvrEngGgPMtYGvTRXMtYRWlJpkx+u7fpGmEErdkvjwIhANHuZWywt8EtH2jA9csXpMDj8rh0tmOpT5hcL2D14Wh/",
      "1": "MIIC9zCCAnygAwIBAgIIb+/Y9emjp+4wCgYIKoZIzj0EAwIwZzEbMBkGA1UEAwwSQXBwbGUgUm9vdCBDQSAtIEczMSYwJAYDVQQLDB1BcHBsZSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTETMBEGA1UECgwKQXBwbGUgSW5jLjELMAkGA1UEBhMCVVMwHhcNMTQwNTA2MjM0MzI0WhcNMjkwNTA2MjM0MzI0WjCBgDE0MDIGA1UEAwwrQXBwbGUgV29ybGR3aWRlIERldmVsb3BlciBSZWxhdGlvbnMgQ0EgLSBHMjEmMCQGA1UECwwdQXBwbGUgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkxEzARBgNVBAoMCkFwcGxlIEluYy4xCzAJBgNVBAYTAlVTMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE3fC3BkvP3XMEE8RDiQOTgPte9nStQmFSWAImUxnIYyIHCVJhysTZV+9tJmiLdJGMxPmAaCj8CWjwENrp0C7JGqOB9zCB9DBGBggrBgEFBQcBAQQ6MDgwNgYIKwYBBQUHMAGGKmh0dHA6Ly9vY3NwLmFwcGxlLmNvbS9vY3NwMDQtYXBwbGVyb290Y2FnMzAdBgNVHQ4EFgQUhLaEzDqGYnIWWZToGqO9SN863wswDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBS7sN6hWDOImqSKmd6+veuv2sskqzA3BgNVHR8EMDAuMCygKqAohiZodHRwOi8vY3JsLmFwcGxlLmNvbS9hcHBsZXJvb3RjYWczLmNybDAOBgNVHQ8BAf8EBAMCAQYwEAYKKoZIhvdjZAYCDwQCBQAwCgYIKoZIzj0EAwIDaQAwZgIxANmxxzHGI/ZPTdDZR8V9GGkRh3En02it4Jtlmr5s3z9GppAJvm6hOyywUYlBPIfSvwIxAPxkUolLPF2/axzCiZgvcq61m6oaCyNUd1ToFUOixRLal1BzfF7QbrJcYlDXUfE6Wg==",
    ],
    ]
}
