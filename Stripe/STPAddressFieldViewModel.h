//
//  STPAddressFieldViewModel.h
//  Stripe
//
//  Created by Ben Guo on 4/13/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, STPAddressFieldViewModelType) {
    STPAddressFieldViewModelTypeText,
    STPAddressFieldViewModelTypePhoneNumber,
    STPAddressFieldViewModelTypeEmail,
    STPAddressFieldViewModelTypeZip,
    STPAddressFieldViewModelTypeCountry,
};

@interface STPAddressFieldViewModel : NSObject

+ (instancetype)viewModelWithLabel:(NSString *)label
                       placeholder:(NSString *)placeholder
                          contents:(NSString *)contents
                              type:(STPAddressFieldViewModelType)type;

@property (nonatomic, strong, readonly) NSString *label;
@property (nonatomic, strong, readonly) NSString *placeholder;
@property (nonatomic, assign, readonly) STPAddressFieldViewModelType type;
@property (nonatomic, strong) NSString *contents;
@property (nonatomic, readonly) BOOL isValid;

@end
