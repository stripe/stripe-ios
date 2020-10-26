//
//  STPAddressViewModel.h
//  Stripe
//
//  Created by Jack Flintermann on 4/21/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STPAddress.h"
#import "STPAddressFieldTableViewCell.h"

@class STPAddressViewModel;

@protocol STPAddressViewModelDelegate <NSObject>

- (void)addressViewModelDidChange:(STPAddressViewModel *)addressViewModel;
- (void)addressViewModel:(STPAddressViewModel *)addressViewModel addedCellAtIndex:(NSUInteger)index;
- (void)addressViewModel:(STPAddressViewModel *)addressViewModel removedCellAtIndex:(NSUInteger)index;
- (void)addressViewModelWillUpdate:(STPAddressViewModel *)addressViewModel;
- (void)addressViewModelDidUpdate:(STPAddressViewModel *)addressViewModel;

@end

@interface STPAddressViewModel : NSObject

@property (nonatomic, readonly) NSArray<STPAddressFieldTableViewCell *> *addressCells;
@property (nonatomic, weak) id<STPAddressViewModelDelegate>delegate;
@property (nonatomic) STPAddress *address;
@property (nonatomic, copy, readwrite) NSSet<NSString *> *availableCountries;
@property (nonatomic, readonly) BOOL isValid;

- (instancetype)initWithRequiredBillingFields:(STPBillingAddressFields)requiredBillingAddressFields;
- (instancetype)initWithRequiredShippingFields:(NSSet<STPContactField> *)requiredShippingAddressFields;

/* The default value of availableCountries is nil, which will allow all known countries. */
- (instancetype)initWithRequiredBillingFields:(STPBillingAddressFields)requiredBillingAddressFields availableCountries:(NSSet<NSString *> *)availableCountries;
- (instancetype)initWithRequiredShippingFields:(NSSet<STPContactField> *)requiredShippingAddressFields availableCountries:(NSSet<NSString *> *)availableCountries;
- (STPAddressFieldTableViewCell *)cellAtIndex:(NSInteger)index;

@end
