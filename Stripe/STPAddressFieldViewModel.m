//
//  STPAddressFieldViewModel.m
//  Stripe
//
//  Created by Ben Guo on 4/13/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPAddressFieldViewModel.h"
#import "STPPhoneNumberValidator.h"
#import "STPEmailAddressValidator.h"
#import "STPPostalCodeValidator.h"

@interface STPAddressFieldViewModel()

@property (nonatomic, strong) NSString *label;
@property (nonatomic, strong) NSString *placeholder;
@property (nonatomic, assign) STPAddressFieldViewModelType type;

@end

@implementation STPAddressFieldViewModel

+ (instancetype)viewModelWithLabel:(NSString *)label
                       placeholder:(NSString *)placeholder
                          contents:(NSString *)contents
                              type:(STPAddressFieldViewModelType)type {
    STPAddressFieldViewModel *viewModel = [STPAddressFieldViewModel new];
    viewModel.label = label;
    viewModel.placeholder = placeholder;
    viewModel.contents = contents;
    viewModel.type = type;
    return viewModel;
}

- (BOOL)isValid {
    switch (self.type) {
        case STPAddressFieldViewModelTypeText:
            return [self.contents length] > 0;
            break;
        case STPAddressFieldViewModelTypeOptionalText:
            return YES;
            break;
        case STPAddressFieldViewModelTypePhoneNumber:
            return [STPPhoneNumberValidator stringIsValidPhoneNumber:self.contents];
            break;
        case STPAddressFieldViewModelTypeEmail:
            return [STPEmailAddressValidator stringIsValidEmailAddress:self.contents];
            break;
        case STPAddressFieldViewModelTypeCountry:
            // TODO: country validation
            return [self.contents length] > 0;
            break;
        case STPAddressFieldViewModelTypeZip:
            return [STPPostalCodeValidator stringIsValidPostalCode:self.contents];
            break;
    }
}

@end
