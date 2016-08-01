//
//  STPPaymentContextTest.m
//  Stripe
//
//  Created by Brian Dorfman on 8/1/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPAPIClient.h"
#import "STPPaymentContext.h"

@interface STPPaymentContext (Testing)
- (PKPaymentRequest *)buildPaymentRequest;
@end

@interface TestSTPBackendAPIAdapter: NSObject <STPBackendAPIAdapter>
@end

@implementation TestSTPBackendAPIAdapter

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-parameter"
- (void)retrieveCustomer:(STPCustomerCompletionBlock)completion {

}

- (void)attachSourceToCustomer:(id<STPSource>)source completion:(STPErrorBlock)completion {
    
}

- (void)selectDefaultCustomerSource:(id<STPSource>)source completion:(STPErrorBlock)completion {
    
}
#pragma clang diagnostic pop

@end

@interface STPPaymentContextTest : XCTestCase

@end

@implementation STPPaymentContextTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [Stripe setDefaultPublishableKey:@"test"];
    [STPPaymentConfiguration sharedConfiguration].appleMerchantIdentifier = @"testMerchantId";
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testPKPaymentTotalAmount {
    STPPaymentContext *context = [[STPPaymentContext alloc] initWithAPIAdapter:[TestSTPBackendAPIAdapter new]];
    context.paymentAmount = 150;
    PKPaymentRequest *request = [context buildPaymentRequest];

    XCTAssertTrue([[request.paymentSummaryItems lastObject].amount isEqual:[NSDecimalNumber decimalNumberWithString:@"1.50"]],
                  @"PKPayment total is not equal to STPPaymentContext amount");
}

- (void)testPKPaymentUSDDefault {
    STPPaymentContext *context = [[STPPaymentContext alloc] initWithAPIAdapter:[TestSTPBackendAPIAdapter new]];
    context.paymentAmount = 100;
    PKPaymentRequest *request = [context buildPaymentRequest];
    
    XCTAssertTrue([request.currencyCode isEqualToString:@"USD"], 
                  @"Default PKPaymentRequest currency code is not USD");
}

- (void)testPKPaymentGBP {
    STPPaymentContext *context = [[STPPaymentContext alloc] initWithAPIAdapter:[TestSTPBackendAPIAdapter new]];
    context.paymentAmount = 100;
    context.paymentCurrency = @"GBP";
    PKPaymentRequest *request = [context buildPaymentRequest];

    XCTAssertTrue([request.currencyCode isEqualToString:@"GBP"], 
                  @"PKPaymentRequest currency code is not equal to STPPaymentContext currency");
}

- (void)testPKPaymentLowercase {
    STPPaymentContext *context = [[STPPaymentContext alloc] initWithAPIAdapter:[TestSTPBackendAPIAdapter new]];
    context.paymentAmount = 100;
    context.paymentCurrency = @"eur";
    PKPaymentRequest *request = [context buildPaymentRequest];

    XCTAssertTrue([request.currencyCode isEqualToString:@"EUR"], 
                  @"PKPaymentRequest currency code is not uppercased");
}



@end
