//
//  STPBankPickerDataSource.h
//  Stripe
//
//  Created by Ben Guo on 2/10/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPPickerTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPBankPickerDataSource : NSObject <STPPickerDataSource>

+ (STPBankPickerDataSource *)iDEALBankDataSource;

@end

NS_ASSUME_NONNULL_END
