//
//  STPPaymentCardTextFieldUITests.m
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 1/12/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Stripe/Stripe.h>

@interface STPPaymentCardTextField (Testing)
@property(nonatomic, readwrite, weak)UIImageView *brandImageView;
@property(nonatomic, readwrite, weak)UITextField *numberField;
@property(nonatomic, readwrite, weak)UITextField *expirationField;
@property(nonatomic, readwrite, weak)UITextField *cvcField;
@property(nonatomic, readwrite, weak)UITextField *selectedField;
@property(nonatomic, assign)BOOL numberFieldShrunk;
+ (UIImage *)cvcImageForCardBrand:(STPCardBrand)cardBrand;
+ (UIImage *)brandImageForCardBrand:(STPCardBrand)cardBrand;
@end

@interface STPPaymentCardTextFieldUITests : XCTestCase
@property (nonatomic, strong) STPPaymentCardTextField *sut;
@property (nonatomic, strong) UIViewController *viewController;
@end

@implementation STPPaymentCardTextFieldUITests

- (void)setUp {
    [super setUp];
    self.viewController = [UIViewController new];
    self.sut = [STPPaymentCardTextField new];
    [self.viewController.view addSubview:self.sut];
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    window.rootViewController = self.viewController;
}

- (void)testSetCard_allFields_whileEditingNumber {
    XCTAssertTrue([self.sut.numberField becomeFirstResponder]);
    STPCardParams *card = [STPCardParams new];
    NSString *number = @"4242424242424242";
    NSString *cvc = @"123";
    card.number = number;
    card.expMonth = 10;
    card.expYear = 99;
    card.cvc = cvc;
    [self.sut setCard:card];
    NSData *imgData = UIImagePNGRepresentation(self.sut.brandImageView.image);
    NSData *expectedImgData = UIImagePNGRepresentation([STPPaymentCardTextField cvcImageForCardBrand:STPCardBrandVisa]);

    XCTAssertTrue(self.sut.numberFieldShrunk);
    XCTAssertTrue([expectedImgData isEqualToData:imgData]);
    XCTAssertEqualObjects(self.sut.numberField.text, number);
    XCTAssertEqualObjects(self.sut.expirationField.text, @"10/99");
    XCTAssertEqualObjects(self.sut.cvcField.text, cvc);
    XCTAssertEqualObjects(self.sut.selectedField, self.sut.cvcField);
    XCTAssertTrue([self.sut.cvcField isFirstResponder]);
    XCTAssertTrue(self.sut.isValid);
}

- (void)testSetCard_partialNumberAndExpiration_whileEditingExpiration {
    XCTAssertTrue([self.sut.expirationField becomeFirstResponder]);
    STPCardParams *card = [STPCardParams new];
    NSString *number = @"42";
    card.number = number;
    card.expMonth = 10;
    card.expYear = 99;
    [self.sut setCard:card];
    NSData *imgData = UIImagePNGRepresentation(self.sut.brandImageView.image);
    NSData *expectedImgData = UIImagePNGRepresentation([STPPaymentCardTextField brandImageForCardBrand:STPCardBrandVisa]);

    XCTAssertTrue(self.sut.numberFieldShrunk);
    XCTAssertTrue([expectedImgData isEqualToData:imgData]);
    XCTAssertEqualObjects(self.sut.numberField.text, number);
    XCTAssertEqualObjects(self.sut.expirationField.text, @"10/99");
    XCTAssertEqual(self.sut.cvcField.text.length, (NSUInteger)0);
    XCTAssertEqualObjects(self.sut.selectedField, self.sut.cvcField);
    XCTAssertTrue([self.sut.cvcField isFirstResponder]);
    XCTAssertFalse(self.sut.isValid);
}

- (void)testSetCard_number_whileEditingCVC {
    XCTAssertTrue([self.sut.cvcField becomeFirstResponder]);
    STPCardParams *card = [STPCardParams new];
    NSString *number = @"4242424242424242";
    card.number = number;
    [self.sut setCard:card];
    NSData *imgData = UIImagePNGRepresentation(sut.brandImageView.image);
    NSData *expectedImgData = UIImagePNGRepresentation([STPPaymentCardTextField brandImageForCardBrand:STPCardBrandVisa]);

    XCTAssertTrue(self.sut.numberFieldShrunk);
    XCTAssertTrue([expectedImgData isEqualToData:imgData]);
    XCTAssertEqualObjects(self.sut.numberField.text, number);
    XCTAssertEqual(self.sut.expirationField.text.length, (NSUInteger)0);
    XCTAssertEqual(self.sut.cvcField.text.length, (NSUInteger)0);
    XCTAssertEqualObjects(self.sut.selectedField, self.sut.expirationField);
    XCTAssertTrue([self.sut.expirationField isFirstResponder]);
    XCTAssertFalse(sut.isValid);
}

@end
