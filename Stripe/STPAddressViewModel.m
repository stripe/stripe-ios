//
//  STPAddressViewModel.m
//  Stripe
//
//  Created by Jack Flintermann on 4/21/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPAddressViewModel.h"
#import "NSArray+Stripe_BoundSafe.h"
#import "STPPostalCodeValidator.h"

typedef NS_ENUM(NSUInteger, STPAddressType) {
    STPAddressTypeBilling,
    STPAddressTypeShipping,
    STPAddressTypeSEPADebit,
};

@interface STPAddressViewModel()<STPAddressFieldTableViewCellDelegate>
@property(nonatomic)STPAddressType addressType;
@property(nonatomic)STPBillingAddressFields requiredBillingAddressFields;
@property(nonatomic)PKAddressField requiredShippingAddressFields;
@property(nonatomic)NSArray<STPAddressFieldTableViewCell *> *addressCells;
@property(nonatomic)BOOL showingPostalCodeCell;
@end

@implementation STPAddressViewModel

@synthesize addressFieldTableViewCountryCode = _addressFieldTableViewCountryCode;

- (instancetype)initWithRequiredBillingFields:(STPBillingAddressFields)requiredBillingAddressFields {
    self = [super init];
    if (self) {
        _addressType = STPAddressTypeBilling;
        _requiredBillingAddressFields = requiredBillingAddressFields;
        switch (requiredBillingAddressFields) {
            case STPBillingAddressFieldsNone:
                _addressCells = @[];
                break;
            case STPBillingAddressFieldsZip:
                _addressCells = @[
                                  // Postal code cell will be added later if necessary
                                  ];
                break;
            case STPBillingAddressFieldsFull:
                _addressCells = @[
                                  [[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeName contents:@"" lastInList:NO delegate:self],
                                  [[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeLine1 contents:@"" lastInList:NO delegate:self],
                                  [[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeLine2 contents:@"" lastInList:NO delegate:self],
                                  [[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeCity contents:@"" lastInList:NO delegate:self],
                                  [[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeState contents:@"" lastInList:NO delegate:self],
                                  // Postal code cell will be added later if necessary
                                  [[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeCountry contents:_addressFieldTableViewCountryCode lastInList:YES delegate:self],
                                  ];
                break;
        }
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithRequiredShippingFields:(PKAddressField)requiredShippingAddressFields {
    self = [super init];
    if (self) {
        _addressType = STPAddressTypeShipping;
        _requiredShippingAddressFields = requiredShippingAddressFields;
        NSMutableArray *cells = [NSMutableArray new];
        if (requiredShippingAddressFields & PKAddressFieldName) {
            [cells addObject:[[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeName contents:@"" lastInList:NO delegate:self]];
        }
        if (requiredShippingAddressFields & PKAddressFieldEmail) {
            [cells addObject:[[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeEmail contents:@"" lastInList:NO delegate:self]];
        }
        if (requiredShippingAddressFields & PKAddressFieldPostalAddress) {
            NSMutableArray *postalCells = [@[
                                             [[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeName contents:@"" lastInList:NO delegate:self],
                                             [[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeLine1 contents:@"" lastInList:NO delegate:self],
                                             [[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeLine2 contents:@"" lastInList:NO delegate:self],
                                             [[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeCity contents:@"" lastInList:NO delegate:self],
                                             [[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeState contents:@"" lastInList:NO delegate:self],
                                             // Postal code cell will be added later if necessary
                                             [[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeCountry contents:_addressFieldTableViewCountryCode lastInList:NO delegate:self],
                                             ] mutableCopy];
            if (requiredShippingAddressFields & PKAddressFieldName) {
                [postalCells removeObjectAtIndex:0];
            }
            [cells addObjectsFromArray:postalCells];
        }
        if (requiredShippingAddressFields & PKAddressFieldPhone) {
            [cells addObject:[[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypePhone contents:@"" lastInList:NO delegate:self]];
        }
        STPAddressFieldTableViewCell *lastCell = [cells lastObject];
        if (lastCell != nil) {
            lastCell.lastInList = YES;
        }
        _addressCells = [cells copy];
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithSEPADebitFields {
    self = [super init];
    if (self) {
        _addressType = STPAddressTypeSEPADebit;
        _addressCells = @[
                          [[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeLine1 contents:@"" lastInList:NO delegate:self],
                          [[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeCity contents:@"" lastInList:NO delegate:self],
                          // Postal code cell will be added later if necessary
                          [[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeSEPACountry contents:_addressFieldTableViewCountryCode lastInList:YES delegate:self],
                          ];
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _addressFieldTableViewCountryCode = [[NSLocale autoupdatingCurrentLocale] objectForKey:NSLocaleCountryCode];
    [self updatePostalCodeFieldIfNecessary];
}

- (void)updatePostalCodeFieldIfNecessary {
    if (![self displaysPostalCodeField]) {
        return;
    }
    STPPostalCodeType postalCodeType = [STPPostalCodeValidator postalCodeTypeForCountryCode:_addressFieldTableViewCountryCode];
    if (self.addressType == STPAddressTypeSEPADebit) {
        postalCodeType = [STPPostalCodeValidator postalCodeTypeForSEPACountryCode:_addressFieldTableViewCountryCode];
    }
    BOOL shouldBeShowingPostalCode = (postalCodeType != STPCountryPostalCodeTypeNotRequired);
    // Add postal code field
    if (shouldBeShowingPostalCode && !self.showingPostalCodeCell) {
        NSNumber *previousFieldType = [self fieldTypeAbovePostalCode];
        NSUInteger previousFieldIndex = NSNotFound;
        if (previousFieldType) {
            previousFieldIndex = [self.addressCells indexOfObjectPassingTest:^BOOL(STPAddressFieldTableViewCell *obj, NSUInteger __unused idx, BOOL *__unused stop) {
                return (obj.type == [previousFieldType integerValue]);
            }];
        }

        STPAddressFieldTableViewCell *zipCell = [[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeZip contents:@"" lastInList:NO delegate:self];
        NSUInteger zipFieldIndex;
        if (previousFieldIndex != NSNotFound) {
            zipFieldIndex = previousFieldIndex + 1;
        } else {
            zipFieldIndex = 0;
        }
        NSMutableArray<STPAddressFieldTableViewCell *> *mutableAddressCells = self.addressCells.mutableCopy;
        [mutableAddressCells insertObject:zipCell atIndex:zipFieldIndex];
        NSUInteger count = mutableAddressCells.count;
        for (NSUInteger i = 0; i < count; i++) {
            STPAddressFieldTableViewCell *cell = [mutableAddressCells stp_boundSafeObjectAtIndex:i];
            cell.lastInList = (i == count - 1);
        }
        self.addressCells = mutableAddressCells.copy;
        [self.delegate addressViewModel:self addedCellAtIndex:zipFieldIndex];
        [self.delegate addressViewModelDidChange:self];
    }
    // Remove postal code field
    else if (!shouldBeShowingPostalCode && self.showingPostalCodeCell) {
        NSUInteger zipFieldIndex = [self.addressCells indexOfObjectPassingTest:^BOOL(STPAddressFieldTableViewCell *obj, NSUInteger __unused idx, BOOL * __unused stop) {
            return (obj.type == STPAddressFieldTypeZip);
        }];

        if (zipFieldIndex != NSNotFound) {
            NSMutableArray<STPAddressFieldTableViewCell *> *mutableAddressCells = self.addressCells.mutableCopy;
            [mutableAddressCells removeObjectAtIndex:zipFieldIndex];
            self.addressCells = mutableAddressCells.copy;
            [self.delegate addressViewModel:self removedCellAtIndex:zipFieldIndex];
            [self.delegate addressViewModelDidChange:self];
        }
    }
    self.showingPostalCodeCell = shouldBeShowingPostalCode;
}

/// Returns a boxed STPAddressFieldType. If nil, the postal code field is the first field.
- (NSNumber *)fieldTypeAbovePostalCode {
    switch (self.addressType) {
        case STPAddressTypeBilling:
            if (self.requiredBillingAddressFields == STPBillingAddressFieldsZip) {
                return nil;
            } else {
                return @(STPAddressFieldTypeState);
            }
        case STPAddressTypeShipping:
            return @(STPAddressFieldTypeState);
        case STPAddressTypeSEPADebit:
            return @(STPAddressFieldTypeCity);
    }
}

- (BOOL)displaysPostalCodeField {
    switch (self.addressType) {
        case STPAddressTypeBilling:
            return ((self.requiredBillingAddressFields == STPBillingAddressFieldsFull) ||
                    (self.requiredBillingAddressFields == STPBillingAddressFieldsZip));
        case STPAddressTypeShipping:
            return ((self.requiredShippingAddressFields & PKAddressFieldPostalAddress) == PKAddressFieldPostalAddress);
        case STPAddressTypeSEPADebit:
            return YES;
    }
}

- (STPAddressFieldTableViewCell *)cellAtIndex:(NSInteger)index {
    return self.addressCells[index];
}

- (void)addressFieldTableViewCellDidReturn:(STPAddressFieldTableViewCell *)cell {
    [[self cellAfterCell:cell] becomeFirstResponder];
}

- (void)addressFieldTableViewCellDidBackspaceOnEmpty:(STPAddressFieldTableViewCell *)cell {
    if ([self.addressCells indexOfObject:cell] == 0) {
        [self.previousField becomeFirstResponder];
    } else {
        [[self cellBeforeCell:cell] becomeFirstResponder];
    }
}

- (void)addressFieldTableViewCellDidUpdateText:(__unused STPAddressFieldTableViewCell *)cell {
    [self.delegate addressViewModelDidChange:self];
}

- (BOOL)isValid {
    switch (self.addressType) {
        case STPAddressTypeBilling:
            return [self.address containsRequiredFields:self.requiredBillingAddressFields];
        case STPAddressTypeShipping:
            return [self.address containsRequiredShippingAddressFields:self.requiredShippingAddressFields];
        case STPAddressTypeSEPADebit:
            return [self.address containsRequiredSEPADebitFields];
        default:
            return YES;
    }
}

- (void)setAddressFieldTableViewCountryCode:(NSString *)addressFieldTableViewCountryCode {
    if (addressFieldTableViewCountryCode.length > 0 // ignore if someone passing in nil or empty and keep our current setup
        && ![_addressFieldTableViewCountryCode isEqualToString:addressFieldTableViewCountryCode]) {
        _addressFieldTableViewCountryCode = addressFieldTableViewCountryCode.copy;
        [self updatePostalCodeFieldIfNecessary];
        for (STPAddressFieldTableViewCell *cell in self.addressCells) {
            [cell delegateCountryCodeDidChange:_addressFieldTableViewCountryCode];
        }
    }
}

- (void)setAddress:(STPAddress *)address {
    self.addressFieldTableViewCountryCode = address.country;
    
    for (STPAddressFieldTableViewCell *cell in self.addressCells) {
        switch (cell.type) {
            case STPAddressFieldTypeName:
                cell.contents = address.name;
                break;
            case STPAddressFieldTypeLine1:
                cell.contents = address.line1;
                break;
            case STPAddressFieldTypeLine2:
                cell.contents = address.line2;
                break;
            case STPAddressFieldTypeCity:
                cell.contents = address.city;
                break;
            case STPAddressFieldTypeState:
                cell.contents = address.state;
                break;
            case STPAddressFieldTypeZip:
                cell.contents = address.postalCode;
                break;
            case STPAddressFieldTypeCountry:
            case STPAddressFieldTypeSEPACountry:
                cell.contents = address.country;
                break;
            case STPAddressFieldTypeEmail:
                cell.contents = address.email;
                break;
            case STPAddressFieldTypePhone:
                cell.contents = address.phone;
                break;
        }
    }
}

- (STPAddress *)address {
    STPAddress *address = [STPAddress new];
    for (STPAddressFieldTableViewCell *cell in self.addressCells) {
        
        switch (cell.type) {
            case STPAddressFieldTypeName:
                address.name = cell.contents;
                break;
            case STPAddressFieldTypeLine1:
                address.line1 = cell.contents;
                break;
            case STPAddressFieldTypeLine2:
                address.line2 = cell.contents;
                break;
            case STPAddressFieldTypeCity:
                address.city = cell.contents;
                break;
            case STPAddressFieldTypeState:
                address.state = cell.contents;
                break;
            case STPAddressFieldTypeZip:
                address.postalCode = cell.contents;
                break;
            case STPAddressFieldTypeCountry:
            case STPAddressFieldTypeSEPACountry:
                address.country = cell.contents;
                break;
            case STPAddressFieldTypeEmail:
                address.email = cell.contents;
                break;
            case STPAddressFieldTypePhone:
                address.phone = cell.contents;
                break;
        }
    }
    return address;
}

- (STPAddressFieldTableViewCell *)cellBeforeCell:(STPAddressFieldTableViewCell *)cell {
    NSInteger index = [self.addressCells indexOfObject:cell];
    return [self.addressCells stp_boundSafeObjectAtIndex:index - 1];
}

- (STPAddressFieldTableViewCell *)cellAfterCell:(STPAddressFieldTableViewCell *)cell {
    NSInteger index = [self.addressCells indexOfObject:cell];
    return [self.addressCells stp_boundSafeObjectAtIndex:index + 1];
}

@end
