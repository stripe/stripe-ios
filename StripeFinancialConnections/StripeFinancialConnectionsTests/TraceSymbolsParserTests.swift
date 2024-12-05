//
//  TraceSymbolsParserTests.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2024-10-22.
//

import Foundation
@testable import StripeFinancialConnections
import XCTest

class TraceSymbolsParserTests: XCTestCase {
    // An example output of `Thread.callStackSymbols`.
    private static let mockCallStackSymbols: [String] = [
        "0   StripeFinancialConnections          0x0000000102315a18 $s26StripeFinancialConnections16SentryStacktraceC7captureSayAC10StackFrameVGyFZ + 200",
        "1   StripeFinancialConnections          0x00000001023c53d4 $s26StripeFinancialConnections0bC5SheetC7present4from10completionySo16UIViewControllerC_yAA04HostI6ResultOctF + 1360",
        "2   StripeFinancialConnections          0x00000001023c18e4 $s26StripeFinancialConnections0bC17SDKImplementationC07presentbC5Sheet9apiClient12clientSecret9returnURL22elementsSessionContext7onEvent4from10completiony0A4Core12STPAPIClientC_S2SSgAL08ElementsnO0VSgyAL0bcQ0VcSgSo16UIViewControllerCyAL0bC9SDKResultOctF + 724",
        "3   StripeFinancialConnections          0x00000001023c27f8 $s26StripeFinancialConnections0bC17SDKImplementationC0A4Core0bC12SDKInterfaceAadEP07presentbC5Sheet9apiClient12clientSecret9returnURL22elementsSessionContext7onEvent4from10completionyAD12STPAPIClientC_S2SSgAD08ElementspQ0VSgyAD0bcS0VcSgSo16UIViewControllerCyAD0bC9SDKResultOctFTW + 60",
        "4   StripeCore                          0x00000001019ccc2c $s10StripeCore32FinancialConnectionsSDKInterfaceP07presentcD5Sheet9apiClient12clientSecret9returnURL22elementsSessionContext7onEvent4from10completionyAA12STPAPIClientC_S2SSgAA08ElementsoP0VSgyAA0cdR0VcSgSo16UIViewControllerCyAA0cD9SDKResultOctFTj + 64",
        "5   StripePayments                      0x0000000102bd93ac $s14StripePayments23STPBankAccountCollectorC012_collectBankD10ForPayment33_DA65D4A0CBE8EF79280D20C93D49C0D2LL12clientSecret9returnURL20additionalParameters22elementsSessionContext7onEvent6params4from30financialConnectionsCompletionySS_SSSgSDySSypG0A4Core22ElementsSessionContextVSgyAP25FinancialConnectionsEventVcSgAA010STPCollectgD6ParamsCSo16UIViewControllerCyAP29FinancialConnectionsSDKResultOSg_AA04LinkD7SessionCSgSo7NSErrorCSgtctFyA4__s5Error_pSgtcfU_ + 1100",
        "6   StripePayments                      0x0000000102bde88c $s14StripePayments23STPBankAccountCollectorC012_collectBankD10ForPayment33_DA65D4A0CBE8EF79280D20C93D49C0D2LL12clientSecret9returnURL20additionalParameters22elementsSessionContext7onEvent6params4from30financialConnectionsCompletionySS_SSSgSDySSypG0A4Core22ElementsSessionContextVSgyAP25FinancialConnectionsEventVcSgAA010STPCollectgD6ParamsCSo16UIViewControllerCyAP29FinancialConnectionsSDKResultOSg_AA04LinkD7SessionCSgSo7NSErrorCSgtctFyA4__s5Error_pSgtcfU_TA + 168",
        "7   StripePayments                      0x0000000102ba32ec $s10StripeCore12STPAPIClientC0A8PaymentsE19linkAccountSessions33_F5AA4EEE3A66BBA67222962A492D7A9BLL8endpoint12clientSecret17paymentMethodType12customerName0V12EmailAddress21additionalParameteres10completionySS_SSAD010STPPaymenttU0OSSSgAPSDySSypGyAD04LinkF7SessionCSg_s5Error_pSgtctFyAT_So17NSHTTPURLResponseCSgAVtcfU_ + 104",
        "8   StripePayments                      0x0000000102bf0d4c $s14StripePayments10APIRequestC13parseResponse_4body5error10completionySo13NSURLResponseCSg_10Foundation4DataVSgs5Error_pSgyxSg_So17NSHTTPURLResponseCSgAPtctFZyAQ_APtcfU_yycfU_ + 176",
        "9   StripeCore                          0x0000000101970fec $sIeg_IeyB_TR + 48",
        "10  libdispatch.dylib                   0x0000000100724ec0 _dispatch_call_block_and_release + 24",
        "11  libdispatch.dylib                   0x00000001007267b8 _dispatch_client_callout + 16",
        "12  libdispatch.dylib                   0x000000010073645c _dispatch_main_queue_drain + 1224",
        "13  libdispatch.dylib                   0x0000000100735f84 _dispatch_main_queue_callback_4CF + 40",
        "14  CoreFoundation                      0x000000018041ae3c __CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__ + 12",
        "15  CoreFoundation                      0x0000000180415534 __CFRunLoopRun + 1944",
        "16  CoreFoundation                      0x0000000180414960 CFRunLoopRunSpecific + 536",
        "17  GraphicsServices                    0x0000000190183b10 GSEventRunModal + 160",
        "18  UIKitCore                           0x0000000185aa2b40 -[UIApplication _run] + 796",
        "19  UIKitCore                           0x0000000185aa6d38 UIApplicationMain + 124",
        "20  PaymentSheetExample.debug.dylib     0x0000000101308074 __debug_main_executable_dylib_entry_point + 64",
        "21  dyld                                0x0000000100879410 start_sim + 20",
        "22  ???                                 0x00000001001f2154 0x0 + 4297007444",
        "23  ???                                 0x690f000000000000 0x0 + 7570269498633093120",
    ]

    private static let expectedTraces: [CallStackTrace] = [
        CallStackTrace(module: "StripeFinancialConnections", function: "$s26StripeFinancialConnections16SentryStacktraceC7captureSayAC10StackFrameVGyFZ"),
        CallStackTrace(module: "StripeFinancialConnections", function: "$s26StripeFinancialConnections0bC5SheetC7present4from10completionySo16UIViewControllerC_yAA04HostI6ResultOctF"),
        CallStackTrace(module: "StripeFinancialConnections", function: "$s26StripeFinancialConnections0bC17SDKImplementationC07presentbC5Sheet9apiClient12clientSecret9returnURL22elementsSessionContext7onEvent4from10completiony0A4Core12STPAPIClientC_S2SSgAL08ElementsnO0VSgyAL0bcQ0VcSgSo16UIViewControllerCyAL0bC9SDKResultOctF"),
        CallStackTrace(module: "StripeFinancialConnections", function: "$s26StripeFinancialConnections0bC17SDKImplementationC0A4Core0bC12SDKInterfaceAadEP07presentbC5Sheet9apiClient12clientSecret9returnURL22elementsSessionContext7onEvent4from10completionyAD12STPAPIClientC_S2SSgAD08ElementspQ0VSgyAD0bcS0VcSgSo16UIViewControllerCyAD0bC9SDKResultOctFTW"),
        CallStackTrace(module: "StripeCore", function: "$s10StripeCore32FinancialConnectionsSDKInterfaceP07presentcD5Sheet9apiClient12clientSecret9returnURL22elementsSessionContext7onEvent4from10completionyAA12STPAPIClientC_S2SSgAA08ElementsoP0VSgyAA0cdR0VcSgSo16UIViewControllerCyAA0cD9SDKResultOctFTj"),
        CallStackTrace(module: "StripePayments", function: "$s14StripePayments23STPBankAccountCollectorC012_collectBankD10ForPayment33_DA65D4A0CBE8EF79280D20C93D49C0D2LL12clientSecret9returnURL20additionalParameters22elementsSessionContext7onEvent6params4from30financialConnectionsCompletionySS_SSSgSDySSypG0A4Core22ElementsSessionContextVSgyAP25FinancialConnectionsEventVcSgAA010STPCollectgD6ParamsCSo16UIViewControllerCyAP29FinancialConnectionsSDKResultOSg_AA04LinkD7SessionCSgSo7NSErrorCSgtctFyA4__s5Error_pSgtcfU_"),
        CallStackTrace(module: "StripePayments", function: "$s14StripePayments23STPBankAccountCollectorC012_collectBankD10ForPayment33_DA65D4A0CBE8EF79280D20C93D49C0D2LL12clientSecret9returnURL20additionalParameters22elementsSessionContext7onEvent6params4from30financialConnectionsCompletionySS_SSSgSDySSypG0A4Core22ElementsSessionContextVSgyAP25FinancialConnectionsEventVcSgAA010STPCollectgD6ParamsCSo16UIViewControllerCyAP29FinancialConnectionsSDKResultOSg_AA04LinkD7SessionCSgSo7NSErrorCSgtctFyA4__s5Error_pSgtcfU_TA"),
        CallStackTrace(module: "StripePayments", function: "$s10StripeCore12STPAPIClientC0A8PaymentsE19linkAccountSessions33_F5AA4EEE3A66BBA67222962A492D7A9BLL8endpoint12clientSecret17paymentMethodType12customerName0V12EmailAddress21additionalParameteres10completionySS_SSAD010STPPaymenttU0OSSSgAPSDySSypGyAD04LinkF7SessionCSg_s5Error_pSgtctFyAT_So17NSHTTPURLResponseCSgAVtcfU_"),
        CallStackTrace(module: "StripePayments", function: "$s14StripePayments10APIRequestC13parseResponse_4body5error10completionySo13NSURLResponseCSg_10Foundation4DataVSgs5Error_pSgyxSg_So17NSHTTPURLResponseCSgAPtctFZyAQ_APtcfU_yycfU_"),
        CallStackTrace(module: "StripeCore", function: "$sIeg_IeyB_TR"),
        CallStackTrace(module: "libdispatch.dylib", function: "_dispatch_call_block_and_release"),
        CallStackTrace(module: "libdispatch.dylib", function: "_dispatch_client_callout"),
        CallStackTrace(module: "libdispatch.dylib", function: "_dispatch_main_queue_drain"),
        CallStackTrace(module: "libdispatch.dylib", function: "_dispatch_main_queue_callback_4CF"),
        CallStackTrace(module: "CoreFoundation", function: "__CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__"),
        CallStackTrace(module: "CoreFoundation", function: "__CFRunLoopRun"),
        CallStackTrace(module: "CoreFoundation", function: "CFRunLoopRunSpecific"),
        CallStackTrace(module: "GraphicsServices", function: "GSEventRunModal"),
        CallStackTrace(module: "UIKitCore", function: "-[UIApplication _run]"),
        CallStackTrace(module: "UIKitCore", function: "UIApplicationMain"),
        CallStackTrace(module: "PaymentSheetExample.debug.dylib", function: "__debug_main_executable_dylib_entry_point"),
        CallStackTrace(module: "dyld", function: "start_sim"),
        CallStackTrace(module: "???", function: "0x0"),
        CallStackTrace(module: "???", function: "0x0"),
    ]

    func testParser() {
        for (symbols, expectedTrace) in zip(Self.mockCallStackSymbols, Self.expectedTraces) {
            let trace = TraceSymbolsParser.parse(symbols: symbols)
            XCTAssertEqual(trace, expectedTrace, "Expected trace does not match for symbols: \(symbols)")
        }
    }
}
