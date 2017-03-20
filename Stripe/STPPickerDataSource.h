//
//  STPPickerDataSource.h
//  Stripe
//
//  Created by Ben Guo on 3/20/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol STPPickerDataSource <NSObject>

- (NSInteger)numberOfRows;
- (NSInteger)indexOfValue:(NSString *)value;
- (NSString *)valueForRow:(NSInteger)row;
- (NSString *)titleForRow:(NSInteger)row;

@end
