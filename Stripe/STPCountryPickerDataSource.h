//
//  STPCountryPickerDataSource.h
//  Stripe
//
//  Created by Ben Guo on 2/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPPickerDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPCountryPickerDataSource : NSObject <STPPickerDataSource>

@property (nonatomic) NSArray<NSString *>*countryCodes;

+ (NSArray<NSString *>*)sepaCountryCodes;

- (instancetype)initWithCountryCodes:(NSArray<NSString *>*)countryCodes;

@end

NS_ASSUME_NONNULL_END
