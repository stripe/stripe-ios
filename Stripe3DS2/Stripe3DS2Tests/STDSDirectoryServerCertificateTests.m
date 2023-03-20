//
//  STDSDirectoryServerCertificateTests.m
//  Stripe3DS2Tests
//
//  Created by Cameron Sabol on 3/28/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STDSDirectoryServerCertificate+Internal.h"
#import "STDSJSONWebSignature.h"
#import "NSString+JWEHelpers.h"

@interface STDSDirectoryServerCertificateTests : XCTestCase

@end

@implementation STDSDirectoryServerCertificateTests

- (void)testCertificateForDirectoryServer {
    NSArray<NSNumber *> *directoryServers = @[
        @(STDSDirectoryServerULTestRSA),
        @(STDSDirectoryServerULTestEC),
        @(STDSDirectoryServerSTPTestRSA),
        @(STDSDirectoryServerSTPTestEC),
        @(STDSDirectoryServerAmex),
        @(STDSDirectoryServerDiscover),
        @(STDSDirectoryServerMastercard),
        @(STDSDirectoryServerVisa),
        @(STDSDirectoryServerCustom),
        @(STDSDirectoryServerUnknown),
    ];
    
    for (NSNumber *directoryServerNum in directoryServers) {
        STDSDirectoryServer directoryServer = (STDSDirectoryServer)[directoryServerNum integerValue];
        switch (directoryServer) {
            case STDSDirectoryServerULTestRSA:
            case STDSDirectoryServerULTestEC:
            case STDSDirectoryServerSTPTestRSA:
            case STDSDirectoryServerSTPTestEC:
            case STDSDirectoryServerAmex:
            case STDSDirectoryServerCartesBancaires:
            case STDSDirectoryServerDiscover:
            case STDSDirectoryServerMastercard:
            case STDSDirectoryServerVisa:
                XCTAssertNotNil([STDSDirectoryServerCertificate certificateForDirectoryServer:directoryServer], @"Failed creating certificate for type %@", directoryServerNum);
                break;
                
            case STDSDirectoryServerCustom:
            case STDSDirectoryServerUnknown:
                XCTAssertNil([STDSDirectoryServerCertificate certificateForDirectoryServer:directoryServer], @"Should return nil for STDSDirectoryServerUnknown");
                break;
        }
    }
}

- (void)testKeyType {
    NSArray<NSNumber *> *directoryServers = @[
        @(STDSDirectoryServerULTestRSA),
        @(STDSDirectoryServerULTestEC),
        @(STDSDirectoryServerSTPTestRSA),
        @(STDSDirectoryServerSTPTestEC),
        @(STDSDirectoryServerAmex),
        @(STDSDirectoryServerCartesBancaires),
        @(STDSDirectoryServerDiscover),
        @(STDSDirectoryServerMastercard),
        @(STDSDirectoryServerVisa),
        @(STDSDirectoryServerCustom),
        @(STDSDirectoryServerUnknown),
    ];
    
    for (NSNumber *directoryServerNum in directoryServers) {
        STDSDirectoryServer directoryServer = (STDSDirectoryServer)[directoryServerNum integerValue];
        STDSDirectoryServerCertificate *certificate = [STDSDirectoryServerCertificate certificateForDirectoryServer:directoryServer];
        switch (directoryServer) {
            case STDSDirectoryServerULTestRSA:
                XCTAssertEqual(certificate.keyType, STDSDirectoryServerKeyTypeRSA, @"Incorrect key type for STDSDirectoryServerULTestRSA");
                break;
                
            case STDSDirectoryServerULTestEC:
                XCTAssertEqual(certificate.keyType, STDSDirectoryServerKeyTypeEC, @"Incorrect key type for STDSDirectoryServerULTestEC");
                break;
                
            case STDSDirectoryServerSTPTestRSA:
                XCTAssertEqual(certificate.keyType, STDSDirectoryServerKeyTypeRSA, @"Incorrect key type for STDSDirectoryServerSTPTestRSA");
                break;
                
            case STDSDirectoryServerSTPTestEC:
                XCTAssertEqual(certificate.keyType, STDSDirectoryServerKeyTypeEC, @"Incorrect key type for STDSDirectoryServerSTPTestEC");
                break;
                
            case STDSDirectoryServerAmex:
                XCTAssertEqual(certificate.keyType, STDSDirectoryServerKeyTypeRSA, @"Incorrect key type for STDSDirectoryServerAmex");
                break;
                
            case STDSDirectoryServerCartesBancaires:
                XCTAssertEqual(certificate.keyType, STDSDirectoryServerKeyTypeRSA, @"Incorrect key type for STDSDirectoryServerCartesBancaires");
                break;
                
            case STDSDirectoryServerDiscover:
                XCTAssertEqual(certificate.keyType, STDSDirectoryServerKeyTypeRSA, @"Incorrect key type for STDSDirectoryServerDiscover");
                break;
                
            case STDSDirectoryServerMastercard:
                XCTAssertEqual(certificate.keyType, STDSDirectoryServerKeyTypeRSA, @"Incorrect key type for STDSDirectoryServerMastercard");
                break;
                
            case STDSDirectoryServerVisa:
                XCTAssertEqual(certificate.keyType, STDSDirectoryServerKeyTypeRSA, @"Incorrect key type for STDSDirectoryServerVisa");
                break;
                
            case STDSDirectoryServerCustom:
            case STDSDirectoryServerUnknown:
                // asserts
                break;
        }
    }
}

- (void)testRSA_OAEP_SHA256Encryption {
    STDSDirectoryServerCertificate *certificate = [STDSDirectoryServerCertificate certificateForDirectoryServer:STDSDirectoryServerSTPTestRSA];
    if (certificate != nil) {
        
        XCTAssertNotNil([certificate encryptDataUsingRSA_OAEP_SHA256:[@"In nature's infinite book of secrecy a little I can read." dataUsingEncoding:NSUTF8StringEncoding]]);
    } else {
        XCTFail(@"Failed loading certificate for %@", NSStringFromSelector(_cmd));
    }
}

- (void)testCustomCertificate {
    NSString *certificateString = @"MIIDXTCCAkWgAwIBAgIQbS4C4BSig7uuJ5uDpeT4VjANBgkqhkiG9w0BAQsFADBH"
    "MRMwEQYKCZImiZPyLGQBGRYDY29tMRcwFQYKCZImiZPyLGQBGRYHZXhhbXBsZTEX"
    "MBUGA1UEAwwOUlNBIEV4YW1wbGUgRFMwHhcNMTcxMTIxMTE0ODQ5WhcNMjcxMjMx"
    "MTQwMDAwWjBHMRMwEQYKCZImiZPyLGQBGRYDY29tMRcwFQYKCZImiZPyLGQBGRYH"
    "ZXhhbXBsZTEXMBUGA1UEAwwOUlNBIEV4YW1wbGUgRFMwggEiMA0GCSqGSIb3DQEB"
    "AQUAA4IBDwAwggEKAoIBAQCfgQ+0A4Jz0CWR5Ac/MdK2ABuCzttNkvBQFl1Hz8q4"
    "o8Qct3isdVN5P475dXaNGiN02HElZMO813uepDRUSJlAfP8AmZIKkxokxEFIUqsp"
    "vbCpXAZT82xg5gv5C2JY3aVvNwR7pcLR0CmvnJ1AuseqQceKDdEGit1pnoCP6gEe"
    "oUQdik97tOl7459V8d3UTpxLozUVlwPU00tgPmUUek8j1tPAmWx17e6EaoLRkK4Q"
    "eDyWHPA4eu0hBtLQVVtv2Tf61VNTh+D/cv++eJQUArC4IuoqdLYFjB2r+bNKdstj"
    "uH+qLGhHuOKDf/+RGG5rHBSRHPmJqJCSqBzmAd2s0/nPAgMBAAGjRTBDMBIGA1Ud"
    "EwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgEGMB0GA1UdDgQWBBTDgwKdvAPq"
    "bbCmehDaw0PwavI83jANBgkqhkiG9w0BAQsFAAOCAQEAOUcKqpzNQ6lr0PbDSsns"
    "D6onfi+8j3TD0xG0zBSf+8G4zs8Zb6vzzQ5qHKgfr4aeen8Pw0cw2KKUJ2dFaBqj"
    "n3/6/MIZbgaBvXKUbmY8xCxKQ+tOFc3KWIu4pSaO50tMPJjU/lP35bv19AA9vs9M"
    "TKY2qLf88bmoNYT3W8VSDcB58KBHa7HVIPx7BUUtSyb2N2Jqx5AOiYy4NarhB3hV"
    "ftkZBmCzi2Qw50KWIgTFYcIVeRTx3Js/F0IuEdgZHBK2gmO7fdM7+QKYm83401vl"
    "YRNCXfIZ0H9E1V3NddqJuqIutdUajckSzMhXdNCJqfI4FAQAymTWGL3/lZyr/30x"
    "Fg==";
    
    STDSDirectoryServerCertificate *certificate = [STDSDirectoryServerCertificate customCertificateWithData:[[NSData alloc] initWithBase64EncodedString:certificateString options:0]];
    XCTAssertNotNil(certificate, @"Failed to create certificate from string.");
    XCTAssertEqual(certificate.keyType, STDSDirectoryServerKeyTypeRSA, @"Parsed incorrect key type from custom certificate");
}

- (void)testCustomCertificateWithString {
    // Using ds-amex.pm.PEM
    NSString *certificateString = @"MIIE0TCCA7mgAwIBAgIUXbeqM1duFcHk4dDBwT8o7Ln5wX8wDQYJKoZIhvcNAQEL"
    "BQAwXjELMAkGA1UEBhMCVVMxITAfBgNVBAoTGEFtZXJpY2FuIEV4cHJlc3MgQ29t"
    "cGFueTEsMCoGA1UEAxMjQW1lcmljYW4gRXhwcmVzcyBTYWZla2V5IElzc3Vpbmcg"
    "Q0EwHhcNMTgwMjIxMjM0OTMxWhcNMjAwMjIxMjM0OTMwWjCB0DELMAkGA1UEBhMC"
    "VVMxETAPBgNVBAgTCE5ldyBZb3JrMREwDwYDVQQHEwhOZXcgWW9yazE/MD0GA1UE"
    "ChM2QW1lcmljYW4gRXhwcmVzcyBUcmF2ZWwgUmVsYXRlZCBTZXJ2aWNlcyBDb21w"
    "YW55LCBJbmMuMTkwNwYDVQQLEzBHbG9iYWwgTmV0d29yayBUZWNobm9sb2d5IC0g"
    "TmV0d29yayBBUEkgUGxhdGZvcm0xHzAdBgNVBAMTFlNESy5TYWZlS2V5LkVuY3J5"
    "cHRLZXkwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDSFF9kTYbwRrxX"
    "C6WcJJYio5TZDM62+CnjQRfggV3GMI+xIDtMIN8LL/jbWBTycu97vrNjNNv+UPhI"
    "WzhFDdUqyRfrY337A39uE8k1xhdDI3dNeZz6xgq8r9hn2NBou78YPBKidpN5oiHn"
    "TxcFq1zudut2fmaldaa9a4ZKgIQo+02heiJfJ8XNWkoWJ17GcjJ59UU8C1KF/y1G"
    "ymYO5ha2QRsVZYI17+ZFsqnpcXwK4Mr6RQKV6UimmO0nr5++CgvXfekcWAlLV6Xq"
    "juACWi3kw0haepaX/9qHRu1OSyjzWNcSVZ0On6plB5Lq6Y9ylgmxDrv+zltz3MrT"
    "K7txIAFFAgMBAAGjggESMIIBDjAMBgNVHRMBAf8EAjAAMCEGA1UdEQQaMBiCFlNE"
    "Sy5TYWZlS2V5LkVuY3J5cHRLZXkwRQYJKwYBBAGCNxQCBDgeNgBBAE0ARQBYAF8A"
    "UwBBAEYARQBLAEUAWQAyAF8ARABTAF8ARQBOAEMAUgBZAFAAVABJAE8ATjAOBgNV"
    "HQ8BAf8EBAMCBJAwHwYDVR0jBBgwFoAU7k/rXuVMhTBxB1zSftPgmLFuDIgwRAYD"
    "VR0fBD0wOzA5oDegNYYzaHR0cDovL2FtZXhzay5jcmwuY29tLXN0cm9uZy1pZC5u"
    "ZXQvYW1leHNhZmVrZXkuY3JsMB0GA1UdDgQWBBQHclVTo5nwZGH8labJ2F2P45xi"
    "fDANBgkqhkiG9w0BAQsFAAOCAQEAWY6b77VBoGLs3k5vOqSU7QRqT+4v6y77T8LA"
    "BKrSZ58DiVZWVyDSxyftQUiRRgFHt2gTN0yfJTP50Fyp84nCEWC0tugZ4iIhgPss"
    "HzL+4/u4eG/MTzK2ESxvPgr6YHajyuU+GXA89u8+bsFrFmojOjhTgFKli7YUeV/0"
    "xoiYZf2utlns800ofJrcrfiFoqE6PvK4Od0jpeMgfSKv71nK5ihA1+wTk76ge1fs"
    "PxL23hEdRpWW11ofaLfJGkLFXMM3/LHSXWy7HhsBgDELdzLSHU4VkSv8yTOZxsRO"
    "ByxdC5v3tXGcK56iQdtKVPhFGOOEBugw7AcuRzv3f1GhvzAQZg==";
    STDSDirectoryServerCertificate *certificate = certificate = [STDSDirectoryServerCertificate customCertificateWithString:certificateString];
    XCTAssertNotNil(certificate, @"Failed to create certificate from string.");
    XCTAssertEqual(certificate.keyType, STDSDirectoryServerKeyTypeRSA, @"Parsed incorrect key type from custom certificate");
    
    // 3ds2.rsa.encryption.crt
    certificateString = @"-----BEGIN CERTIFICATE-----"
    "MIIFrjCCBJagAwIBAgIQB2rJmsHVwbONd36WP9QPrTANBgkqhkiG9w0BAQsFADBx"
    "MQswCQYDVQQGEwJVUzENMAsGA1UEChMEVklTQTEvMC0GA1UECxMmVmlzYSBJbnRl"
    "cm5hdGlvbmFsIFNlcnZpY2UgQXNzb2NpYXRpb24xIjAgBgNVBAMTGVZpc2EgZUNv"
    "bW1lcmNlIElzc3VpbmcgQ0EwHhcNMTcxMTAyMjIyMzEwWhcNMjAxMTAzMDAyMzEw"
    "WjCBoTEYMBYGA1UEBxMPSGlnaGxhbmRzIFJhbmNoMREwDwYDVQQIEwhDb2xvcmFk"
    "bzELMAkGA1UEBhMCVVMxDTALBgNVBAoTBFZJU0ExLzAtBgNVBAsTJlZpc2EgSW50"
    "ZXJuYXRpb25hbCBTZXJ2aWNlIEFzc29jaWF0aW9uMSUwIwYDVQQDExwzZHMyLnJz"
    "YS5lbmNyeXB0aW9uLnZpc2EuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB"
    "CgKCAQEAst+HGfPPsX3p6HHEQ9YzourlQj16Nscmm13Cp7cZe4dZB2oWnJqZ7oh/"
    "pEoEoOAxBw1x4NFgXKTKdHAeu3VBNVw8SwMTdIC+X16VV+3VIyPbUvJXFp3QoR8W"
    "UwPB3F1Lb9SMFNS95boYDZKIOdPW0cP1dRi7pFugsBUZDCP/H3nFfBFHMCBoga+P"
    "3AHGj5y8RVpv0hS9jaIsYjX+i58B61OGCB7D0AiADNZJuFzw2+xpNkt6NJJF66FP"
    "O8qIh8xR2xGVDf7TtCbss/CugLRgSqKab9YRB8/TBTcy5bxj6O8HD6aL2zGLcMY9"
    "dCobXxCodLEtMjJdVL8N+iZrsI2gtwIDAQABo4ICDzCCAgswEwYDVR0lBAwwCgYI"
    "KwYBBQUHAwEwZQYIKwYBBQUHAQEEWTBXMCUGCCsGAQUFBzABhhlodHRwOi8vb2Nz"
    "cC52aXNhLmNvbS9vY3NwMC4GCCsGAQUFBzAChiJodHRwOi8vZW5yb2xsLnZpc2Fj"
    "YS5jb20vZWNvbW0uY2VyMB8GA1UdIwQYMBaAFN/DKlUuL0I6ekCdkqD3R3nXj4eK"
    "MAwGA1UdEwEB/wQCMAAwgcoGA1UdHwSBwjCBvzAooCagJIYiaHR0cDovL0Vucm9s"
    "bC52aXNhY2EuY29tL2VDb21tLmNybDCBkqCBj6CBjIaBiWxkYXA6Ly9FbnJvbGwu"
    "dmlzYWNhLmNvbTozODkvY249VmlzYSBlQ29tbWVyY2UgSXNzdWluZyBDQSxjPVVT"
    "LG91PVZpc2EgSW50ZXJuYXRpb25hbCBTZXJ2aWNlIEFzc29jaWF0aW9uLG89VklT"
    "QT9jZXJ0aWZpY2F0ZVJldm9jYXRpb25MaXN0MA4GA1UdDwEB/wQEAwIFoDAnBgNV"
    "HREEIDAeghwzZHMyLnJzYS5lbmNyeXB0aW9uLnZpc2EuY29tMB0GA1UdDgQWBBT8"
    "m2pDtUtY13f/3NCOmexHavP5zDA5BgNVHSAEMjAwMC4GBWeBAwEBMCUwIwYIKwYB"
    "BQUHAgEWF2h0dHA6Ly93d3cudmlzYS5jb20vcGtpMA0GCSqGSIb3DQEBCwUAA4IB"
    "AQCcCUhU7KnHUDuLXqwSuzC8lWWCcEqPRgPPzY3mgBUg9ya0p+v7QF2BG77tpygK"
    "E2yDPkOE8trzYeMi7TCuvKgZvUXDSOka8SId9QleMBlo2pzNi0vKKBG8+E7qmGaf"
    "etQHVaoFvhg24/e7y8q89VYNKfLXn8TWMUOJdTQoNP+4bHcCnBvWWUcI2LlyEog1"
    "2FDSG8hgP3cpw+0B2Hace9BQGR7ZgTIJAANEHZ54QGOYdxZEcDS5IEpKZlN8INs/"
    "NKJyCkqP09VA4NO/WHaGFAXtgoLmjlA9Kal+4ieJPKijVDxcHVv/uPSfVQJ0/vCa"
    "udJGOXV9q4VteupwLxfOGW8w"
    "-----END CERTIFICATE-----";
    
    certificateString = @"-----BEGIN CERTIFICATE-----\n"
    "MIIFrjCCBJagAwIBAgIQB2rJmsHVwbONd36WP9QPrTANBgkqhkiG9w0BAQsFADBx\n"
    "MQswCQYDVQQGEwJVUzENMAsGA1UEChMEVklTQTEvMC0GA1UECxMmVmlzYSBJbnRl\n"
    "cm5hdGlvbmFsIFNlcnZpY2UgQXNzb2NpYXRpb24xIjAgBgNVBAMTGVZpc2EgZUNv\n"
    "bW1lcmNlIElzc3VpbmcgQ0EwHhcNMTcxMTAyMjIyMzEwWhcNMjAxMTAzMDAyMzEw\n"
    "WjCBoTEYMBYGA1UEBxMPSGlnaGxhbmRzIFJhbmNoMREwDwYDVQQIEwhDb2xvcmFk\n"
    "bzELMAkGA1UEBhMCVVMxDTALBgNVBAoTBFZJU0ExLzAtBgNVBAsTJlZpc2EgSW50\n"
    "ZXJuYXRpb25hbCBTZXJ2aWNlIEFzc29jaWF0aW9uMSUwIwYDVQQDExwzZHMyLnJz\n"
    "YS5lbmNyeXB0aW9uLnZpc2EuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB\n"
    "CgKCAQEAst+HGfPPsX3p6HHEQ9YzourlQj16Nscmm13Cp7cZe4dZB2oWnJqZ7oh/\n"
    "pEoEoOAxBw1x4NFgXKTKdHAeu3VBNVw8SwMTdIC+X16VV+3VIyPbUvJXFp3QoR8W\n"
    "UwPB3F1Lb9SMFNS95boYDZKIOdPW0cP1dRi7pFugsBUZDCP/H3nFfBFHMCBoga+P\n"
    "3AHGj5y8RVpv0hS9jaIsYjX+i58B61OGCB7D0AiADNZJuFzw2+xpNkt6NJJF66FP\n"
    "O8qIh8xR2xGVDf7TtCbss/CugLRgSqKab9YRB8/TBTcy5bxj6O8HD6aL2zGLcMY9\n"
    "dCobXxCodLEtMjJdVL8N+iZrsI2gtwIDAQABo4ICDzCCAgswEwYDVR0lBAwwCgYI\n"
    "KwYBBQUHAwEwZQYIKwYBBQUHAQEEWTBXMCUGCCsGAQUFBzABhhlodHRwOi8vb2Nz\n"
    "cC52aXNhLmNvbS9vY3NwMC4GCCsGAQUFBzAChiJodHRwOi8vZW5yb2xsLnZpc2Fj\n"
    "YS5jb20vZWNvbW0uY2VyMB8GA1UdIwQYMBaAFN/DKlUuL0I6ekCdkqD3R3nXj4eK\n"
    "MAwGA1UdEwEB/wQCMAAwgcoGA1UdHwSBwjCBvzAooCagJIYiaHR0cDovL0Vucm9s\n"
    "bC52aXNhY2EuY29tL2VDb21tLmNybDCBkqCBj6CBjIaBiWxkYXA6Ly9FbnJvbGwu\n"
    "dmlzYWNhLmNvbTozODkvY249VmlzYSBlQ29tbWVyY2UgSXNzdWluZyBDQSxjPVVT\n"
    "LG91PVZpc2EgSW50ZXJuYXRpb25hbCBTZXJ2aWNlIEFzc29jaWF0aW9uLG89VklT\n"
    "QT9jZXJ0aWZpY2F0ZVJldm9jYXRpb25MaXN0MA4GA1UdDwEB/wQEAwIFoDAnBgNV\n"
    "HREEIDAeghwzZHMyLnJzYS5lbmNyeXB0aW9uLnZpc2EuY29tMB0GA1UdDgQWBBT8\n"
    "m2pDtUtY13f/3NCOmexHavP5zDA5BgNVHSAEMjAwMC4GBWeBAwEBMCUwIwYIKwYB\n"
    "BQUHAgEWF2h0dHA6Ly93d3cudmlzYS5jb20vcGtpMA0GCSqGSIb3DQEBCwUAA4IB\n"
    "AQCcCUhU7KnHUDuLXqwSuzC8lWWCcEqPRgPPzY3mgBUg9ya0p+v7QF2BG77tpygK\n"
    "E2yDPkOE8trzYeMi7TCuvKgZvUXDSOka8SId9QleMBlo2pzNi0vKKBG8+E7qmGaf\n"
    "etQHVaoFvhg24/e7y8q89VYNKfLXn8TWMUOJdTQoNP+4bHcCnBvWWUcI2LlyEog1\n"
    "2FDSG8hgP3cpw+0B2Hace9BQGR7ZgTIJAANEHZ54QGOYdxZEcDS5IEpKZlN8INs/\n"
    "NKJyCkqP09VA4NO/WHaGFAXtgoLmjlA9Kal+4ieJPKijVDxcHVv/uPSfVQJ0/vCa\n"
    "udJGOXV9q4VteupwLxfOGW8w\n"
    "-----END CERTIFICATE-----\n";
    certificate = [STDSDirectoryServerCertificate customCertificateWithString:certificateString];
    XCTAssertNotNil(certificate, @"Failed to create certificate from string.");
    XCTAssertEqual(certificate.keyType, STDSDirectoryServerKeyTypeRSA, @"Parsed incorrect key type from custom certificate");
    
    certificateString = @"-----BEGIN CERTIFICATE-----"
    "-----END CERTIFICATE-----";
    certificate = [STDSDirectoryServerCertificate customCertificateWithString:certificateString];
    XCTAssertNil(certificate, @"Should not return a valid value with only anchors");
    XCTAssertEqual(certificate.keyType, STDSDirectoryServerKeyTypeRSA, @"Parsed incorrect key type from custom certificate");
    certificateString = @"-----END CERTIFICATE-----";
    
    certificate = [STDSDirectoryServerCertificate customCertificateWithString:certificateString];
    XCTAssertNil(certificate, @"Should not return a valid value with only suffix anchor");
    XCTAssertEqual(certificate.keyType, STDSDirectoryServerKeyTypeRSA, @"Parsed incorrect key type from custom certificate");
}

- (void)testCertificateChainValidation {
    // ref. EMVCo_3DS_-AppBased_CryptoExamples_082018.pdf
    NSString *certificateString = @"MIIDXTCCAkWgAwIBAgIQbS4C4BSig7uuJ5uDpeT4VjANBgkqhkiG9w0BAQsFADBH"
    "MRMwEQYKCZImiZPyLGQBGRYDY29tMRcwFQYKCZImiZPyLGQBGRYHZXhhbXBsZTEX"
    "MBUGA1UEAwwOUlNBIEV4YW1wbGUgRFMwHhcNMTcxMTIxMTE0ODQ5WhcNMjcxMjMx"
    "MTQwMDAwWjBHMRMwEQYKCZImiZPyLGQBGRYDY29tMRcwFQYKCZImiZPyLGQBGRYH"
    "ZXhhbXBsZTEXMBUGA1UEAwwOUlNBIEV4YW1wbGUgRFMwggEiMA0GCSqGSIb3DQEB"
    "AQUAA4IBDwAwggEKAoIBAQCfgQ+0A4Jz0CWR5Ac/MdK2ABuCzttNkvBQFl1Hz8q4"
    "o8Qct3isdVN5P475dXaNGiN02HElZMO813uepDRUSJlAfP8AmZIKkxokxEFIUqsp"
    "vbCpXAZT82xg5gv5C2JY3aVvNwR7pcLR0CmvnJ1AuseqQceKDdEGit1pnoCP6gEe"
    "oUQdik97tOl7459V8d3UTpxLozUVlwPU00tgPmUUek8j1tPAmWx17e6EaoLRkK4Q"
    "eDyWHPA4eu0hBtLQVVtv2Tf61VNTh+D/cv++eJQUArC4IuoqdLYFjB2r+bNKdstj"
    "uH+qLGhHuOKDf/+RGG5rHBSRHPmJqJCSqBzmAd2s0/nPAgMBAAGjRTBDMBIGA1Ud"
    "EwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgEGMB0GA1UdDgQWBBTDgwKdvAPq"
    "bbCmehDaw0PwavI83jANBgkqhkiG9w0BAQsFAAOCAQEAOUcKqpzNQ6lr0PbDSsns"
    "D6onfi+8j3TD0xG0zBSf+8G4zs8Zb6vzzQ5qHKgfr4aeen8Pw0cw2KKUJ2dFaBqj"
    "n3/6/MIZbgaBvXKUbmY8xCxKQ+tOFc3KWIu4pSaO50tMPJjU/lP35bv19AA9vs9M"
    "TKY2qLf88bmoNYT3W8VSDcB58KBHa7HVIPx7BUUtSyb2N2Jqx5AOiYy4NarhB3hV"
    "ftkZBmCzi2Qw50KWIgTFYcIVeRTx3Js/F0IuEdgZHBK2gmO7fdM7+QKYm83401vl"
    "YRNCXfIZ0H9E1V3NddqJuqIutdUajckSzMhXdNCJqfI4FAQAymTWGL3/lZyr/30x"
    "Fg==";
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-string-concatenation"
    // ref. EMVCo_3DS_-AppBased_CryptoExamples_082018.pdf
    NSArray<NSString *> *certChain = @[@"MIIDeTCCAmGgAwIBAgIQbS4C4BSig7uuJ5uDpeT4WDANB"
                                       "gkqhkiG9w0BAQsFADBHMRMwEQYKCZImiZPyLGQBGRYDY29tMRcwFQYKCZImiZPyLGQBG"
                                       "RYHZXhhbXBsZTEXMBUGA1UEAwwOUlNBIEV4YW1wbGUgRFMwHhcNMTcxMTIxMTE1NDAyW"
                                       "hcNMjcxMjMxMTMzMDAwWjBIMRMwEQYKCZImiZPyLGQBGRYDY29tMRcwFQYKCZImiZPyL"
                                       "GQBGRYHZXhhbXBsZTEYMBYGA1UEAwwPUlNBIEV4YW1wbGUgQUNTMIIBIjANBgkqhkiG9"
                                       "w0BAQEFAAOCAQ8AMIIBCgKCAQEAkNrPIBDXMU6fcyv5i+QHQAQ+K8gsC3HJb7FYhYaw8"
                                       "hXbNJa+t8q0lDKwLZgQXYV+ffWxXJv5GGrlZE4GU52lfMEegTDzYTrRQ3tepgKFjMGg6"
                                       "Iy6fkl1ZNsx2gEonsnlShfzA9GJwRTmtKPbk1s+hwx1IU5AT+AIelNqBgcF2vE5W25/S"
                                       "GGBoaROVdUYxqETDggM1z5cKV4ZjDZ8+lh4oVB07bkac6LQdHpJUUySH/Er20DXx30Ky"
                                       "i97PciXKTS+QKXnmm8ivyRCmux22ZoPUind2BKC5OiG4MwALhaL2Z2k8CsRdfy+7dg7z"
                                       "41Rp6D0ZeEvtaUp4bX4aKraL4rTfwIDAQABo2AwXjAMBgNVHRMBAf8EAjAAMA4GA1UdD"
                                       "wEB/wQEAwIHgDAdBgNVHQ4EFgQUktwf6ZpTCxjYKw/BLW6PeiNX4swwHwYDVR0jBBgwF"
                                       "oAUw4MCnbwD6m2wpnoQ2sND8GryPN4wDQYJKoZIhvcNAQELBQADggEBAGuNHxv/BR6j7"
                                       "lCPysm1uhrbjBOqdrhJMR/Id4dB2GtdEScl3irGPmXyQ2SncTWhNfsgsKDZWp5Bk7+Ot"
                                       "nty0eNUMk3hZEqgYjxhzau048XHbsfGvoJaMGZZNTwUvTUz2hkkhgpx9yQAKIA2LzFKc"
                                       "gYhelPu4GW5rtEuxu3IS6WYy3D1GtF3naEWkjUra8hQOhOl2S+CYHmRd6lGkXykVDajM"
                                       "gd2AJFzXdKLxTt0OYrWDGlUSzGACRBCd5xbRmATIldtccaGqDN1cNWv0I/bPN8EpKS6B"
                                       "0WaZcPasItKWpDC85Jw1GrDxdhwoKHoxtSG+odiTwB5zLbrn2OsRE5bV7E="];
#pragma clang diagnostic pop
    
    XCTAssertTrue([STDSDirectoryServerCertificate _verifyCertificateChain:certChain withRootCertificates:@[certificateString]], @"Failed to verify certificate chain.");
    certChain = @[@"junk_data", @"more_junk"];
    XCTAssertFalse([STDSDirectoryServerCertificate _verifyCertificateChain:certChain withRootCertificates:@[certificateString]], @"Verified certificate chain with invalid certificates.");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-string-concatenation"
    // Test with valid certificates in the chain, but that are not related to the root certificate
    // ref. https://tools.ietf.org/html/rfc7515
    certChain = @[
        @"MIIE3jCCA8agAwIBAgICAwEwDQYJKoZIhvcNAQEFBQAwYzELMAkGA1UEBhMCVVM"
        "xITAfBgNVBAoTGFRoZSBHbyBEYWRkeSBHcm91cCwgSW5jLjExMC8GA1UECxMoR2"
        "8gRGFkZHkgQ2xhc3MgMiBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTAeFw0wNjExM"
        "TYwMTU0MzdaFw0yNjExMTYwMTU0MzdaMIHKMQswCQYDVQQGEwJVUzEQMA4GA1UE"
        "CBMHQXJpem9uYTETMBEGA1UEBxMKU2NvdHRzZGFsZTEaMBgGA1UEChMRR29EYWR"
        "keS5jb20sIEluYy4xMzAxBgNVBAsTKmh0dHA6Ly9jZXJ0aWZpY2F0ZXMuZ29kYW"
        "RkeS5jb20vcmVwb3NpdG9yeTEwMC4GA1UEAxMnR28gRGFkZHkgU2VjdXJlIENlc"
        "nRpZmljYXRpb24gQXV0aG9yaXR5MREwDwYDVQQFEwgwNzk2OTI4NzCCASIwDQYJ"
        "KoZIhvcNAQEBBQADggEPADCCAQoCggEBAMQt1RWMnCZM7DI161+4WQFapmGBWTt"
        "wY6vj3D3HKrjJM9N55DrtPDAjhI6zMBS2sofDPZVUBJ7fmd0LJR4h3mUpfjWoqV"
        "Tr9vcyOdQmVZWt7/v+WIbXnvQAjYwqDL1CBM6nPwT27oDyqu9SoWlm2r4arV3aL"
        "GbqGmu75RpRSgAvSMeYddi5Kcju+GZtCpyz8/x4fKL4o/K1w/O5epHBp+YlLpyo"
        "7RJlbmr2EkRTcDCVw5wrWCs9CHRK8r5RsL+H0EwnWGu1NcWdrxcx+AuP7q2BNgW"
        "JCJjPOq8lh8BJ6qf9Z/dFjpfMFDniNoW1fho3/Rb2cRGadDAW/hOUoz+EDU8CAw"
        "EAAaOCATIwggEuMB0GA1UdDgQWBBT9rGEyk2xF1uLuhV+auud2mWjM5zAfBgNVH"
        "SMEGDAWgBTSxLDSkdRMEXGzYcs9of7dqGrU4zASBgNVHRMBAf8ECDAGAQH/AgEA"
        "MDMGCCsGAQUFBwEBBCcwJTAjBggrBgEFBQcwAYYXaHR0cDovL29jc3AuZ29kYWR"
        "keS5jb20wRgYDVR0fBD8wPTA7oDmgN4Y1aHR0cDovL2NlcnRpZmljYXRlcy5nb2"
        "RhZGR5LmNvbS9yZXBvc2l0b3J5L2dkcm9vdC5jcmwwSwYDVR0gBEQwQjBABgRVH"
        "SAAMDgwNgYIKwYBBQUHAgEWKmh0dHA6Ly9jZXJ0aWZpY2F0ZXMuZ29kYWRkeS5j"
        "b20vcmVwb3NpdG9yeTAOBgNVHQ8BAf8EBAMCAQYwDQYJKoZIhvcNAQEFBQADggE"
        "BANKGwOy9+aG2Z+5mC6IGOgRQjhVyrEp0lVPLN8tESe8HkGsz2ZbwlFalEzAFPI"
        "UyIXvJxwqoJKSQ3kbTJSMUA2fCENZvD117esyfxVgqwcSeIaha86ykRvOe5GPLL"
        "5CkKSkB2XIsKd83ASe8T+5o0yGPwLPk9Qnt0hCqU7S+8MxZC9Y7lhyVJEnfzuz9"
        "p0iRFEUOOjZv2kWzRaJBydTXRE4+uXR21aITVSzGh6O1mawGhId/dQb8vxRMDsx"
        "uxN89txJx9OjxUUAiKEngHUuHqDTMBqLdElrRhjZkAzVvb3du6/KFUJheqwNTrZ"
        "EjYx8WnM25sgVjOuH0aBsXBTWVU+4=",
        @"MIIE+zCCBGSgAwIBAgICAQ0wDQYJKoZIhvcNAQEFBQAwgbsxJDAiBgNVBAcTG1Z"
        "hbGlDZXJ0IFZhbGlkYXRpb24gTmV0d29yazEXMBUGA1UEChMOVmFsaUNlcnQsIE"
        "luYy4xNTAzBgNVBAsTLFZhbGlDZXJ0IENsYXNzIDIgUG9saWN5IFZhbGlkYXRpb"
        "24gQXV0aG9yaXR5MSEwHwYDVQQDExhodHRwOi8vd3d3LnZhbGljZXJ0LmNvbS8x"
        "IDAeBgkqhkiG9w0BCQEWEWluZm9AdmFsaWNlcnQuY29tMB4XDTA0MDYyOTE3MDY"
        "yMFoXDTI0MDYyOTE3MDYyMFowYzELMAkGA1UEBhMCVVMxITAfBgNVBAoTGFRoZS"
        "BHbyBEYWRkeSBHcm91cCwgSW5jLjExMC8GA1UECxMoR28gRGFkZHkgQ2xhc3MgM"
        "iBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTCCASAwDQYJKoZIhvcNAQEBBQADggEN"
        "ADCCAQgCggEBAN6d1+pXGEmhW+vXX0iG6r7d/+TvZxz0ZWizV3GgXne77ZtJ6XC"
        "APVYYYwhv2vLM0D9/AlQiVBDYsoHUwHU9S3/Hd8M+eKsaA7Ugay9qK7HFiH7Eux"
        "6wwdhFJ2+qN1j3hybX2C32qRe3H3I2TqYXP2WYktsqbl2i/ojgC95/5Y0V4evLO"
        "tXiEqITLdiOr18SPaAIBQi2XKVlOARFmR6jYGB0xUGlcmIbYsUfb18aQr4CUWWo"
        "riMYavx4A6lNf4DD+qta/KFApMoZFv6yyO9ecw3ud72a9nmYvLEHZ6IVDd2gWMZ"
        "Eewo+YihfukEHU1jPEX44dMX4/7VpkI+EdOqXG68CAQOjggHhMIIB3TAdBgNVHQ"
        "4EFgQU0sSw0pHUTBFxs2HLPaH+3ahq1OMwgdIGA1UdIwSByjCBx6GBwaSBvjCBu"
        "zEkMCIGA1UEBxMbVmFsaUNlcnQgVmFsaWRhdGlvbiBOZXR3b3JrMRcwFQYDVQQK"
        "Ew5WYWxpQ2VydCwgSW5jLjE1MDMGA1UECxMsVmFsaUNlcnQgQ2xhc3MgMiBQb2x"
        "pY3kgVmFsaWRhdGlvbiBBdXRob3JpdHkxITAfBgNVBAMTGGh0dHA6Ly93d3cudm"
        "FsaWNlcnQuY29tLzEgMB4GCSqGSIb3DQEJARYRaW5mb0B2YWxpY2VydC5jb22CA"
        "QEwDwYDVR0TAQH/BAUwAwEB/zAzBggrBgEFBQcBAQQnMCUwIwYIKwYBBQUHMAGG"
        "F2h0dHA6Ly9vY3NwLmdvZGFkZHkuY29tMEQGA1UdHwQ9MDswOaA3oDWGM2h0dHA"
        "6Ly9jZXJ0aWZpY2F0ZXMuZ29kYWRkeS5jb20vcmVwb3NpdG9yeS9yb290LmNybD"
        "BLBgNVHSAERDBCMEAGBFUdIAAwODA2BggrBgEFBQcCARYqaHR0cDovL2NlcnRpZ"
        "mljYXRlcy5nb2RhZGR5LmNvbS9yZXBvc2l0b3J5MA4GA1UdDwEB/wQEAwIBBjAN"
        "BgkqhkiG9w0BAQUFAAOBgQC1QPmnHfbq/qQaQlpE9xXUhUaJwL6e4+PrxeNYiY+"
        "Sn1eocSxI0YGyeR+sBjUZsE4OWBsUs5iB0QQeyAfJg594RAoYC5jcdnplDQ1tgM"
        "QLARzLrUc+cb53S8wGd9D0VmsfSxOaFIqII6hR8INMqzW/Rn453HWkrugp++85j"
        "09VZw==",
        @"MIIC5zCCAlACAQEwDQYJKoZIhvcNAQEFBQAwgbsxJDAiBgNVBAcTG1ZhbGlDZXJ"
        "0IFZhbGlkYXRpb24gTmV0d29yazEXMBUGA1UEChMOVmFsaUNlcnQsIEluYy4xNT"
        "AzBgNVBAsTLFZhbGlDZXJ0IENsYXNzIDIgUG9saWN5IFZhbGlkYXRpb24gQXV0a"
        "G9yaXR5MSEwHwYDVQQDExhodHRwOi8vd3d3LnZhbGljZXJ0LmNvbS8xIDAeBgkq"
        "hkiG9w0BCQEWEWluZm9AdmFsaWNlcnQuY29tMB4XDTk5MDYyNjAwMTk1NFoXDTE"
        "5MDYyNjAwMTk1NFowgbsxJDAiBgNVBAcTG1ZhbGlDZXJ0IFZhbGlkYXRpb24gTm"
        "V0d29yazEXMBUGA1UEChMOVmFsaUNlcnQsIEluYy4xNTAzBgNVBAsTLFZhbGlDZ"
        "XJ0IENsYXNzIDIgUG9saWN5IFZhbGlkYXRpb24gQXV0aG9yaXR5MSEwHwYDVQQD"
        "ExhodHRwOi8vd3d3LnZhbGljZXJ0LmNvbS8xIDAeBgkqhkiG9w0BCQEWEWluZm9"
        "AdmFsaWNlcnQuY29tMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDOOnHK5a"
        "vIWZJV16vYdA757tn2VUdZZUcOBVXc65g2PFxTXdMwzzjsvUGJ7SVCCSRrCl6zf"
        "N1SLUzm1NZ9WlmpZdRJEy0kTRxQb7XBhVQ7/nHk01xC+YDgkRoKWzk2Z/M/VXwb"
        "P7RfZHM047QSv4dk+NoS/zcnwbNDu+97bi5p9wIDAQABMA0GCSqGSIb3DQEBBQU"
        "AA4GBADt/UG9vUJSZSWI4OB9L+KXIPqeCgfYrx+jFzug6EILLGACOTb2oWH+heQ"
        "C1u+mNr0HZDzTuIYEZoDJJKPTEjlbVUjP9UNV+mWwD5MlM/Mtsq2azSiGM5bUMM"
        "j4QssxsodyamEwCW/POuZ6lcg5Ktz885hZo+L7tdEy8W9ViH0Pd",
        @"MIIDeTCCAmGgAwIBAgIQbS4C4BSig7uuJ5uDpeT4WDANB"
        "gkqhkiG9w0BAQsFADBHMRMwEQYKCZImiZPyLGQBGRYDY29tMRcwFQYKCZImiZPyLGQBG"
        "RYHZXhhbXBsZTEXMBUGA1UEAwwOUlNBIEV4YW1wbGUgRFMwHhcNMTcxMTIxMTE1NDAyW"
        "hcNMjcxMjMxMTMzMDAwWjBIMRMwEQYKCZImiZPyLGQBGRYDY29tMRcwFQYKCZImiZPyL"
        "GQBGRYHZXhhbXBsZTEYMBYGA1UEAwwPUlNBIEV4YW1wbGUgQUNTMIIBIjANBgkqhkiG9"
        "w0BAQEFAAOCAQ8AMIIBCgKCAQEAkNrPIBDXMU6fcyv5i+QHQAQ+K8gsC3HJb7FYhYaw8"
        "hXbNJa+t8q0lDKwLZgQXYV+ffWxXJv5GGrlZE4GU52lfMEegTDzYTrRQ3tepgKFjMGg6"
        "Iy6fkl1ZNsx2gEonsnlShfzA9GJwRTmtKPbk1s+hwx1IU5AT+AIelNqBgcF2vE5W25/S"
        "GGBoaROVdUYxqETDggM1z5cKV4ZjDZ8+lh4oVB07bkac6LQdHpJUUySH/Er20DXx30Ky"
        "i97PciXKTS+QKXnmm8ivyRCmux22ZoPUind2BKC5OiG4MwALhaL2Z2k8CsRdfy+7dg7z"
        "41Rp6D0ZeEvtaUp4bX4aKraL4rTfwIDAQABo2AwXjAMBgNVHRMBAf8EAjAAMA4GA1UdD"
        "wEB/wQEAwIHgDAdBgNVHQ4EFgQUktwf6ZpTCxjYKw/BLW6PeiNX4swwHwYDVR0jBBgwF"
        "oAUw4MCnbwD6m2wpnoQ2sND8GryPN4wDQYJKoZIhvcNAQELBQADggEBAGuNHxv/BR6j7"
        "lCPysm1uhrbjBOqdrhJMR/Id4dB2GtdEScl3irGPmXyQ2SncTWhNfsgsKDZWp5Bk7+Ot"
        "nty0eNUMk3hZEqgYjxhzau048XHbsfGvoJaMGZZNTwUvTUz2hkkhgpx9yQAKIA2LzFKc"
        "gYhelPu4GW5rtEuxu3IS6WYy3D1GtF3naEWkjUra8hQOhOl2S+CYHmRd6lGkXykVDajM"
        "gd2AJFzXdKLxTt0OYrWDGlUSzGACRBCd5xbRmATIldtccaGqDN1cNWv0I/bPN8EpKS6B"
        "0WaZcPasItKWpDC85Jw1GrDxdhwoKHoxtSG+odiTwB5zLbrn2OsRE5bV7E=",];
    XCTAssertFalse([STDSDirectoryServerCertificate _verifyCertificateChain:certChain withRootCertificates:@[certificateString]], @"Verified invalid certificate chain.");
    
    // stripe.com's cert chain retrieved by https://whatsmychaincert.com/
    // If below test cases start failing, the certs may have expired and should be replaced with newer ones
    // from whatsmychaincert.com, select Generate Cert Chain, include root for stripe.com
    // print the entire certificate chain with `openssl crl2pkcs7 -nocrl -certfile  <cert file> | openssl pkcs7 -print_certs -text`
    // The root is the last printed certificate and the cert chain should be ordered with the top most at the end of certChain
    
    certChain = @[
        @"MIIEtjCCA56gAwIBAgIQDHmpRLCMEZUgkmFf4msdgzANBgkqhkiG9w0BAQsFADBs"
        "MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3"
        "d3cuZGlnaWNlcnQuY29tMSswKQYDVQQDEyJEaWdpQ2VydCBIaWdoIEFzc3VyYW5j"
        "ZSBFViBSb290IENBMB4XDTEzMTAyMjEyMDAwMFoXDTI4MTAyMjEyMDAwMFowdTEL"
        "MAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3"
        "LmRpZ2ljZXJ0LmNvbTE0MDIGA1UEAxMrRGlnaUNlcnQgU0hBMiBFeHRlbmRlZCBW"
        "YWxpZGF0aW9uIFNlcnZlciBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC"
        "ggEBANdTpARR+JmmFkhLZyeqk0nQOe0MsLAAh/FnKIaFjI5j2ryxQDji0/XspQUY"
        "uD0+xZkXMuwYjPrxDKZkIYXLBxA0sFKIKx9om9KxjxKws9LniB8f7zh3VFNfgHk/"
        "LhqqqB5LKw2rt2O5Nbd9FLxZS99RStKh4gzikIKHaq7q12TWmFXo/a8aUGxUvBHy"
        "/Urynbt/DvTVvo4WiRJV2MBxNO723C3sxIclho3YIeSwTQyJ3DkmF93215SF2AQh"
        "cJ1vb/9cuhnhRctWVyh+HA1BV6q3uCe7seT6Ku8hI3UarS2bhjWMnHe1c63YlC3k"
        "8wyd7sFOYn4XwHGeLN7x+RAoGTMCAwEAAaOCAUkwggFFMBIGA1UdEwEB/wQIMAYB"
        "Af8CAQAwDgYDVR0PAQH/BAQDAgGGMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEF"
        "BQcDAjA0BggrBgEFBQcBAQQoMCYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRp"
        "Z2ljZXJ0LmNvbTBLBgNVHR8ERDBCMECgPqA8hjpodHRwOi8vY3JsNC5kaWdpY2Vy"
        "dC5jb20vRGlnaUNlcnRIaWdoQXNzdXJhbmNlRVZSb290Q0EuY3JsMD0GA1UdIAQ2"
        "MDQwMgYEVR0gADAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5j"
        "b20vQ1BTMB0GA1UdDgQWBBQ901Cl1qCt7vNKYApl0yHU+PjWDzAfBgNVHSMEGDAW"
        "gBSxPsNpA/i/RwHUmCYaCALvY2QrwzANBgkqhkiG9w0BAQsFAAOCAQEAnbbQkIbh"
        "hgLtxaDwNBx0wY12zIYKqPBKikLWP8ipTa18CK3mtlC4ohpNiAexKSHc59rGPCHg"
        "4xFJcKx6HQGkyhE6V6t9VypAdP3THYUYUN9XR3WhfVUgLkc3UHKMf4Ib0mKPLQNa"
        "2sPIoc4sUqIAY+tzunHISScjl2SFnjgOrWNoPLpSgVh5oywM395t6zHyuqB8bPEs"
        "1OG9d4Q3A84ytciagRpKkk47RpqF/oOi+Z6Mo8wNXrM9zwR4jxQUezKcxwCmXMS1"
        "oVWNWlZopCJwqjyBcdmdqEU79OX2olHdx3ti6G8MdOu42vi/hw15UJGQmxg7kVkn"
        "8TUoE6smftX3eg==",

        @"MIIHQDCCBiigAwIBAgIQD2ygPziYarLZojJGDizjjzANBgkqhkiG9w0BAQsFADB1"
        "MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3"
        "d3cuZGlnaWNlcnQuY29tMTQwMgYDVQQDEytEaWdpQ2VydCBTSEEyIEV4dGVuZGVk"
        "IFZhbGlkYXRpb24gU2VydmVyIENBMB4XDTIxMTAyMDAwMDAwMFoXDTIyMDIwMjIz"
        "NTk1OVowgcYxHTAbBgNVBA8MFFByaXZhdGUgT3JnYW5pemF0aW9uMRMwEQYLKwYB"
        "BAGCNzwCAQMTAlVTMRkwFwYLKwYBBAGCNzwCAQITCERlbGF3YXJlMRAwDgYDVQQF"
        "Ewc0Njc1NTA2MQswCQYDVQQGEwJVUzETMBEGA1UECBMKQ2FsaWZvcm5pYTEWMBQG"
        "A1UEBxMNU2FuIEZyYW5jaXNjbzEUMBIGA1UEChMLU3RyaXBlLCBJbmMxEzARBgNV"
        "BAMTCnN0cmlwZS5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC1"
        "ZyRTERjtA28e16WX4AUBBbXE8YTA6F5RNp5NEy2px6GF2LbjR8TobVfJoj63+CXR"
        "W4uox0TQV526ZnPKbvYpAilYxEc9/fJTPS3lDJ4EgKRZlZ97UrGY8dzOR2aebpw4"
        "xYnN8gYXFHeISG1ieQnnyZUck5HUF1FX3rcWh8y7doNLL9cvIt5+R6yLqeTZkCX3"
        "eIAvANuhdN++nqTM7JoFSViZa8VNQ18wviB5Hw+VWdpZXF9SQmWpP4M7pgDUYTVa"
        "xIsywBiisQBExh5NXEhSAboTtqxmt5IADSQx9E2tp5u3oY2Ql3YRGmYnfe1y7QKD"
        "PdEVMRa4aFod+w9qe2OfAgMBAAGjggN4MIIDdDAfBgNVHSMEGDAWgBQ901Cl1qCt"
        "7vNKYApl0yHU+PjWDzAdBgNVHQ4EFgQUzjnGrO9r9NbeN6cRkzoAtaKNZLowJQYD"
        "VR0RBB4wHIIKc3RyaXBlLmNvbYIOd3d3LnN0cmlwZS5jb20wDgYDVR0PAQH/BAQD"
        "AgWgMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjB1BgNVHR8EbjBsMDSg"
        "MqAwhi5odHRwOi8vY3JsMy5kaWdpY2VydC5jb20vc2hhMi1ldi1zZXJ2ZXItZzMu"
        "Y3JsMDSgMqAwhi5odHRwOi8vY3JsNC5kaWdpY2VydC5jb20vc2hhMi1ldi1zZXJ2"
        "ZXItZzMuY3JsMEoGA1UdIARDMEEwCwYJYIZIAYb9bAIBMDIGBWeBDAEBMCkwJwYI"
        "KwYBBQUHAgEWG2h0dHA6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzCBiAYIKwYBBQUH"
        "AQEEfDB6MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wUgYI"
        "KwYBBQUHMAKGRmh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFNI"
        "QTJFeHRlbmRlZFZhbGlkYXRpb25TZXJ2ZXJDQS5jcnQwDAYDVR0TAQH/BAIwADCC"
        "AX4GCisGAQQB1nkCBAIEggFuBIIBagFoAHYAKXm+8J45OSHwVnOfY6V35b5XfZxg"
        "Cvj5TV0mXCVdx4QAAAF8n1z3KwAABAMARzBFAiAWda1cPqRI3YujJxhh3ahOlUoN"
        "L+bpZFA30lL+L3UB1AIhAIAX2FUC4uyshmrtgnnq7OcmIzsOEVW7LDlFUlfokAbW"
        "AHUAUaOw9f0BeZxWbbg3eI8MpHrMGyfL956IQpoN/tSLBeUAAAF8n1z3JAAABAMA"
        "RjBEAiAPAv+vPLXXB1hB5S+MIrWXIIIsa0u+cPIARVuMEQPz5gIgLbrsj2bNmxYF"
        "mfvwsORC61rCPouzzFkvQGy81lz0L38AdwBByMqx3yJGShDGoToJQodeTjGLGwPr"
        "60vHaPCQYpYG9gAAAXyfXPahAAAEAwBIMEYCIQCdieTsguvk9YFGdpMPsSp4CJYY"
        "1cn1lTiYQQBwzKSqogIhAOyyQKx4fhNqtWOiXUYhPaQtYLS7Ey4TeOlmm7U3OktO"
        "MA0GCSqGSIb3DQEBCwUAA4IBAQBmZNhqh9q/u4hNPX7fPhIXTkHJD+B30kefLTOK"
        "OA/ZlMzGdvrGaJAJNzQzZL0gTEf3x+D9yjOv8shBIfblugTTa/+ulDbSzjM7qrn6"
        "nfojxtLdJ90UvkDCeJ30+Mn+FRahAeLN1jVAgXAUKTgU8QoAM0URZuLh/yWSoMzh"
        "kx9PiDtEJR6DMoVVOPTf9Yk3iUBr//KDzVMbz5aJFDO+2fUjGqVmW+3rapYfealY"
        "LNz/SmaO8S5U4z9A3xkwXSWxlEKkboKvngSdhNgYyPeHTmNKhcmFnnA9q2LvAl9u"
        "UUhp5kZA9EKInRZiVl6i7z1RNhxe2RISbq1MlZi/raZYACt8",
    ];
#pragma clang diagnostic pop
    
    // root
    NSString *rootCertificateString =         @"MIIDxTCCAq2gAwIBAgIQAqxcJmoLQJuPC3nyrkYldzANBgkqhkiG9w0BAQUFADBs"
    "MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3"
    "d3cuZGlnaWNlcnQuY29tMSswKQYDVQQDEyJEaWdpQ2VydCBIaWdoIEFzc3VyYW5j"
    "ZSBFViBSb290IENBMB4XDTA2MTExMDAwMDAwMFoXDTMxMTExMDAwMDAwMFowbDEL"
    "MAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3"
    "LmRpZ2ljZXJ0LmNvbTErMCkGA1UEAxMiRGlnaUNlcnQgSGlnaCBBc3N1cmFuY2Ug"
    "RVYgUm9vdCBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMbM5XPm"
    "+9S75S0tMqbf5YE/yc0lSbZxKsPVlDRnogocsF9ppkCxxLeyj9CYpKlBWTrT3JTW"
    "PNt0OKRKzE0lgvdKpVMSOO7zSW1xkX5jtqumX8OkhPhPYlG++MXs2ziS4wblCJEM"
    "xChBVfvLWokVfnHoNb9Ncgk9vjo4UFt3MRuNs8ckRZqnrG0AFFoEt7oT61EKmEFB"
    "Ik5lYYeBQVCmeVyJ3hlKV9Uu5l0cUyx+mM0aBhakaHPQNAQTXKFx01p8VdteZOE3"
    "hzBWBOURtCmAEvF5OYiiAhF8J2a3iLd48soKqDirCmTCv2ZdlYTBoSUeh10aUAsg"
    "EsxBu24LUTi4S8sCAwEAAaNjMGEwDgYDVR0PAQH/BAQDAgGGMA8GA1UdEwEB/wQF"
    "MAMBAf8wHQYDVR0OBBYEFLE+w2kD+L9HAdSYJhoIAu9jZCvDMB8GA1UdIwQYMBaA"
    "FLE+w2kD+L9HAdSYJhoIAu9jZCvDMA0GCSqGSIb3DQEBBQUAA4IBAQAcGgaX3Nec"
    "nzyIZgYIVyHbIUf4KmeqvxgydkAQV8GK83rZEWWONfqe/EW1ntlMMUu4kehDLI6z"
    "eM7b41N5cdblIZQB2lWHmiRk9opmzN6cN82oNLFpmyPInngiK3BD41VHMWEZ71jF"
    "hS9OMPagMRYjyOfiZRYzy78aG6A9+MpeizGLYAiJLQwGXFK3xPkKmNEVX58Svnw2"
    "Yzi9RKR/5CYrCsSXaQ3pjOLAEFe4yHYSkVXySGnYvCoCWw9E1CAx2/S6cCZdkGCe"
    "vEsXCS+0yx5DaMkHJ8HSXPfqIbloEpw8nL+e/IBcm2PN7EeqJSdnoDfzAIJ9VNep"
    "+OkuE6N36B9K";
    
    // mastercard DS (from mastercard.der)
    NSString *dsCertificateString = @"MIIFtTCCA52gAwIBAgIQJqSRaPua/6cpablmVDHWUDANBgkqhkiG9w0BAQsFADB6"
    "MQswCQYDVQQGEwJVUzETMBEGA1UEChMKTWFzdGVyQ2FyZDEoMCYGA1UECxMfTWFz"
    "dGVyQ2FyZCBJZGVudGl0eSBDaGVjayBHZW4gMzEsMCoGA1UEAxMjUFJEIE1hc3Rl"
    "ckNhcmQgM0RTMiBBY3F1aXJlciBTdWIgQ0EwHhcNMTgxMTIwMTQ1MzIzWhcNMjEx"
    "MTIwMTQ1MzIzWjBxMQswCQYDVQQGEwJVUzEdMBsGA1UEChMUTWFzdGVyQ2FyZCBX"
    "b3JsZHdpZGUxGzAZBgNVBAsTEmdhdGV3YXktZW5jcnlwdGlvbjEmMCQGA1UEAxMd"
    "M2RzMi5kaXJlY3RvcnkubWFzdGVyY2FyZC5jb20wggEiMA0GCSqGSIb3DQEBAQUA"
    "A4IBDwAwggEKAoIBAQCFlZjqbbL9bDKOzZFawdbyfQcezVEUSDCWWsYKw/V6co9A"
    "GaPBUsGgzxF6+EDgVj3vYytgSl8xFvVPsb4ZJ6BJGvimda8QiIyrX7WUxQMB3hyS"
    "BOPf4OB72CP+UkaFNR6hdlO5ofzTmB2oj1FdLGZmTN/sj6ZoHkn2Zzums8QAHFjv"
    "FjspKUYCmms91gpNpJPUUztn0N1YMWVFpFMytahHIlpiGqTDt4314F7sFABLxzFr"
    "Dmcqhf623SPV3kwQiLVWOvewO62ItYUFgHwle2dq76YiKrUv1C7vADSk2Am4gqwv"
    "7dcCnFeM2AHbBFBa1ZBRQXosuXVw8ZcQqfY8m4iNAgMBAAGjggE+MIIBOjAOBgNV"
    "HQ8BAf8EBAMCAygwCQYDVR0TBAIwADAfBgNVHSMEGDAWgBSakqJUx4CN/s5W4wMU"
    "/17uSLhFuzBIBggrBgEFBQcBAQQ8MDowOAYIKwYBBQUHMAGGLGh0dHA6Ly9vY3Nw"
    "LnBraS5pZGVudGl0eWNoZWNrLm1hc3RlcmNhcmQuY29tMCgGA1UdEQQhMB+CHTNk"
    "czIuZGlyZWN0b3J5Lm1hc3RlcmNhcmQuY29tMGkGA1UdHwRiMGAwXqBcoFqGWGh0"
    "dHA6Ly9jcmwucGtpLmlkZW50aXR5Y2hlY2subWFzdGVyY2FyZC5jb20vOWE5MmEy"
    "NTRjNzgwOGRmZWNlNTZlMzAzMTRmZjVlZWU0OGI4NDViYi5jcmwwHQYDVR0OBBYE"
    "FHxN6+P0r3+dFWmi/+pDQ8JWaCbuMA0GCSqGSIb3DQEBCwUAA4ICAQAtwW8siyCi"
    "mhon1WUAUmufZ7bbegf3cTOafQh77NvA0xgVeloELUNCwsSSZgcOIa4Zgpsa0xi5"
    "fYxXsPLgVPLM0mBhTOD1DnPu1AAm32QVelHe6oB98XxbkQlHGXeOLs62PLtDZd94"
    "7pm08QMVb+MoCnHLaBLV6eKhKK+SNrfcxr33m0h3v2EMoiJ6zCvp8HgIHEhVpleU"
    "8H2Uo5YObatb/KUHgtp2z0vEfyGhZR7hrr48vUQpfVGBABsCV0aqUkPxtAXWfQo9"
    "1N9B7H3EIcSjbiUz5vkj9YeDSyJIi0Y/IZbzuNMsz2cRi1CWLl37w2fe128qWxYq"
    "Y/k+Y4HX7uYchB8xPaZR4JczCvg1FV2JrkOcFvElVXWSMpBbe2PS6OMr3XxrHjzp"
    "DyM9qvzge0Ai9+rq8AyGoG1dP2Ay83Ndlgi42X3yl1uEUW2feGojCQQCFFArazEj"
    "LUkSlrB2kA12SWAhsqqQwnBLGSTp7PqPZeWkluQVXS0sbj0878kTra6TjG3U+KqO"
    "JCj8v6G380qIkAXe1xMHHNQ6GS59HZMeBPYkK2y5hmh/JVo4bRfK7Ya3blBSBfB8"
    "AVWQ5GqVWklvXZsQLN7FH/fMIT3y8iE1W19Ua4whlhvn7o/aYWOkHr1G2xyh8BHj"
    "7H63A2hjcPlW/ZAJSTuBZUClAhsNohH2Jg==";
    
    XCTAssertTrue([STDSDirectoryServerCertificate _verifyCertificateChain:certChain withRootCertificates:@[rootCertificateString]], @"Failed to verify w/ root certificate.");
    XCTAssertFalse([STDSDirectoryServerCertificate _verifyCertificateChain:certChain withRootCertificates:@[dsCertificateString]], @"Should not verify w/ DS certificate.");
    NSArray<NSString *> *bothCertificateStrings = @[dsCertificateString, rootCertificateString];
    XCTAssertTrue([STDSDirectoryServerCertificate _verifyCertificateChain:certChain withRootCertificates:bothCertificateStrings], @"Failed to verify w/ root certificate and ds certificate.");
}

- (void)testVerifyPS256Signature {
    // ref. EMVCo_3DS_-AppBased_CryptoExamples_082018.pdf
    NSString *jwsString = @"eyJhbGciOiJQUzI1NiIsIng1YyI6WyJNSUlEZVRDQ0FtR2dBd0lCQWdJUWJTNEM0QlNp"
    "Zzd1dUo1dURwZVQ0V0RBTkJna3Foa2lHOXcwQkFRc0ZBREJITVJNd0VRWUtDWkltaVpQ"
    "eUxHUUJHUllEWTI5dE1SY3dGUVlLQ1pJbWlaUHlMR1FCR1JZSFpYaGhiWEJzWlRFWE1C"
    "VUdBMVVFQXd3T1VsTkJJRVY0WVcxd2JHVWdSRk13SGhjTk1UY3hNVEl4TVRFMU5EQXlX"
    "aGNOTWpjeE1qTXhNVE16TURBd1dqQklNUk13RVFZS0NaSW1pWlB5TEdRQkdSWURZMjl0"
    "TVJjd0ZRWUtDWkltaVpQeUxHUUJHUllIWlhoaGJYQnNaVEVZTUJZR0ExVUVBd3dQVWxO"
    "QklFVjRZVzF3YkdVZ1FVTlRNSUlCSWpBTkJna3Foa2lHOXcwQkFRRUZBQU9DQVE4QU1J"
    "SUJDZ0tDQVFFQWtOclBJQkRYTVU2ZmN5djVpK1FIUUFRK0s4Z3NDM0hKYjdGWWhZYXc4"
    "aFhiTkphK3Q4cTBsREt3TFpnUVhZVitmZld4WEp2NUdHcmxaRTRHVTUybGZNRWVnVER6"
    "WVRyUlEzdGVwZ0tGak1HZzZJeTZma2wxWk5zeDJnRW9uc25sU2hmekE5R0p3UlRtdEtQ"
    "Ymsxcytod3gxSVU1QVQrQUllbE5xQmdjRjJ2RTVXMjUvU0dHQm9hUk9WZFVZeHFFVERn"
    "Z00xejVjS1Y0WmpEWjgrbGg0b1ZCMDdia2FjNkxRZEhwSlVVeVNIL0VyMjBEWHgzMEt5"
    "aTk3UGNpWEtUUytRS1hubW04aXZ5UkNtdXgyMlpvUFVpbmQyQktDNU9pRzRNd0FMaGFM"
    "MloyazhDc1JkZnkrN2RnN3o0MVJwNkQwWmVFdnRhVXA0Ylg0YUtyYUw0clRmd0lEQVFB"
    "Qm8yQXdYakFNQmdOVkhSTUJBZjhFQWpBQU1BNEdBMVVkRHdFQi93UUVBd0lIZ0RBZEJn"
    "TlZIUTRFRmdRVWt0d2Y2WnBUQ3hqWUt3L0JMVzZQZWlOWDRzd3dId1lEVlIwakJCZ3dG"
    "b0FVdzRNQ25id0Q2bTJ3cG5vUTJzTkQ4R3J5UE40d0RRWUpLb1pJaHZjTkFRRUxCUUFE"
    "Z2dFQkFHdU5IeHYvQlI2ajdsQ1B5c20xdWhyYmpCT3FkcmhKTVIvSWQ0ZEIyR3RkRVNj"
    "bDNpckdQbVh5UTJTbmNUV2hOZnNnc0tEWldwNUJrNytPdG50eTBlTlVNazNoWkVxZ1lq"
    "eGh6YXUwNDhYSGJzZkd2b0phTUdaWk5Ud1V2VFV6Mmhra2hncHg5eVFBS0lBMkx6Rktj"
    "Z1loZWxQdTRHVzVydEV1eHUzSVM2V1l5M0QxR3RGM25hRVdralVyYThoUU9oT2wyUytD"
    "WUhtUmQ2bEdrWHlrVkRhak1nZDJBSkZ6WGRLTHhUdDBPWXJXREdsVVN6R0FDUkJDZDV4"
    "YlJtQVRJbGR0Y2NhR3FETjFjTld2MEkvYlBOOEVwS1M2QjBXYVpjUGFzSXRLV3BEQzg1"
    "SncxR3JEeGRod29LSG94dFNHK29kaVR3QjV6TGJybjJPc1JFNWJWN0U9Il19"
    "."
    "eyJBQ1MgRXBoZW1lcmFsIFB1YmxpYyBLZXkgKFFUKSI6eyJrdHkiOiJFQyIsImNydiI6"
    "IlAtMjU2IiwieCI6Im1QVUtUX2JBV0dISWhnMFRwampxVnNQMXJYV1F1X3Z3Vk9ISHRO"
    "a2RZb0EiLCJ5IjoiOEJRQXNJbUdlQVM0NmZ5V3c1TWhmR1RUMElqQnBGdzJTUzM0RHY0"
    "SXJzIix9LCJTREsgRXBoZW1lcmFsIFB1YmxpYyBLZXkgKFFDKSI6eyJrdHkiOiJFQyIs"
    "ImNydiI6IlAtMjU2IiwieCI6IlplMmxvU1Yzd3Jyb0tVTl80emh3R2hDcW8zWGh1MXRk"
    "NFFqZVE1d0lWUjAiLCJ5IjoiSGxMdGRYQVJZX2Y1NUEzZm56UWJQY202aGdyMzRNcDhw"
    "LW51elFDRTBadyIsfSwiQUNTIFVSTCI6Imh0dHA6Ly9hY3NzZXJ2ZXIuZG9tYWlubmFt"
    "ZS5jb20ifQ"
    "."
    "OiiD5pbwe_0wrG_j61LmUxidBzTbUHyZXrKE9efRylEgMJy0axYJLOUshIloiKMexPdo"
    "yDdpZV5pMQR588q-"
    "uuUfssKpDXj3dCrIlUCEwgs4yfIBAUwd2NHoDg20w25ek0NPH9RV_T867DAXIjDWyd2I"
    "y0ZFvJeHSrRskyPY75PA_mAUIpahaW20rxJHHMyGuWx2byKxnIx6G14vXCOPp1xEv49K"
    "xKWrgFLS3_GtVYuNDqQC5pleHd4drLKSbq1bjwqEM1osYEZvw9y-"
    "f1vQYxAQ8GJEti9F_309GVCZSWe1oyNDY51mo-"
    "BwiyojoCDPxQDOTp6g4lp656tUQNW16g";
    STDSJSONWebSignature *jws = [[STDSJSONWebSignature alloc] initWithString:jwsString];
    
    // ref. EMVCo_3DS_-AppBased_CryptoExamples_082018.pdf
    NSString *certificateString = @"MIIDXTCCAkWgAwIBAgIQbS4C4BSig7uuJ5uDpeT4VjANBgkqhkiG9w0BAQsFADBH"
    "MRMwEQYKCZImiZPyLGQBGRYDY29tMRcwFQYKCZImiZPyLGQBGRYHZXhhbXBsZTEX"
    "MBUGA1UEAwwOUlNBIEV4YW1wbGUgRFMwHhcNMTcxMTIxMTE0ODQ5WhcNMjcxMjMx"
    "MTQwMDAwWjBHMRMwEQYKCZImiZPyLGQBGRYDY29tMRcwFQYKCZImiZPyLGQBGRYH"
    "ZXhhbXBsZTEXMBUGA1UEAwwOUlNBIEV4YW1wbGUgRFMwggEiMA0GCSqGSIb3DQEB"
    "AQUAA4IBDwAwggEKAoIBAQCfgQ+0A4Jz0CWR5Ac/MdK2ABuCzttNkvBQFl1Hz8q4"
    "o8Qct3isdVN5P475dXaNGiN02HElZMO813uepDRUSJlAfP8AmZIKkxokxEFIUqsp"
    "vbCpXAZT82xg5gv5C2JY3aVvNwR7pcLR0CmvnJ1AuseqQceKDdEGit1pnoCP6gEe"
    "oUQdik97tOl7459V8d3UTpxLozUVlwPU00tgPmUUek8j1tPAmWx17e6EaoLRkK4Q"
    "eDyWHPA4eu0hBtLQVVtv2Tf61VNTh+D/cv++eJQUArC4IuoqdLYFjB2r+bNKdstj"
    "uH+qLGhHuOKDf/+RGG5rHBSRHPmJqJCSqBzmAd2s0/nPAgMBAAGjRTBDMBIGA1Ud"
    "EwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgEGMB0GA1UdDgQWBBTDgwKdvAPq"
    "bbCmehDaw0PwavI83jANBgkqhkiG9w0BAQsFAAOCAQEAOUcKqpzNQ6lr0PbDSsns"
    "D6onfi+8j3TD0xG0zBSf+8G4zs8Zb6vzzQ5qHKgfr4aeen8Pw0cw2KKUJ2dFaBqj"
    "n3/6/MIZbgaBvXKUbmY8xCxKQ+tOFc3KWIu4pSaO50tMPJjU/lP35bv19AA9vs9M"
    "TKY2qLf88bmoNYT3W8VSDcB58KBHa7HVIPx7BUUtSyb2N2Jqx5AOiYy4NarhB3hV"
    "ftkZBmCzi2Qw50KWIgTFYcIVeRTx3Js/F0IuEdgZHBK2gmO7fdM7+QKYm83401vl"
    "YRNCXfIZ0H9E1V3NddqJuqIutdUajckSzMhXdNCJqfI4FAQAymTWGL3/lZyr/30x"
    "Fg==";
        
    XCTAssertTrue([STDSDirectoryServerCertificate verifyJSONWebSignature:jws withRootCertificates:@[certificateString]], @"Failed to validate correct PS256 signature.");
}

- (void)testVerifyPS256SignatureFail {
    // ref. EMVCo_3DS_-AppBased_CryptoExamples_082018.pdf
    NSString *jwsString = @"eyJhbGciOiJQUzI1NiIsIng1YyI6WyJNSUlEZVRDQ0FtR2dBd0lCQWdJUWJTNEM0QlNp"
    "Zzd1dUo1dURwZVQ0V0RBTkJna3Foa2lHOXcwQkFRc0ZBREJITVJNd0VRWUtDWkltaVpQ"
    "eUxHUUJHUllEWTI5dE1SY3dGUVlLQ1pJbWlaUHlMR1FCR1JZSFpYaGhiWEJzWlRFWE1C"
    "VUdBMVVFQXd3T1VsTkJJRVY0WVcxd2JHVWdSRk13SGhjTk1UY3hNVEl4TVRFMU5EQXlX"
    "aGNOTWpjeE1qTXhNVE16TURBd1dqQklNUk13RVFZS0NaSW1pWlB5TEdRQkdSWURZMjl0"
    "TVJjd0ZRWUtDWkltaVpQeUxHUUJHUllIWlhoaGJYQnNaVEVZTUJZR0ExVUVBd3dQVWxO"
    "QklFVjRZVzF3YkdVZ1FVTlRNSUlCSWpBTkJna3Foa2lHOXcwQkFRRUZBQU9DQVE4QU1J"
    "SUJDZ0tDQVFFQWtOclBJQkRYTVU2ZmN5djVpK1FIUUFRK0s4Z3NDM0hKYjdGWWhZYXc4"
    "aFhiTkphK3Q4cTBsREt3TFpnUVhZVitmZld4WEp2NUdHcmxaRTRHVTUybGZNRWVnVER6"
    "WVRyUlEzdGVwZ0tGak1HZzZJeTZma2wxWk5zeDJnRW9uc25sU2hmekE5R0p3UlRtdEtQ"
    "Ymsxcytod3gxSVU1QVQrQUllbE5xQmdjRjJ2RTVXMjUvU0dHQm9hUk9WZFVZeHFFVERn"
    "Z00xejVjS1Y0WmpEWjgrbGg0b1ZCMDdia2FjNkxRZEhwSlVVeVNIL0VyMjBEWHgzMEt5"
    "aTk3UGNpWEtUUytRS1hubW04aXZ5UkNtdXgyMlpvUFVpbmQyQktDNU9pRzRNd0FMaGFM"
    "MloyazhDc1JkZnkrN2RnN3o0MVJwNkQwWmVFdnRhVXA0Ylg0YUtyYUw0clRmd0lEQVFB"
    "Qm8yQXdYakFNQmdOVkhSTUJBZjhFQWpBQU1BNEdBMVVkRHdFQi93UUVBd0lIZ0RBZEJn"
    "TlZIUTRFRmdRVWt0d2Y2WnBUQ3hqWUt3L0JMVzZQZWlOWDRzd3dId1lEVlIwakJCZ3dG"
    "b0FVdzRNQ25id0Q2bTJ3cG5vUTJzTkQ4R3J5UE40d0RRWUpLb1pJaHZjTkFRRUxCUUFE"
    "Z2dFQkFHdU5IeHYvQlI2ajdsQ1B5c20xdWhyYmpCT3FkcmhKTVIvSWQ0ZEIyR3RkRVNj"
    "bDNpckdQbVh5UTJTbmNUV2hOZnNnc0tEWldwNUJrNytPdG50eTBlTlVNazNoWkVxZ1lq"
    "eGh6YXUwNDhYSGJzZkd2b0phTUdaWk5Ud1V2VFV6Mmhra2hncHg5eVFBS0lBMkx6Rktj"
    "Z1loZWxQdTRHVzVydEV1eHUzSVM2V1l5M0QxR3RGM25hRVdralVyYThoUU9oT2wyUytD"
    "WUhtUmQ2bEdrWHlrVkRhak1nZDJBSkZ6WGRLTHhUdDBPWXJXREdsVVN6R0FDUkJDZDV4"
    "YlJtQVRJbGR0Y2NhR3FETjFjTld2MEkvYlBOOEVwS1M2QjBXYVpjUGFzSXRLV3BEQzg1"
    "SncxR3JEeGRod29LSG94dFNHK29kaVR3QjV6TGJybjJPc1JFNWJWN0U9Il19"
    "."
    "eyJBQ1MgRXBoZW1lcmFsIFB1YmxpYyBLZXkgKFFUKSI6eyJrdHkiOiJFQyIsImNydiI6"
    "IlAtMjU2IiwieCI6Im1QVUtUX2JBV0dISWhnMFRwampxVnNQMXJYV1F1X3Z3Vk9ISHRO"
    "a2RZb0EiLCJ5IjoiOEJRQXNJbUdlQVM0NmZ5V3c1TWhmR1RUMElqQnBGdzJTUzM0RHY0"
    "SXJzIix9LCJTREsgRXBoZW1lcmFsIFB1YmxpYyBLZXkgKFFDKSI6eyJrdHkiOiJFQyIs"
    "ImNydiI6IlAtMjU2IiwieCI6IlplMmxvU1Yzd3Jyb0tVTl80emh3R2hDcW8zWGh1MXRk"
    "NFFqZVE1d0lWUjAiLCJ5IjoiSGxMdGRYQVJZX2Y1NUEzZm56UWJQY202aGdyMzRNcDhw"
    "LW51elFDRTBadyIsfSwiQUNTIFVSTCI6Imh0dHA6Ly9hY3NzZXJ2ZXIuZG9tYWlubmFt"
    "ZS5jb20ifQ"
    "."
    "OiiD5pbwe_0wrG_j61LmUxidBzTbUHyZXrKE9efRylEgMJy0axYJLOUshIloiKMexPdo"
    "yDdpZV5pMQR588q-"
    "uuUfssKpDXj3dCrIlUCEwgs4yfIBAUwd2NHoDg20w25ek0NPH9RV_T867DAXIjDWyd2I"
    "y0ZFvJeHSrRskyPY75PA_mAUIpahaW20rxJHHMyGuWx2byKxnIx6G14vXCOPp1xEv49K"
    "xKWrgFLS3_GtVYuNDqQC5pleHd4drLKSbq1bjwqEM1osYEZvw9y-"
    "f1vQYxAQ8GJEti9F_309GVCZSWe1oyNEY51mo-" // This is all the same as testVerifyPS256Signature, except this line where "NDY51mo-" became "NEY51mo-"
    "BwiyojoCDPxQDOTp6g4lp656tUQNW16g";
    STDSJSONWebSignature *jws = [[STDSJSONWebSignature alloc] initWithString:jwsString];
    
    // ref. EMVCo_3DS_-AppBased_CryptoExamples_082018.pdf
    NSString *certificateString = @"MIIDXTCCAkWgAwIBAgIQbS4C4BSig7uuJ5uDpeT4VjANBgkqhkiG9w0BAQsFADBH"
    "MRMwEQYKCZImiZPyLGQBGRYDY29tMRcwFQYKCZImiZPyLGQBGRYHZXhhbXBsZTEX"
    "MBUGA1UEAwwOUlNBIEV4YW1wbGUgRFMwHhcNMTcxMTIxMTE0ODQ5WhcNMjcxMjMx"
    "MTQwMDAwWjBHMRMwEQYKCZImiZPyLGQBGRYDY29tMRcwFQYKCZImiZPyLGQBGRYH"
    "ZXhhbXBsZTEXMBUGA1UEAwwOUlNBIEV4YW1wbGUgRFMwggEiMA0GCSqGSIb3DQEB"
    "AQUAA4IBDwAwggEKAoIBAQCfgQ+0A4Jz0CWR5Ac/MdK2ABuCzttNkvBQFl1Hz8q4"
    "o8Qct3isdVN5P475dXaNGiN02HElZMO813uepDRUSJlAfP8AmZIKkxokxEFIUqsp"
    "vbCpXAZT82xg5gv5C2JY3aVvNwR7pcLR0CmvnJ1AuseqQceKDdEGit1pnoCP6gEe"
    "oUQdik97tOl7459V8d3UTpxLozUVlwPU00tgPmUUek8j1tPAmWx17e6EaoLRkK4Q"
    "eDyWHPA4eu0hBtLQVVtv2Tf61VNTh+D/cv++eJQUArC4IuoqdLYFjB2r+bNKdstj"
    "uH+qLGhHuOKDf/+RGG5rHBSRHPmJqJCSqBzmAd2s0/nPAgMBAAGjRTBDMBIGA1Ud"
    "EwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgEGMB0GA1UdDgQWBBTDgwKdvAPq"
    "bbCmehDaw0PwavI83jANBgkqhkiG9w0BAQsFAAOCAQEAOUcKqpzNQ6lr0PbDSsns"
    "D6onfi+8j3TD0xG0zBSf+8G4zs8Zb6vzzQ5qHKgfr4aeen8Pw0cw2KKUJ2dFaBqj"
    "n3/6/MIZbgaBvXKUbmY8xCxKQ+tOFc3KWIu4pSaO50tMPJjU/lP35bv19AA9vs9M"
    "TKY2qLf88bmoNYT3W8VSDcB58KBHa7HVIPx7BUUtSyb2N2Jqx5AOiYy4NarhB3hV"
    "ftkZBmCzi2Qw50KWIgTFYcIVeRTx3Js/F0IuEdgZHBK2gmO7fdM7+QKYm83401vl"
    "YRNCXfIZ0H9E1V3NddqJuqIutdUajckSzMhXdNCJqfI4FAQAymTWGL3/lZyr/30x"
    "Fg==";
        
    XCTAssertFalse([STDSDirectoryServerCertificate verifyJSONWebSignature:jws withRootCertificates:@[certificateString]], @"Incorrectly validated PS256 signature.");
}

- (void)testVerifyES256Signature {
    // ref. EMVCo_3DS_-AppBased_CryptoExamples_082018.pdf
    NSString *jwsString = @"eyJhbGciOiJFUzI1NiIsIng1YyI6WyJNSUlDclRDQ0FaV2dBd0lCQWdJUWJTNEM0QlNp"
    "Zzd1dUo1dURwZVQ0V1RBTkJna3Foa2lHOXcwQkFRc0ZBREJITVJNd0VRWUtDWkltaVpQ"
    "eUxHUUJHUllEWTI5dE1SY3dGUVlLQ1pJbWlaUHlMR1FCR1JZSFpYaGhiWEJzWlRFWE1C"
    "VUdBMVVFQXd3T1VsTkJJRVY0WVcxd2JHVWdSRk13SGhjTk1UY3hNVEl4TVRVME16STNX"
    "aGNOTWpjeE1qTXhNVE16TURBd1dqQkhNUk13RVFZS0NaSW1pWlB5TEdRQkdSWURZMjl0"
    "TVJjd0ZRWUtDWkltaVpQeUxHUUJHUllIWlhoaGJYQnNaVEVYTUJVR0ExVUVBd3dPUlVN"
    "Z1JYaGhiWEJzWlNCQlExTXdXVEFUQmdjcWhrak9QUUlCQmdncWhrak9QUU1CQndOQ0FB"
    "VGZvZml3YzZBaXUxWWc1dkc5ZUtYSGVEQ1ZoOWgzVk1xTjIveUoxQ1dHVWlwOEJqOHEr"
    "ZXJPbzc0dHQ2akVUTXpBYVRwekxaNW9HRFpjZVpmR21NN2RvMkF3WGpBTUJnTlZIUk1C"
    "QWY4RUFqQUFNQTRHQTFVZER3RUIvd1FFQXdJSGdEQWRCZ05WSFE0RUZnUVUwQVd0REhS"
    "L3ZsUXJSQXo0YUtnSkJsbkZqRXN3SHdZRFZSMGpCQmd3Rm9BVXc0TUNuYndENm0yd3Bu"
    "b1Eyc05EOEdyeVBONHdEUVlKS29aSWh2Y05BUUVMQlFBRGdnRUJBRXFsRVJld1VDZUV0"
    "dEFrQzBGMTZIamp4ZnYxV2E4bmFEbWFSTDk5UTAvcXFVTjh3MHF3cEFQRjd3bjJhZkxm"
    "YUdkKzV1WkViMVROWXdWOUF3OUwvczNCY1NURVJJbDZPRVduK3g3Y3RPbUh5MnZ2N21p"
    "dGFVcmlsZUdvZGVubS9mYURkeTVWZ0tZaitLc01WTTJzTlZhZWtYK1Qwc3dBQ1g5Qjkw"
    "dW5aeGE2MjU2dDJPSjJRVjV6dTNzWU8xTjBqOXY3K3lGK0ZneDAxNE5ydzcvWHQ4SUxH"
    "RjU4TnhiUWhraGtmV1NmSHRhRTVtb0JBYldSdUZURmJrQmY0NVNLZTBVTWlVNUxhYzl4"
    "STBPN1hDRCt6TkI1bXdzNE5PMkFZdnl4SHE5WCthNjRJaFhjbFhuZ1BRTXJVcU1vTFdJ"
    "MTY2Z1JKU3ZRRVdzSUxJVXR4MndzaVlzPSJdfQ"
    "."
    "eyJBQ1MgRXBoZW1lcmFsIFB1YmxpYyBLZXkgKFFUKSI6eyJrdHkiOiJFQyIsImNydiI6"
    "IlAtMjU2IiwieCI6Im1QVUtUX2JBV0dISWhnMFRwampxVnNQMXJYV1F1X3Z3Vk9ISHRO"
    "a2RZb0EiLCJ5IjoiOEJRQXNJbUdlQVM0NmZ5V3c1TWhmR1RUMElqQnBGdzJTUzM0RHY0"
    "SXJzIix9LCJTREsgRXBoZW1lcmFsIFB1YmxpYyBLZXkgKFFDKSI6eyJrdHkiOiJFQyIs"
    "ImNydiI6IlAtMjU2IiwieCI6IlplMmxvU1Yzd3Jyb0tVTl80emh3R2hDcW8zWGh1MXRk"
    "NFFqZVE1d0lWUjAiLCJ5IjoiSGxMdGRYQVJZX2Y1NUEzZm56UWJQY202aGdyMzRNcDhw"
    "LW51elFDRTBadyIsfSwiQUNTIFVSTCI6Imh0dHA6Ly9hY3NzZXJ2ZXIuZG9tYWlubmFt"
    "ZS5jb20ifQ"
    "."
    "KMNtxy3eZMDnVRK_UZvFtRY8fDuAAHJXHCaKncoViB3dy56u5VOT0XnB8K-"
    "0nWwFhwWmwU1xGVwimBcfxNplCA";
    STDSJSONWebSignature *jws = [[STDSJSONWebSignature alloc] initWithString:jwsString];
    
    // ref. EMVCo_3DS_-AppBased_CryptoExamples_082018.pdf
    NSString *certificateString = @"MIIDXTCCAkWgAwIBAgIQbS4C4BSig7uuJ5uDpeT4VjANBgkqhkiG9w0BAQsFADBH"
    "MRMwEQYKCZImiZPyLGQBGRYDY29tMRcwFQYKCZImiZPyLGQBGRYHZXhhbXBsZTEX"
    "MBUGA1UEAwwOUlNBIEV4YW1wbGUgRFMwHhcNMTcxMTIxMTE0ODQ5WhcNMjcxMjMx"
    "MTQwMDAwWjBHMRMwEQYKCZImiZPyLGQBGRYDY29tMRcwFQYKCZImiZPyLGQBGRYH"
    "ZXhhbXBsZTEXMBUGA1UEAwwOUlNBIEV4YW1wbGUgRFMwggEiMA0GCSqGSIb3DQEB"
    "AQUAA4IBDwAwggEKAoIBAQCfgQ+0A4Jz0CWR5Ac/MdK2ABuCzttNkvBQFl1Hz8q4"
    "o8Qct3isdVN5P475dXaNGiN02HElZMO813uepDRUSJlAfP8AmZIKkxokxEFIUqsp"
    "vbCpXAZT82xg5gv5C2JY3aVvNwR7pcLR0CmvnJ1AuseqQceKDdEGit1pnoCP6gEe"
    "oUQdik97tOl7459V8d3UTpxLozUVlwPU00tgPmUUek8j1tPAmWx17e6EaoLRkK4Q"
    "eDyWHPA4eu0hBtLQVVtv2Tf61VNTh+D/cv++eJQUArC4IuoqdLYFjB2r+bNKdstj"
    "uH+qLGhHuOKDf/+RGG5rHBSRHPmJqJCSqBzmAd2s0/nPAgMBAAGjRTBDMBIGA1Ud"
    "EwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgEGMB0GA1UdDgQWBBTDgwKdvAPq"
    "bbCmehDaw0PwavI83jANBgkqhkiG9w0BAQsFAAOCAQEAOUcKqpzNQ6lr0PbDSsns"
    "D6onfi+8j3TD0xG0zBSf+8G4zs8Zb6vzzQ5qHKgfr4aeen8Pw0cw2KKUJ2dFaBqj"
    "n3/6/MIZbgaBvXKUbmY8xCxKQ+tOFc3KWIu4pSaO50tMPJjU/lP35bv19AA9vs9M"
    "TKY2qLf88bmoNYT3W8VSDcB58KBHa7HVIPx7BUUtSyb2N2Jqx5AOiYy4NarhB3hV"
    "ftkZBmCzi2Qw50KWIgTFYcIVeRTx3Js/F0IuEdgZHBK2gmO7fdM7+QKYm83401vl"
    "YRNCXfIZ0H9E1V3NddqJuqIutdUajckSzMhXdNCJqfI4FAQAymTWGL3/lZyr/30x"
    "Fg==";
        
    XCTAssertTrue([STDSDirectoryServerCertificate verifyJSONWebSignature:jws withRootCertificates:@[certificateString]], @"Failed to verify valid ES256 signature.");
}

- (void)testVerifyES256SignatureFail {
    // ref. EMVCo_3DS_-AppBased_CryptoExamples_082018.pdf
    NSString *jwsString = @"eyJhbGciOiJFUzI1NiIsIng1YyI6WyJNSUlDclRDQ0FaV2dBd0lCQWdJUWJTNEM0QlNp"
    "Zzd1dUo1dURwZVQ0V1RBTkJna3Foa2lHOXcwQkFRc0ZBREJITVJNd0VRWUtDWkltaVpQ"
    "eUxHUUJHUllEWTI5dE1SY3dGUVlLQ1pJbWlaUHlMR1FCR1JZSFpYaGhiWEJzWlRFWE1C"
    "VUdBMVVFQXd3T1VsTkJJRVY0WVcxd2JHVWdSRk13SGhjTk1UY3hNVEl4TVRVME16STNX"
    "aGNOTWpjeE1qTXhNVE16TURBd1dqQkhNUk13RVFZS0NaSW1pWlB5TEdRQkdSWURZMjl0"
    "TVJjd0ZRWUtDWkltaVpQeUxHUUJHUllIWlhoaGJYQnNaVEVYTUJVR0ExVUVBd3dPUlVN"
    "Z1JYaGhiWEJzWlNCQlExTXdXVEFUQmdjcWhrak9QUUlCQmdncWhrak9QUU1CQndOQ0FB"
    "VGZvZml3YzZBaXUxWWc1dkc5ZUtYSGVEQ1ZoOWgzVk1xTjIveUoxQ1dHVWlwOEJqOHEr"
    "ZXJPbzc0dHQ2akVUTXpBYVRwekxaNW9HRFpjZVpmR21NN2RvMkF3WGpBTUJnTlZIUk1C"
    "QWY4RUFqQUFNQTRHQTFVZER3RUIvd1FFQXdJSGdEQWRCZ05WSFE0RUZnUVUwQVd0REhS"
    "L3ZsUXJSQXo0YUtnSkJsbkZqRXN3SHdZRFZSMGpCQmd3Rm9BVXc0TUNuYndENm0yd3Bu"
    "b1Eyc05EOEdyeVBONHdEUVlKS29aSWh2Y05BUUVMQlFBRGdnRUJBRXFsRVJld1VDZUV0"
    "dEFrQzBGMTZIamp4ZnYxV2E4bmFEbWFSTDk5UTAvcXFVTjh3MHF3cEFQRjd3bjJhZkxm"
    "YUdkKzV1WkViMVROWXdWOUF3OUwvczNCY1NURVJJbDZPRVduK3g3Y3RPbUh5MnZ2N21p"
    "dGFVcmlsZUdvZGVubS9mYURkeTVWZ0tZaitLc01WTTJzTlZhZWtYK1Qwc3dBQ1g5Qjkw"
    "dW5aeGE2MjU2dDJPSjJRVjV6dTNzWU8xTjBqOXY3K3lGK0ZneDAxNE5ydzcvWHQ4SUxH"
    "RjU4TnhiUWhraGtmV1NmSHRhRTVtb0JBYldSdUZURmJrQmY0NVNLZTBVTWlVNUxhYzl4"
    "STBPN1hDRCt6TkI1bXdzNE5PMkFZdnl4SHE5WCthNjRJaFhjbFhuZ1BRTXJVcU1vTFdJ"
    "MTY2Z1JKU3ZRRVdzSUxJVXR4MndzaVlzPSJdfQ"
    "."
    "eyJBQ1MgRXBoZW1lcmFsIFB1YmxpYyBLZXkgKFFUKSI6eyJrdHkiOiJFQyIsImNydiI6"
    "IlAtMjU2IiwieCI6Im1QVUtUX2JBV0dISWhnMFRwampxVnNQMXJYV1F1X3Z3Vk9ISHRO"
    "a2RZb0EiLCJ5IjoiOEJRQXNJbUdlQVM0NmZ5V3c1TWhmR1RUMElqQnBGdzJTUzM0RHY0"
    "SXJzIix9LCJTREsgRXBoZW1lcmFsIFB1YmxpYyBLZXkgKFFDKSI6eyJrdHkiOiJFQyIs"
    "ImNydiI6IlAtMjU2IiwieCI6IlplMmxvU1Yzd3Jyb0tVTl80emh3R2hDcW8zWGh1MXRk"
    "NFFqZVE1d0lWUjAiLCJ5IjoiSGxMdGRYQVJZX2Y1NUEzZm56UWJQY202aGdyMzRNcDhw"
    "LW51elFDRTBadyIsfSwiQUNTIFVSTCI6Imh0dHA6Ly9hY3NzZXJ2ZXIuZG9tYWlubMFt" // This is all the same as testVerifyPS256Signature, except this line where "bmFt" became "bMFt"
    "ZS5jb20ifQ"
    "."
    "KMNtxy3eZMDnVRK_UZvFtRY8fDuAAHJXHCaKncoViB3dy56u5VOT0XnB8K-"
    "0nWwFhwWmwU1xGVwimBcfxNplCA";
    STDSJSONWebSignature *jws = [[STDSJSONWebSignature alloc] initWithString:jwsString];
    
    // ref. EMVCo_3DS_-AppBased_CryptoExamples_082018.pdf
    NSString *certificateString = @"MIIDXTCCAkWgAwIBAgIQbS4C4BSig7uuJ5uDpeT4VjANBgkqhkiG9w0BAQsFADBH"
    "MRMwEQYKCZImiZPyLGQBGRYDY29tMRcwFQYKCZImiZPyLGQBGRYHZXhhbXBsZTEX"
    "MBUGA1UEAwwOUlNBIEV4YW1wbGUgRFMwHhcNMTcxMTIxMTE0ODQ5WhcNMjcxMjMx"
    "MTQwMDAwWjBHMRMwEQYKCZImiZPyLGQBGRYDY29tMRcwFQYKCZImiZPyLGQBGRYH"
    "ZXhhbXBsZTEXMBUGA1UEAwwOUlNBIEV4YW1wbGUgRFMwggEiMA0GCSqGSIb3DQEB"
    "AQUAA4IBDwAwggEKAoIBAQCfgQ+0A4Jz0CWR5Ac/MdK2ABuCzttNkvBQFl1Hz8q4"
    "o8Qct3isdVN5P475dXaNGiN02HElZMO813uepDRUSJlAfP8AmZIKkxokxEFIUqsp"
    "vbCpXAZT82xg5gv5C2JY3aVvNwR7pcLR0CmvnJ1AuseqQceKDdEGit1pnoCP6gEe"
    "oUQdik97tOl7459V8d3UTpxLozUVlwPU00tgPmUUek8j1tPAmWx17e6EaoLRkK4Q"
    "eDyWHPA4eu0hBtLQVVtv2Tf61VNTh+D/cv++eJQUArC4IuoqdLYFjB2r+bNKdstj"
    "uH+qLGhHuOKDf/+RGG5rHBSRHPmJqJCSqBzmAd2s0/nPAgMBAAGjRTBDMBIGA1Ud"
    "EwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgEGMB0GA1UdDgQWBBTDgwKdvAPq"
    "bbCmehDaw0PwavI83jANBgkqhkiG9w0BAQsFAAOCAQEAOUcKqpzNQ6lr0PbDSsns"
    "D6onfi+8j3TD0xG0zBSf+8G4zs8Zb6vzzQ5qHKgfr4aeen8Pw0cw2KKUJ2dFaBqj"
    "n3/6/MIZbgaBvXKUbmY8xCxKQ+tOFc3KWIu4pSaO50tMPJjU/lP35bv19AA9vs9M"
    "TKY2qLf88bmoNYT3W8VSDcB58KBHa7HVIPx7BUUtSyb2N2Jqx5AOiYy4NarhB3hV"
    "ftkZBmCzi2Qw50KWIgTFYcIVeRTx3Js/F0IuEdgZHBK2gmO7fdM7+QKYm83401vl"
    "YRNCXfIZ0H9E1V3NddqJuqIutdUajckSzMhXdNCJqfI4FAQAymTWGL3/lZyr/30x"
    "Fg==";
        
    XCTAssertFalse([STDSDirectoryServerCertificate verifyJSONWebSignature:jws withRootCertificates:@[certificateString]], @"Verified invalid ES256 signature.");
}

@end
