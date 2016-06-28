//
//  STPPaymentCardTextFieldTest.m
//  Stripe
//
//  Created by Jack Flintermann on 8/26/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

@import UIKit;
@import XCTest;

#import "Stripe.h"
#import "STPFormTextField.h"
#import "STPPaymentCardTextFieldViewModel.h"

@interface STPFormTextField(Testing)
@property(nonatomic)BOOL skipsReloadingInputViews;
@end

@interface STPPaymentCardTextField (Testing)
@property(nonatomic, readwrite, weak)UIImageView *brandImageView;
@property(nonatomic, readwrite, weak)STPFormTextField *numberField;
@property(nonatomic, readwrite, weak)STPFormTextField *expirationField;
@property(nonatomic, readwrite, weak)STPFormTextField *cvcField;
@property(nonatomic, readonly, weak)STPFormTextField *currentFirstResponderField;
@property(nonatomic, readwrite, strong)STPPaymentCardTextFieldViewModel *viewModel;
@property(nonatomic, assign)BOOL numberFieldShrunk;
+ (UIImage *)cvcImageForCardBrand:(STPCardBrand)cardBrand;
+ (UIImage *)brandImageForCardBrand:(STPCardBrand)cardBrand;
@end

@interface STPPaymentCardTextFieldTest : XCTestCase
@end

@implementation STPPaymentCardTextFieldTest

- (void)testIntrinsicContentSize {
    STPPaymentCardTextField *textField = [STPPaymentCardTextField new];
    
    UIFont *iOS8SystemFont = [UIFont fontWithName:@"HelveticaNeue" size:18];
    textField.font = iOS8SystemFont;
    XCTAssertEqualWithAccuracy(textField.intrinsicContentSize.height, 44, 0.1);
    XCTAssertEqualWithAccuracy(textField.intrinsicContentSize.width, 266, 0.1);
    
    UIFont *iOS9SystemFont = [UIFont fontWithName:@".SFUIText-Regular" size:18];
    if (iOS9SystemFont) {
        textField.font = iOS9SystemFont;
        XCTAssertEqualWithAccuracy(textField.intrinsicContentSize.height, 44, 0.1);
        XCTAssertEqualWithAccuracy(textField.intrinsicContentSize.width, 279, 0.1);
    }
    
    textField.font = [UIFont fontWithName:@"Avenir" size:44];
    XCTAssertEqualWithAccuracy(textField.intrinsicContentSize.height, 60, 0.1);
    XCTAssertEqualWithAccuracy(textField.intrinsicContentSize.width, 497, 0.1);
}

- (void)testSetCard_numberUnknown {
    STPPaymentCardTextField *sut = [STPPaymentCardTextField new];
    STPCardParams *card = [STPCardParams new];
    NSString *number = @"1";
    card.number = number;
    [sut setCardParams:card];
    NSData *imgData = UIImagePNGRepresentation(sut.brandImageView.image);
    NSData *expectedImgData = UIImagePNGRepresentation([STPPaymentCardTextField brandImageForCardBrand:STPCardBrandUnknown]);

    XCTAssertFalse(sut.numberFieldShrunk);
    XCTAssertTrue([expectedImgData isEqualToData:imgData]);
    XCTAssertEqualObjects(sut.numberField.text, number);
    XCTAssertEqual(sut.expirationField.text.length, (NSUInteger)0);
    XCTAssertEqual(sut.cvcField.text.length, (NSUInteger)0);
    XCTAssertNil(sut.currentFirstResponderField);
}

- (void)testSetCard_expiration {
    STPPaymentCardTextField *sut = [STPPaymentCardTextField new];
    STPCardParams *card = [STPCardParams new];
    card.expMonth = 10;
    card.expYear = 99;
    [sut setCardParams:card];
    NSData *imgData = UIImagePNGRepresentation(sut.brandImageView.image);
    NSData *expectedImgData = UIImagePNGRepresentation([STPPaymentCardTextField brandImageForCardBrand:STPCardBrandUnknown]);

    XCTAssertFalse(sut.numberFieldShrunk);
    XCTAssertTrue([expectedImgData isEqualToData:imgData]);
    XCTAssertEqual(sut.numberField.text.length, (NSUInteger)0);
    XCTAssertEqualObjects(sut.expirationField.text, @"10/99");
    XCTAssertEqual(sut.cvcField.text.length, (NSUInteger)0);
    XCTAssertNil(sut.currentFirstResponderField);
    XCTAssertFalse(sut.isValid);
}

- (void)testSetCard_CVC {
    STPPaymentCardTextField *sut = [STPPaymentCardTextField new];
    STPCardParams *card = [STPCardParams new];
    NSString *cvc = @"123";
    card.cvc = cvc;
    [sut setCardParams:card];
    NSData *imgData = UIImagePNGRepresentation(sut.brandImageView.image);
    NSData *expectedImgData = UIImagePNGRepresentation([STPPaymentCardTextField brandImageForCardBrand:STPCardBrandUnknown]);

    XCTAssertFalse(sut.numberFieldShrunk);
    XCTAssertTrue([expectedImgData isEqualToData:imgData]);
    XCTAssertEqual(sut.numberField.text.length, (NSUInteger)0);
    XCTAssertEqual(sut.expirationField.text.length, (NSUInteger)0);
    XCTAssertEqualObjects(sut.cvcField.text, cvc);
    XCTAssertNil(sut.currentFirstResponderField);
    XCTAssertFalse(sut.isValid);
}

- (void)testSetCard_numberVisa {
    STPPaymentCardTextField *sut = [STPPaymentCardTextField new];
    STPCardParams *card = [STPCardParams new];
    NSString *number = @"4242";
    card.number = number;
    [sut setCardParams:card];
    NSData *imgData = UIImagePNGRepresentation(sut.brandImageView.image);
    NSData *expectedImgData = UIImagePNGRepresentation([STPPaymentCardTextField brandImageForCardBrand:STPCardBrandVisa]);

    XCTAssertFalse(sut.numberFieldShrunk);
    XCTAssertTrue([expectedImgData isEqualToData:imgData]);
    XCTAssertEqualObjects(sut.numberField.text, number);
    XCTAssertEqual(sut.expirationField.text.length, (NSUInteger)0);
    XCTAssertEqual(sut.cvcField.text.length, (NSUInteger)0);
    XCTAssertNil(sut.currentFirstResponderField);
    XCTAssertFalse(sut.isValid);
}

- (void)testSetCard_numberAndExpiration {
    STPPaymentCardTextField *sut = [STPPaymentCardTextField new];
    STPCardParams *card = [STPCardParams new];
    NSString *number = @"4242424242424242";
    card.number = number;
    card.expMonth = 10;
    card.expYear = 99;
    [sut setCardParams:card];
    NSData *imgData = UIImagePNGRepresentation(sut.brandImageView.image);
    NSData *expectedImgData = UIImagePNGRepresentation([STPPaymentCardTextField brandImageForCardBrand:STPCardBrandVisa]);

    XCTAssertTrue(sut.numberFieldShrunk);
    XCTAssertTrue([expectedImgData isEqualToData:imgData]);
    XCTAssertEqualObjects(sut.numberField.text, number);
    XCTAssertEqualObjects(sut.expirationField.text, @"10/99");
    XCTAssertEqual(sut.cvcField.text.length, (NSUInteger)0);
    XCTAssertNil(sut.currentFirstResponderField);
    XCTAssertFalse(sut.isValid);
}

- (void)testSetCard_partialNumberAndExpiration {
    STPPaymentCardTextField *sut = [STPPaymentCardTextField new];
    STPCardParams *card = [STPCardParams new];
    NSString *number = @"42";
    card.number = number;
    card.expMonth = 10;
    card.expYear = 99;
    [sut setCardParams:card];
    NSData *imgData = UIImagePNGRepresentation(sut.brandImageView.image);
    NSData *expectedImgData = UIImagePNGRepresentation([STPPaymentCardTextField brandImageForCardBrand:STPCardBrandVisa]);

    XCTAssertFalse(sut.numberFieldShrunk);
    XCTAssertTrue([expectedImgData isEqualToData:imgData]);
    XCTAssertEqualObjects(sut.numberField.text, number);
    XCTAssertEqualObjects(sut.expirationField.text, @"10/99");
    XCTAssertEqual(sut.cvcField.text.length, (NSUInteger)0);
    XCTAssertNil(sut.currentFirstResponderField);
    XCTAssertFalse(sut.isValid);
}

- (void)testSetCard_numberAndCVC {
    STPPaymentCardTextField *sut = [STPPaymentCardTextField new];
    STPCardParams *card = [STPCardParams new];
    NSString *number = @"378282246310005";
    NSString *cvc = @"123";
    card.number = number;
    card.cvc = cvc;
    [sut setCardParams:card];
    NSData *imgData = UIImagePNGRepresentation(sut.brandImageView.image);
    NSData *expectedImgData = UIImagePNGRepresentation([STPPaymentCardTextField brandImageForCardBrand:STPCardBrandAmex]);

    XCTAssertTrue(sut.numberFieldShrunk);
    XCTAssertTrue([expectedImgData isEqualToData:imgData]);
    XCTAssertEqualObjects(sut.numberField.text, number);
    XCTAssertEqual(sut.expirationField.text.length, (NSUInteger)0);
    XCTAssertEqualObjects(sut.cvcField.text, cvc);
    XCTAssertNil(sut.currentFirstResponderField);
    XCTAssertFalse(sut.isValid);
}

- (void)testSetCard_expirationAndCVC {
    STPPaymentCardTextField *sut = [STPPaymentCardTextField new];
    STPCardParams *card = [STPCardParams new];
    NSString *cvc = @"123";
    card.expMonth = 10;
    card.expYear = 99;
    card.cvc = cvc;
    [sut setCardParams:card];
    NSData *imgData = UIImagePNGRepresentation(sut.brandImageView.image);
    NSData *expectedImgData = UIImagePNGRepresentation([STPPaymentCardTextField brandImageForCardBrand:STPCardBrandUnknown]);

    XCTAssertFalse(sut.numberFieldShrunk);
    XCTAssertTrue([expectedImgData isEqualToData:imgData]);
    XCTAssertEqual(sut.numberField.text.length, (NSUInteger)0);
    XCTAssertEqualObjects(sut.expirationField.text, @"10/99");
    XCTAssertEqualObjects(sut.cvcField.text, cvc);
    XCTAssertNil(sut.currentFirstResponderField);
    XCTAssertFalse(sut.isValid);
}

- (void)testSetCard_completeCard {
    STPPaymentCardTextField *sut = [STPPaymentCardTextField new];
    STPCardParams *card = [STPCardParams new];
    NSString *number = @"4242424242424242";
    NSString *cvc = @"123";
    card.number = number;
    card.expMonth = 10;
    card.expYear = 99;
    card.cvc = cvc;
    [sut setCardParams:card];
    NSData *imgData = UIImagePNGRepresentation(sut.brandImageView.image);
    NSData *expectedImgData = UIImagePNGRepresentation([STPPaymentCardTextField brandImageForCardBrand:STPCardBrandVisa]);

    XCTAssertTrue(sut.numberFieldShrunk);
    XCTAssertTrue([expectedImgData isEqualToData:imgData]);
    XCTAssertEqualObjects(sut.numberField.text, number);
    XCTAssertEqualObjects(sut.expirationField.text, @"10/99");
    XCTAssertEqualObjects(sut.cvcField.text, cvc);
    XCTAssertNil(sut.currentFirstResponderField);
    XCTAssertTrue(sut.isValid);
}

- (void)testSetCard_empty {
    STPPaymentCardTextField *sut = [STPPaymentCardTextField new];
    sut.numberField.text = @"4242424242424242";
    sut.cvcField.text = @"123";
    sut.expirationField.text = @"10/99";
    STPCardParams *card = [STPCardParams new];
    [sut setCardParams:card];
    NSData *imgData = UIImagePNGRepresentation(sut.brandImageView.image);
    NSData *expectedImgData = UIImagePNGRepresentation([STPPaymentCardTextField brandImageForCardBrand:STPCardBrandUnknown]);

    XCTAssertFalse(sut.numberFieldShrunk);
    XCTAssertTrue([expectedImgData isEqualToData:imgData]);
    XCTAssertEqual(sut.numberField.text.length, (NSUInteger)0);
    XCTAssertEqual(sut.expirationField.text.length, (NSUInteger)0);
    XCTAssertEqual(sut.cvcField.text.length, (NSUInteger)0);
    XCTAssertNil(sut.currentFirstResponderField);
    XCTAssertFalse(sut.isValid);
}

- (void)testSetCard_addressFields {
    STPPaymentCardTextField *sut = [STPPaymentCardTextField new];

    STPCardParams *cardParams = [STPCardParams new];
    cardParams.name = @"John S";
    cardParams.addressLine1 = @"123 Main St";
    cardParams.addressLine2 = @"#3B";
    cardParams.addressCity = @"San Francisco";
    cardParams.addressState = @"CA";
    cardParams.addressZip = @"12345";
    cardParams.addressCountry = @"US";
    sut.cardParams = cardParams;

    XCTAssertEqualObjects(sut.cardParams.name, @"John S");
    XCTAssertEqualObjects(sut.cardParams.addressLine1, @"123 Main St");
    XCTAssertEqualObjects(sut.cardParams.addressLine2, @"#3B");
    XCTAssertEqualObjects(sut.cardParams.addressCity, @"San Francisco");
    XCTAssertEqualObjects(sut.cardParams.addressState, @"CA");
    XCTAssertEqualObjects(sut.cardParams.addressZip, @"12345");
    XCTAssertEqualObjects(sut.cardParams.addressCountry, @"US");
}

- (void)testSettingTextUpdatesViewModelText {
    STPPaymentCardTextField *sut = [STPPaymentCardTextField new];
    sut.numberField.text = @"4242424242424242";
    XCTAssertEqualObjects(sut.viewModel.cardNumber, sut.numberField.text);

    sut.cvcField.text = @"123";
    XCTAssertEqualObjects(sut.viewModel.cvc, sut.cvcField.text);

    sut.expirationField.text = @"10/99";
    XCTAssertEqualObjects(sut.viewModel.rawExpiration, sut.expirationField.text);
    XCTAssertEqualObjects(sut.viewModel.expirationMonth, @"10");
    XCTAssertEqualObjects(sut.viewModel.expirationYear, @"99");
}

- (void)testSettingTextUpdatesCardParams {
    STPPaymentCardTextField *sut = [STPPaymentCardTextField new];
    sut.numberField.text = @"4242424242424242";
    sut.cvcField.text = @"123";
    sut.expirationField.text = @"10/99";

    STPCardParams *params = sut.cardParams;
    XCTAssertNotNil(params);
    XCTAssertEqualObjects(params.number, @"4242424242424242");
    XCTAssertEqualObjects(params.cvc, @"123");
    XCTAssertEqual((int)params.expMonth, 10);
    XCTAssertEqual((int)params.expYear, 99);
}

@end

@interface STPPaymentCardTextFieldUITests : XCTestCase
@property(nonatomic)UIWindow *window;
@property(nonatomic)STPPaymentCardTextField *sut;
@end

@implementation STPPaymentCardTextFieldUITests

- (void)setUp {
    [super setUp];
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    STPPaymentCardTextField *textField = [[STPPaymentCardTextField alloc] initWithFrame:self.window.bounds];
    textField.numberField.skipsReloadingInputViews = YES;
    textField.expirationField.skipsReloadingInputViews = YES;
    textField.cvcField.skipsReloadingInputViews = YES;
    [self.window addSubview:textField];
    XCTAssertTrue([textField.numberField canBecomeFirstResponder], @"text field cannot become first responder");
    self.sut = textField;
}

#pragma mark - UI Tests

- (void)testSetCard_allFields_whileEditingNumber {
    XCTAssertTrue([self.sut.numberField becomeFirstResponder], @"text field is not first responder");
    STPCardParams *card = [STPCardParams new];
    NSString *number = @"4242424242424242";
    NSString *cvc = @"123";
    card.number = number;
    card.expMonth = 10;
    card.expYear = 99;
    card.cvc = cvc;
    [self.sut setCardParams:card];
    NSData *imgData = UIImagePNGRepresentation(self.sut.brandImageView.image);
    NSData *expectedImgData = UIImagePNGRepresentation([STPPaymentCardTextField cvcImageForCardBrand:STPCardBrandVisa]);
    
    XCTAssertTrue(self.sut.numberFieldShrunk);
    XCTAssertTrue([expectedImgData isEqualToData:imgData]);
    XCTAssertEqualObjects(self.sut.numberField.text, number);
    XCTAssertEqualObjects(self.sut.expirationField.text, @"10/99");
    XCTAssertEqualObjects(self.sut.cvcField.text, cvc);
    XCTAssertTrue([self.sut.cvcField isFirstResponder]);
    XCTAssertTrue(self.sut.isValid);
}

- (void)testSetCard_partialNumberAndExpiration_whileEditingExpiration {
    XCTAssertTrue([self.sut.expirationField becomeFirstResponder], @"text field is not first responder");
    STPCardParams *card = [STPCardParams new];
    NSString *number = @"42";
    card.number = number;
    card.expMonth = 10;
    card.expYear = 99;
    [self.sut setCardParams:card];
    NSData *imgData = UIImagePNGRepresentation(self.sut.brandImageView.image);
    NSData *expectedImgData = UIImagePNGRepresentation([STPPaymentCardTextField brandImageForCardBrand:STPCardBrandVisa]);
    
    XCTAssertFalse(self.sut.numberFieldShrunk);
    XCTAssertTrue([expectedImgData isEqualToData:imgData]);
    XCTAssertEqualObjects(self.sut.numberField.text, number);
    XCTAssertEqualObjects(self.sut.expirationField.text, @"10/99");
    XCTAssertEqual(self.sut.cvcField.text.length, (NSUInteger)0);
    XCTAssertTrue([self.sut.numberField isFirstResponder]);
    XCTAssertFalse(self.sut.isValid);
}

- (void)testSetCard_number_whileEditingCVC {
    XCTAssertTrue([self.sut.cvcField becomeFirstResponder], @"text field is not first responder");
    STPCardParams *card = [STPCardParams new];
    NSString *number = @"4242424242424242";
    card.number = number;
    [self.sut setCardParams:card];
    NSData *imgData = UIImagePNGRepresentation(self.sut.brandImageView.image);
    NSData *expectedImgData = UIImagePNGRepresentation([STPPaymentCardTextField brandImageForCardBrand:STPCardBrandVisa]);
    
    XCTAssertTrue(self.sut.numberFieldShrunk);
    XCTAssertTrue([expectedImgData isEqualToData:imgData]);
    XCTAssertEqualObjects(self.sut.numberField.text, number);
    XCTAssertEqual(self.sut.expirationField.text.length, (NSUInteger)0);
    XCTAssertEqual(self.sut.cvcField.text.length, (NSUInteger)0);
    XCTAssertTrue([self.sut.expirationField isFirstResponder]);
    XCTAssertFalse(self.sut.isValid);
}

- (void)testSetCard_empty_whileEditingNumber {
    XCTAssertTrue([self.sut.numberField becomeFirstResponder], @"text field is not first responder");
    self.sut.numberField.text = @"4242424242424242";
    self.sut.cvcField.text = @"123";
    self.sut.expirationField.text = @"10/99";
    STPCardParams *card = [STPCardParams new];
    [self.sut setCardParams:card];
    NSData *imgData = UIImagePNGRepresentation(self.sut.brandImageView.image);
    NSData *expectedImgData = UIImagePNGRepresentation([STPPaymentCardTextField brandImageForCardBrand:STPCardBrandUnknown]);
    
    XCTAssertFalse(self.sut.numberFieldShrunk);
    XCTAssertTrue([expectedImgData isEqualToData:imgData]);
    XCTAssertEqual(self.sut.numberField.text.length, (NSUInteger)0);
    XCTAssertEqual(self.sut.expirationField.text.length, (NSUInteger)0);
    XCTAssertEqual(self.sut.cvcField.text.length, (NSUInteger)0);
    XCTAssertTrue([self.sut.numberField isFirstResponder]);
    XCTAssertFalse(self.sut.isValid);
}


@end
