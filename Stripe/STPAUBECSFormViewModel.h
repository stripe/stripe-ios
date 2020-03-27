//
//  STPAUBECSFormViewModel.h
//  StripeiOS
//
//  Created by Cameron Sabol on 3/12/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@class STPPaymentMethodAUBECSDebitParams;
@class STPPaymentMethodParams;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, STPAUBECSFormViewField) {
    STPAUBECSFormViewFieldName,
    STPAUBECSFormViewFieldEmail,
    STPAUBECSFormViewFieldBSBNumber,
    STPAUBECSFormViewFieldAccountNumber,
};

@interface STPAUBECSFormViewModel : NSObject

@property (nonatomic, nullable, copy) NSString *name;
@property (nonatomic, nullable, copy) NSString *email;

@property (nonatomic, nullable, copy) NSString *bsbNumber;
@property (nonatomic, nullable, copy) NSString *accountNumber;

@property (nonatomic, nullable, readonly, copy) STPPaymentMethodAUBECSDebitParams *becsDebitParams;
@property (nonatomic, nullable, readonly, copy) STPPaymentMethodParams *paymentMethodParams;


- (NSString *)formattedStringForInput:(NSString *)input inField:(STPAUBECSFormViewField)field;
- (nullable NSString *)bsbLabelForInput:(nullable NSString *)input editing:(BOOL)editing isErrorString:(out BOOL *)isErrorString;
- (UIImage *)bankIconForInput:(nullable NSString *)input;

- (BOOL)isFieldCompleteWithInput:(NSString *)input inField:(STPAUBECSFormViewField)field editing:(BOOL)editing;
- (BOOL)isInputValid:(NSString *)input forField:(STPAUBECSFormViewField)field editing:(BOOL)editing;


@end

NS_ASSUME_NONNULL_END
