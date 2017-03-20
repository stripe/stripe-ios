//
//  STPSourceInfoDataSource.h
//  Stripe
//
//  Created by Ben Guo on 3/2/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Stripe/Stripe.h>

@protocol STPPickerDataSource;
@class STPTextFieldTableViewCell;

@interface STPSourceInfoDataSource : NSObject

@property(nonatomic)NSString *title;
@property(nonatomic)STPSourceParams *sourceParams;
@property(nonatomic)NSArray<STPTextFieldTableViewCell *>*cells;
@property(nonatomic)id<STPPickerDataSource>pickerDataSource;

- (instancetype)initWithSourceParams:(STPSourceParams *)sourceParams;
- (STPSourceParams *)completedSourceParams;

@end
