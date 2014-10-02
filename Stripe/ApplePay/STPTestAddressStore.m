//
//  STPTestAddressStore.m
//  StripeExample
//
//  Created by Jack Flintermann on 9/30/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import "STPTestAddressStore.h"

@interface STPTestAddressStore()
@property(nonatomic)NSArray *allItems;
@end

@implementation STPTestAddressStore

@synthesize selectedItem;

- (instancetype)init {
    self = [super init];
    if (self) {
        self.allItems = @[
                          @{
                              @"name": @"Apple HQ",
                              @"line1": @"1 Infinite Loop",
                              @"line2": @"",
                              @"city": @"Cupertino",
                              @"state": @"CA",
                              @"zip": @"95014",
                              @"country": @"US",
                              },
                          @{
                              @"name": @"The White House",
                              @"line1": @"1600 Pennsylvania Ave NW",
                              @"line2": @"",
                              @"city": @"Washington",
                              @"state": @"DC",
                              @"zip": @"20500",
                              @"country": @"US",
                              },
                          @{
                              @"name": @"Buckingham Palace",
                              @"line1": @"SW1A 1AA",
                              @"line2": @"",
                              @"city": @"London",
                              @"country": @"UK",
                              },
                          ];
        self.selectedItem = self.allItems[0];
    }
    return self;
}

- (NSArray *)descriptionsForItem:(id)item {
    return @[item[@"name"], item[@"line1"]];
}

//- (ABRecordRef)recordFromDictionary:(NSDictionary *)dict sanitize:(BOOL)sanitize {
////    ABRecordRef record = ABPersonCreate();
////    ABRecordSetValue(record, kABPersonFirstNameProperty, (__bridge CFTypeRef)(dict[@"name"]), nil);
////    ABRecordSetValue(record, kABPersonAddressProperty, (__bridge CFTypeRef)(dict[@"line1"]), nil);
//    return nil;
//}

@end
