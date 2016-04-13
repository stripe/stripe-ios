//
//  STPAddress.h
//  Stripe
//
//  Created by Ben Guo on 4/13/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

@interface STPAddress : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *street;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *state;
@property (nonatomic, strong) NSString *postalCode;
@property (nonatomic, strong) NSString *country;
@property (nonatomic, strong) NSString *phone;
@property (nonatomic, strong) NSString *email;

- (instancetype)initWithABRecord:(ABRecordRef)record;

@end

#pragma clang diagnostic pop
