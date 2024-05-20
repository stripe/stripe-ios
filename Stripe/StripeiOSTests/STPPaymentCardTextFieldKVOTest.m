//
//  STPPaymentCardTextFieldKVOTest.m
//  Stripe
//
//  Created by Jack Flintermann on 8/26/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

@import UIKit;
@import XCTest;
@import OCMock;
@import StripeCoreTestUtils;
@import StripePaymentsObjcTestUtils;

@interface STPPaymentCardTextField (Testing)
@property (nonatomic, readwrite, weak) UIImageView *brandImageView;
@property (nonatomic, readwrite, weak) STPFormTextField *numberField;
@property (nonatomic, readwrite, weak) STPFormTextField *expirationField;
@property (nonatomic, readwrite, weak) STPFormTextField *cvcField;
@property (nonatomic, readwrite, weak) STPFormTextField *postalCodeField;
@property (nonatomic, readonly, weak) STPFormTextField *currentFirstResponderField;
@property (nonatomic, copy) NSNumber *focusedTextFieldForLayout;
+ (UIImage *)cvcImageForCardBrand:(STPCardBrand)cardBrand;
+ (UIImage *)brandImageForCardBrand:(STPCardBrand)cardBrand;
@end

@interface STPPaymentCardTextFieldKVOUITests : XCTestCase
@property (nonatomic) UIWindow *window;
@property (nonatomic) STPPaymentCardTextField *sut;
@end

@implementation STPPaymentCardTextFieldKVOUITests

+ (void)setUp {
    [super setUp];
    [[STPAPIClient sharedClient] setPublishableKey:STPTestingDefaultPublishableKey];
}

- (void)setUp {
    [super setUp];
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    STPPaymentCardTextField *textField = [[STPPaymentCardTextField alloc] initWithFrame:self.window.bounds];
    [self.window addSubview:textField];
    XCTAssertTrue([textField.numberField canBecomeFirstResponder], @"text field cannot become first responder");
    self.sut = textField;
}

- (void)testIsValidKVO {
    id observer = OCMClassMock([UIViewController class]);
    self.sut.numberField.text = @"4242424242424242";
    self.sut.expirationField.text = @"10/50";
    self.sut.postalCodeField.text = @"90210";
    XCTAssertFalse(self.sut.isValid);
    
    NSString *expectedKeyPath = @"sut.isValid";
    [self addObserver:observer forKeyPath:expectedKeyPath options:NSKeyValueObservingOptionNew context:nil];
    XCTestExpectation *exp = [self expectationWithDescription:@"observeValue"];
    OCMStub([observer observeValueForKeyPath:[OCMArg any] ofObject:[OCMArg any] change:[OCMArg any] context:nil])
    .andDo(^(NSInvocation *invocation) {
        NSString *keyPath;
        NSDictionary *change;
        [invocation getArgument:&keyPath atIndex:2];
        [invocation getArgument:&change atIndex:4];
        if ([keyPath isEqualToString:expectedKeyPath]) {
            if ([change[@"new"] boolValue]) {
                [exp fulfill];
                [self removeObserver:observer forKeyPath:@"sut.isValid"];
            }
        }
    });
    
    self.sut.cvcField.text = @"123";
    
    [self waitForExpectationsWithTimeout:TestConstants.STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testPaymentCardTextFieldCanSetPreferredBrands {
    STPPaymentCardTextField *textField = [[STPPaymentCardTextField alloc] initWithFrame:self.window.bounds];
    [textField setPreferredNetworks:@[[NSNumber numberWithInt:STPCardBrandVisa]]];
    XCTAssertEqual([[[textField preferredNetworks] firstObject] intValue], STPCardBrandVisa);
}

@end
