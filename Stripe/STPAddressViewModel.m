//
//  STPAddressViewModel.m
//  Stripe
//
//  Created by Jack Flintermann on 4/21/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPAddressViewModel.h"

#import "NSArray+Stripe.h"
#import "STPDispatchFunctions.h"
#import "STPPostalCodeValidator.h"

#import <CoreLocation/CoreLocation.h>

@interface STPAddressViewModel()<STPAddressFieldTableViewCellDelegate>
@property (nonatomic) BOOL isBillingAddress;
@property (nonatomic) STPBillingAddressFields requiredBillingAddressFields;
@property (nonatomic) NSSet<STPContactField> *requiredShippingAddressFields;
@property (nonatomic) NSArray<STPAddressFieldTableViewCell *> *addressCells;
@property (nonatomic) BOOL showingPostalCodeCell;
@property (nonatomic) BOOL geocodeInProgress;
@end

@implementation STPAddressViewModel

@synthesize addressFieldTableViewCountryCode = _addressFieldTableViewCountryCode;
@synthesize availableCountries = _availableCountries;

- (instancetype)initWithRequiredBillingFields:(STPBillingAddressFields)requiredBillingAddressFields availableCountries:(NSSet<NSString *> *)availableCountries {
    self = [super init];
    if (self) {
        _isBillingAddress = YES;
        _availableCountries = [availableCountries copy];
        _requiredBillingAddressFields = requiredBillingAddressFields;
        switch (requiredBillingAddressFields) {
            case STPBillingAddressFieldsNone:
                _addressCells = @[];
                break;
            case STPBillingAddressFieldsPostalCode:
                _addressCells = @[
                                  // Postal code cell will be added later if necessary
                                  ];
                break;
            case STPBillingAddressFieldsFull:
                _addressCells = @[
                                  [[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeName contents:@"" lastInList:NO delegate:self],
                                  [[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeLine1 contents:@"" lastInList:NO delegate:self],
                                  [[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeLine2 contents:@"" lastInList:NO delegate:self],
                                  [[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeCountry contents:_addressFieldTableViewCountryCode lastInList:NO delegate:self],
                                  // Postal code cell will be added here later if necessary
                                  [[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeCity contents:@"" lastInList:NO delegate:self],
                                  [[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeState contents:@"" lastInList:YES delegate:self],
                                  ];
                break;
            case STPBillingAddressFieldsName:
                _addressCells = @[
                                  [[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeName contents:@"" lastInList:YES delegate:self]
                                  ];
                break;
        }
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithRequiredShippingFields:(NSSet<STPContactField> *)requiredShippingAddressFields availableCountries:(NSSet<NSString *> *)availableCountries {
    self = [super init];
    if (self) {
        _isBillingAddress = NO;
        _availableCountries = [availableCountries copy];
        _requiredShippingAddressFields = requiredShippingAddressFields;
        NSMutableArray *cells = [NSMutableArray new];
        if ([requiredShippingAddressFields containsObject:STPContactFieldName]) {
            [cells addObject:[[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeName contents:@"" lastInList:NO delegate:self]];
        }
        if ([requiredShippingAddressFields containsObject:STPContactFieldEmailAddress]) {
            [cells addObject:[[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeEmail contents:@"" lastInList:NO delegate:self]];
        }
        if ([requiredShippingAddressFields containsObject:STPContactFieldPostalAddress]) {
            NSMutableArray *postalCells = [@[
                                             [[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeName contents:@"" lastInList:NO delegate:self],
                                             [[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeLine1 contents:@"" lastInList:NO delegate:self],
                                             [[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeLine2 contents:@"" lastInList:NO delegate:self],
                                             [[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeCountry contents:_addressFieldTableViewCountryCode lastInList:NO delegate:self],
                                             // Postal code cell will be added here later if necessary
                                             [[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeCity contents:@"" lastInList:NO delegate:self],
                                             [[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeState contents:@"" lastInList:NO delegate:self],
                                             ] mutableCopy];
            if ([requiredShippingAddressFields containsObject:STPContactFieldName]) {
                [postalCells removeObjectAtIndex:0];
            }
            [cells addObjectsFromArray:postalCells];
        }
        if ([requiredShippingAddressFields containsObject:STPContactFieldPhoneNumber]) {
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

- (instancetype)initWithRequiredBillingFields:(STPBillingAddressFields)requiredBillingAddressFields {
    return [self initWithRequiredBillingFields:requiredBillingAddressFields availableCountries:nil];
}
- (instancetype)initWithRequiredShippingFields:(NSSet<STPContactField> *)requiredShippingAddressFields {
    return [self initWithRequiredShippingFields:requiredShippingAddressFields availableCountries:nil];
}

- (void)commonInit {
    _addressFieldTableViewCountryCode = [[NSLocale autoupdatingCurrentLocale] objectForKey:NSLocaleCountryCode];
    [self updatePostalCodeCellIfNecessary];
}

- (void)updatePostalCodeCellIfNecessary {
    [self.delegate addressViewModelWillUpdate:self];
    BOOL shouldBeShowingPostalCode = [STPPostalCodeValidator postalCodeIsRequiredForCountryCode:self.addressFieldTableViewCountryCode];
    if (shouldBeShowingPostalCode && !self.showingPostalCodeCell) {
        if (self.containsStateAndPostalFields) {
            // Add before city
            NSUInteger stateFieldIndex = [self.addressCells indexOfObjectPassingTest:^BOOL(STPAddressFieldTableViewCell * _Nonnull obj, NSUInteger __unused idx, BOOL * _Nonnull __unused stop) {
                return (obj.type == STPAddressFieldTypeCity);
            }];

            if (stateFieldIndex != NSNotFound) {
                NSUInteger zipFieldIndex = stateFieldIndex;

                NSMutableArray<STPAddressFieldTableViewCell *> *mutableAddressCells = self.addressCells.mutableCopy;
                [mutableAddressCells insertObject:[[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeZip contents:@"" lastInList:NO delegate:self]
                                          atIndex:zipFieldIndex];
                self.addressCells = mutableAddressCells.copy;
                [self.delegate addressViewModel:self addedCellAtIndex:zipFieldIndex];
                [self.delegate addressViewModelDidChange:self];
            }
        }
    } else if (!shouldBeShowingPostalCode && self.showingPostalCodeCell) {
        if (self.containsStateAndPostalFields) {
            NSUInteger zipFieldIndex = [self.addressCells indexOfObjectPassingTest:^BOOL(STPAddressFieldTableViewCell * _Nonnull obj, NSUInteger __unused idx, BOOL * _Nonnull __unused stop) {
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
    }
    self.showingPostalCodeCell = shouldBeShowingPostalCode;
    [self.delegate addressViewModelDidUpdate:self];
}

- (BOOL)containsStateAndPostalFields {
    if (self.isBillingAddress) {
        return self.requiredBillingAddressFields == STPBillingAddressFieldsFull;
    } else {
        return [self.requiredShippingAddressFields containsObject:STPContactFieldPostalAddress];
    }
}

- (STPAddressFieldTableViewCell *)cellAtIndex:(NSInteger)index {
    return self.addressCells[index];
}

- (void)addressFieldTableViewCellDidReturn:(STPAddressFieldTableViewCell *)cell {
    [[self cellAfterCell:cell] becomeFirstResponder];
}

- (void)addressFieldTableViewCellDidEndEditing:(STPAddressFieldTableViewCell *)cell {
    if (cell.type == STPAddressFieldTypeZip) {
        [self updateCityAndStateFromZipCodeCell:cell];
    }
}

- (void)updateCityAndStateFromZipCodeCell:(STPAddressFieldTableViewCell *)zipCell {

    NSString *zipCode = zipCell.contents;

    if (self.geocodeInProgress
        || zipCode == nil
        || !zipCell.textField.validText
        || ![_addressFieldTableViewCountryCode isEqualToString:@"US"]) {
        return;
    }

    STPAddressFieldTableViewCell *cityCell = nil;
    STPAddressFieldTableViewCell *stateCell = nil;
    for (STPAddressFieldTableViewCell *cell in self.addressCells) {
        if (cell.type == STPAddressFieldTypeCity) {
            cityCell = cell;
        } else if (cell.type == STPAddressFieldTypeState) {
            stateCell = cell;
        }
    }

    if ((cityCell == nil && stateCell == nil)
        || (cityCell.contents.length > 0 || stateCell.contents.length > 0)) {
        // Don't auto fill if either have text already
        // Or if neither are non-nil
        return;
    } else {
        self.geocodeInProgress = YES;
        CLGeocoder *geocoder = [CLGeocoder new];

        CLGeocodeCompletionHandler onCompletion = ^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
            stpDispatchToMainThreadIfNecessary(^{
                if (placemarks.count > 0 && error == nil) {
                    CLPlacemark *placemark = placemarks.firstObject;
                    if (cityCell.contents.length == 0
                        && stateCell.contents.length == 0
                        && [zipCell.contents isEqualToString:zipCode]) {
                        // Check contents again to make sure they're still empty
                        // And that zipcode hasn't changed to something else
                        cityCell.contents = placemark.locality;
                        stateCell.contents = placemark.administrativeArea;
                    }
                }
                self.geocodeInProgress = NO;
            });
        };

        if (@available(iOS 11, *)) {
            CNMutablePostalAddress *address = [CNMutablePostalAddress new];
            address.postalCode = zipCode;
            address.ISOCountryCode = _addressFieldTableViewCountryCode;

            [geocoder geocodePostalAddress:address.copy
                         completionHandler:onCompletion];
        } else {
            [geocoder geocodeAddressString:[NSString stringWithFormat:@"%@, %@", zipCode, _addressFieldTableViewCountryCode]
                         completionHandler:onCompletion];
        }
    }
}

- (void)addressFieldTableViewCellDidUpdateText:(__unused STPAddressFieldTableViewCell *)cell {
    [self.delegate addressViewModelDidChange:self];
}

- (BOOL)isValid {
    if (self.isBillingAddress) {
        if (self.requiredBillingAddressFields == STPBillingAddressFieldsPostalCode) {
            return YES; // The AddressViewModel is only for address fields. Determining whether the postal code is present is up to the STPCardTextFieldViewModel.
        }
        return [self.address containsRequiredFields:self.requiredBillingAddressFields];
    } else {
        return [self.address containsRequiredShippingAddressFields:self.requiredShippingAddressFields];
    }
}

- (void)setAddressFieldTableViewCountryCode:(NSString *)addressFieldTableViewCountryCode {
    if (addressFieldTableViewCountryCode.length > 0 // ignore if someone passing in nil or empty and keep our current setup
        && ![_addressFieldTableViewCountryCode isEqualToString:addressFieldTableViewCountryCode]) {
        _addressFieldTableViewCountryCode = addressFieldTableViewCountryCode.copy;
        [self updatePostalCodeCellIfNecessary];
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
    // Prefer to use the contents of STPAddressFieldTypeCountry, but fallback to
    // `addressFieldTableViewCountryCode` if nil (important for STPBillingAddressFieldsPostalCode)
    address.country = address.country ?: self.addressFieldTableViewCountryCode;
    return address;
}

- (STPAddressFieldTableViewCell *)cellAfterCell:(STPAddressFieldTableViewCell *)cell {
    NSInteger index = [self.addressCells indexOfObject:cell];
    return [self.addressCells stp_boundSafeObjectAtIndex:index + 1];
}

@end
