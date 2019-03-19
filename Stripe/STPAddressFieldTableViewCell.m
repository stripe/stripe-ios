//
//  STPAddressFieldTableViewCell.m
//  Stripe
//
//  Created by Ben Guo on 4/13/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPAddressFieldTableViewCell.h"

#import "STPCardValidator.h"
#import "STPEmailAddressValidator.h"
#import "STPLocalizationUtils.h"
#import "STPPhoneNumberValidator.h"
#import "STPPostalCodeValidator.h"
#import "UIView+Stripe_SafeAreaBounds.h"

@interface STPAddressFieldTableViewCell() <UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, weak) STPValidatedTextField *textField;
@property (nonatomic) UIToolbar *inputAccessoryToolbar;
@property (nonatomic) UIPickerView *countryPickerView;
@property (nonatomic, strong) NSArray *countryCodes;
@property (nonatomic, weak) id<STPAddressFieldTableViewCellDelegate>delegate;
@property (nonatomic, strong) NSString *ourCountryCode;
@end

@implementation STPAddressFieldTableViewCell

@synthesize contents = _contents;

- (instancetype)initWithType:(STPAddressFieldType)type
                    contents:(NSString *)contents
                  lastInList:(BOOL)lastInList
                    delegate:(id<STPAddressFieldTableViewCellDelegate>)delegate {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    if (self) {
        _delegate = delegate;
        _theme = [STPTheme new];
        _contents = contents;

        STPValidatedTextField *textField;
        if (type == STPAddressFieldTypePhone) {
            // We have very specific US-based phone formatting that's built into STPFormTextField
            STPFormTextField *formTextField = [[STPFormTextField alloc] init];
            formTextField.preservesContentsOnPaste = NO;
            formTextField.selectionEnabled = NO;
            textField = formTextField;
        }
        else {
            textField = [[STPValidatedTextField alloc] init];
        }
        textField.delegate = self;
        [textField addTarget:self
                      action:@selector(textFieldTextDidChange:)
            forControlEvents:UIControlEventEditingChanged];
        _textField = textField;
        [self.contentView addSubview:textField];
        
        UIToolbar *toolbar = [UIToolbar new];
        UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                      target:nil 
                                                                                      action:nil];
        UIBarButtonItem *nextItem = [[UIBarButtonItem alloc] initWithTitle:STPLocalizedString(@"Next", nil)
                                                                     style:UIBarButtonItemStyleDone
                                                                    target:self
                                                                    action:@selector(nextTapped:)];
        toolbar.items = @[flexibleItem, nextItem];
        _inputAccessoryToolbar = toolbar;
        
        NSString *countryCode = [[NSLocale autoupdatingCurrentLocale] objectForKey:NSLocaleCountryCode];
        NSMutableArray *otherCountryCodes = [[NSLocale ISOCountryCodes] mutableCopy];
        NSLocale *locale = [NSLocale currentLocale];
        [otherCountryCodes removeObject:countryCode];
        [otherCountryCodes sortUsingComparator:^NSComparisonResult(NSString *code1, NSString *code2) {
            NSString *localeID1 = [NSLocale localeIdentifierFromComponents:@{NSLocaleCountryCode: code1}];
            NSString *localeID2 = [NSLocale localeIdentifierFromComponents:@{NSLocaleCountryCode: code2}];
            NSString *name1 = [locale displayNameForKey:NSLocaleIdentifier value:localeID1];
            NSString *name2 = [locale displayNameForKey:NSLocaleIdentifier value:localeID2];
            return [name1 compare:name2];
        }];
        if (countryCode) {
           _countryCodes = [@[@"", countryCode] arrayByAddingObjectsFromArray:otherCountryCodes];
        }
        else {
           _countryCodes = [@[@""] arrayByAddingObjectsFromArray:otherCountryCodes];
        }
        UIPickerView *pickerView = [UIPickerView new];
        pickerView.dataSource = self;
        pickerView.delegate = self;
        _countryPickerView = pickerView;
        
        _lastInList = lastInList;
        _type = type;
        self.textField.text = contents;

        NSString *ourCountryCode = nil;
        if ([self.delegate respondsToSelector:@selector(addressFieldTableViewCountryCode)]) {
            ourCountryCode = self.delegate.addressFieldTableViewCountryCode;
        }
        
        if (ourCountryCode == nil) {
            ourCountryCode = countryCode;
        }
        [self delegateCountryCodeDidChange:ourCountryCode];
        [self updateAppearance];
    }
    return self;
}

- (void)setTheme:(STPTheme *)theme {
    _theme = theme;
    [self updateAppearance];
}

- (void)setLastInList:(BOOL)lastInList {
    _lastInList = lastInList;
    [self updateTextFieldsAndCaptions];
}

- (void)updateTextFieldsAndCaptions {
    self.textField.placeholder = [self placeholderForAddressField:self.type];
    if (!self.lastInList) {
        self.textField.returnKeyType = UIReturnKeyNext;
    }
    else {
        self.textField.returnKeyType = UIReturnKeyDefault;
    }
    switch (self.type) {
        case STPAddressFieldTypeName: 
            self.textField.keyboardType = UIKeyboardTypeDefault;
            if (@available(iOS 10.0, *)) {
                self.textField.textContentType = UITextContentTypeName;
            }
            break;
        case STPAddressFieldTypeLine1: 
            self.textField.keyboardType = UIKeyboardTypeDefault;
            if (@available(iOS 10.0, *)) {
                self.textField.textContentType = UITextContentTypeStreetAddressLine1;
            }
            break;
        case STPAddressFieldTypeLine2: 
            self.textField.keyboardType = UIKeyboardTypeDefault;
            if (@available(iOS 10.0, *)) {
                self.textField.textContentType = UITextContentTypeStreetAddressLine2;
            }
            break;
        case STPAddressFieldTypeCity:
            self.textField.keyboardType = UIKeyboardTypeDefault;
            if (@available(iOS 10.0, *)) {
                self.textField.textContentType = UITextContentTypeAddressCity;
            }
            break;
        case STPAddressFieldTypeState:
            self.textField.keyboardType = UIKeyboardTypeDefault;
            if (@available(iOS 10.0, *)) {
                self.textField.textContentType = UITextContentTypeAddressState;
            }
            break;
        case STPAddressFieldTypeZip:
            if ([self countryCodeIsUnitedStates]) { 
                self.textField.keyboardType = UIKeyboardTypePhonePad;
            } else {
                self.textField.keyboardType = UIKeyboardTypeASCIICapable;
            }

            if (@available(iOS 10.0, *)) {
                self.textField.textContentType = UITextContentTypePostalCode;
            }

            if (!self.lastInList) {
                self.textField.inputAccessoryView = self.inputAccessoryToolbar;
            }
            else {
                self.textField.inputAccessoryView = nil;
            }
            break;
        case STPAddressFieldTypeCountry:
            self.textField.keyboardType = UIKeyboardTypeDefault;
            // Don't set textContentType for Country, because we don't want iOS to skip the UIPickerView for input
            self.textField.inputView = self.countryPickerView;
            NSInteger index = [self.countryCodes indexOfObject:self.contents];
            if (index == NSNotFound) {
                self.textField.text = @"";
            }
            else {
                [self.countryPickerView selectRow:index inComponent:0 animated:NO];
                self.textField.text = [self pickerView:self.countryPickerView titleForRow:index forComponent:0];
            }
            self.textField.validText = [self validContents];
            break;
        case STPAddressFieldTypePhone:
            self.textField.keyboardType = UIKeyboardTypePhonePad;
            if (@available(iOS 10.0, *)) {
                self.textField.textContentType = UITextContentTypeTelephoneNumber;
            }
            STPFormTextFieldAutoFormattingBehavior behavior = ([self countryCodeIsUnitedStates] ?
                                                               STPFormTextFieldAutoFormattingBehaviorPhoneNumbers :
                                                               STPFormTextFieldAutoFormattingBehaviorNone);
            ((STPFormTextField *)self.textField).autoFormattingBehavior = behavior;
            if (!self.lastInList) {
                self.textField.inputAccessoryView = self.inputAccessoryToolbar;
            }
            else {
                self.textField.inputAccessoryView = nil;
            }
            break;
        case STPAddressFieldTypeEmail:
            self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
            self.textField.keyboardType = UIKeyboardTypeEmailAddress;
            if (@available(iOS 10.0, *)) {
                self.textField.textContentType = UITextContentTypeEmailAddress;
            }
            break;
            
    }
    self.textField.accessibilityLabel = self.textField.placeholder;
    self.textField.accessibilityIdentifier = [self accessibilityIdentifierForAddressField:self.type];
}

- (NSString *)accessibilityIdentifierForAddressField:(STPAddressFieldType)type {
    switch (type) {
        case STPAddressFieldTypeName:
            return @"ShippingAddressFieldTypeNameIdentifier";
        case STPAddressFieldTypeLine1:
            return @"ShippingAddressFieldTypeLine1Identifier";
        case STPAddressFieldTypeLine2:
            return @"ShippingAddressFieldTypeLine2Identifier";
        case STPAddressFieldTypeCity:
            return @"ShippingAddressFieldTypeCityIdentifier";
        case STPAddressFieldTypeState:
            return @"ShippingAddressFieldTypeStateIdentifier";
        case STPAddressFieldTypeZip:
            return @"ShippingAddressFieldTypeZipIdentifier";
        case STPAddressFieldTypeCountry:
            return @"ShippingAddressFieldTypeCountryIdentifier";
        case STPAddressFieldTypePhone:
            return @"ShippingAddressFieldTypePhoneIdentifier";
        case STPAddressFieldTypeEmail:
            return @"ShippingAddressFieldTypeEmailIdentifier";
    }
}

+ (NSString *)stateFieldCaptionForCountryCode:(NSString *)countryCode {
    if ([countryCode isEqualToString:@"US"]) {
        return STPLocalizedString(@"State", @"Caption for State field on address form (only countries that use state , like United States)");
    }
    else if ([countryCode isEqualToString:@"CA"]) {
        return STPLocalizedString(@"Province", @"Caption for Province field on address form (only countries that use province, like Canada)");
    }
    else if ([countryCode isEqualToString:@"GB"]) {
        return STPLocalizedString(@"County", @"Caption for County field on address form (only countries that use county, like United Kingdom)");
    }
    else  {
        return STPLocalizedString(@"State / Province / Region", @"Caption for generalized state/province/region field on address form (not tied to a specific country's format)");
    }
}

- (NSString *)placeholderForAddressField:(STPAddressFieldType)addressFieldType {
    switch (addressFieldType) {
        case STPAddressFieldTypeName:
            return STPLocalizedString(@"Name", @"Caption for Name field on address form");
        case STPAddressFieldTypeLine1:
            return STPLocalizedString(@"Address", @"Caption for Address field on address form");
        case STPAddressFieldTypeLine2:
            return STPLocalizedString(@"Apt.", @"Caption for Apartment/Address line 2 field on address form");
        case STPAddressFieldTypeCity:
            return STPLocalizedString(@"City", @"Caption for City field on address form");
        case STPAddressFieldTypeState:
            return [[self class] stateFieldCaptionForCountryCode:self.ourCountryCode];
        case STPAddressFieldTypeZip:
            return ([self countryCodeIsUnitedStates] 
                    ? STPLocalizedString(@"ZIP Code", @"Caption for Zip Code field on address form (only shown when country is United States only)")
                    : STPLocalizedString(@"Postal Code", @"Caption for Postal Code field on address form (only shown in countries other than the United States)"));
        case STPAddressFieldTypeCountry:
            return STPLocalizedString(@"Country", @"Caption for Country field on address form");
        case STPAddressFieldTypeEmail:
            return STPLocalizedString(@"Email", @"Caption for Email field on address form");
        case STPAddressFieldTypePhone:
            return STPLocalizedString(@"Phone", @"Caption for Phone field on address form");
    }
}

- (void)delegateCountryCodeDidChange:(NSString *)countryCode {
    if (self.type == STPAddressFieldTypeCountry) {
        self.contents = countryCode;
    }
    
    self.ourCountryCode = countryCode;
    [self updateTextFieldsAndCaptions];
    [self setNeedsLayout];
}

- (void)updateAppearance {
    self.backgroundColor = self.theme.secondaryBackgroundColor;
    self.contentView.backgroundColor = [UIColor clearColor];
    self.textField.placeholderColor = self.theme.tertiaryForegroundColor;
    self.textField.defaultColor = self.theme.primaryForegroundColor;
    self.textField.errorColor = self.theme.errorColor;
    self.textField.font = self.theme.font;
    [self setNeedsLayout];
}

- (BOOL)countryCodeIsUnitedStates {
    return [self.ourCountryCode isEqualToString:@"US"];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect bounds = [self stp_boundsWithHorizontalSafeAreaInsets];
    CGFloat textFieldX = 15;
    self.textField.frame = CGRectMake(textFieldX, 1, bounds.size.width - textFieldX, bounds.size.height - 1);
    self.inputAccessoryToolbar.frame = CGRectMake(0, 0, bounds.size.width, 44);
}

- (BOOL)becomeFirstResponder {
    return [self.textField becomeFirstResponder];
}

- (void)nextTapped:(__unused id)sender {
    if ([self.delegate respondsToSelector:@selector(addressFieldTableViewCellDidReturn:)]) {
        [self.delegate addressFieldTableViewCellDidReturn:self];
    }
}

#pragma mark - UITextFieldDelegate

- (void)textFieldTextDidChange:(STPValidatedTextField *)textField {
    if (self.type != STPAddressFieldTypeCountry) {
        _contents = textField.text;
        if ([textField isFirstResponder]) {
            textField.validText = [self potentiallyValidContents];
        } else {
            textField.validText = [self validContents];
        }
    }
    [self.delegate addressFieldTableViewCellDidUpdateText:self];
}

- (BOOL)textFieldShouldReturn:(__unused UITextField *)textField {
    if ([self.delegate respondsToSelector:@selector(addressFieldTableViewCellDidReturn:)]) {
        [self.delegate addressFieldTableViewCellDidReturn:self];
    }
    return NO;
}

- (void)textFieldDidEndEditing:(STPFormTextField *)textField {
    textField.validText = [self validContents];
    if ([self.delegate respondsToSelector:@selector(addressFieldTableViewCellDidEndEditing:)]) {
        [self.delegate addressFieldTableViewCellDidEndEditing:self];
    }
}

- (void)setCaption:(NSString *)caption {
    self.textField.placeholder = caption;
}

- (NSString *)caption {
    return self.textField.placeholder;
}

- (NSString *)contents {
    // iOS 11 QuickType completions from textContentType have a space at the end.
    // This *keeps* that space in the `textField`, but removes leading/trailing spaces from
    // the logical contents of this field, so they're ignored for validation and persisting
    return [_contents stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (void)setContents:(NSString *)contents {
    _contents = contents;
    if (self.type == STPAddressFieldTypeCountry) {
        [self updateTextFieldsAndCaptions];
    } else {
        self.textField.text = contents;
    }
    if ([self.textField isFirstResponder]) {
        self.textField.validText = [self potentiallyValidContents];
    } else {
        self.textField.validText = [self validContents];
    }
    [self.delegate addressFieldTableViewCellDidUpdateText:self];
}

- (BOOL)validContents {
    switch (self.type) {
        case STPAddressFieldTypeName:
        case STPAddressFieldTypeLine1:
        case STPAddressFieldTypeCity:
        case STPAddressFieldTypeState:
        case STPAddressFieldTypeCountry:
            return self.contents.length > 0;
        case STPAddressFieldTypeLine2:
            return YES;
        case STPAddressFieldTypeZip:
            return ([STPPostalCodeValidator validationStateForPostalCode:self.contents
                                                             countryCode:self.ourCountryCode] == STPCardValidationStateValid);
        case STPAddressFieldTypeEmail:
            return [STPEmailAddressValidator stringIsValidEmailAddress:self.contents];
        case STPAddressFieldTypePhone:
            return [STPPhoneNumberValidator stringIsValidPhoneNumber:self.contents
                                                      forCountryCode:self.ourCountryCode];
    }
}

- (BOOL)potentiallyValidContents {
    switch (self.type) {
        case STPAddressFieldTypeName:
        case STPAddressFieldTypeLine1:
        case STPAddressFieldTypeCity:
        case STPAddressFieldTypeState:
        case STPAddressFieldTypeCountry:
        case STPAddressFieldTypeLine2:
            return YES;
        case STPAddressFieldTypeZip: {
            STPCardValidationState validationState = [STPPostalCodeValidator validationStateForPostalCode:self.contents
                                                                                              countryCode:self.ourCountryCode];
            return (validationState == STPCardValidationStateValid
                    || validationState == STPCardValidationStateIncomplete);
        }
        case STPAddressFieldTypeEmail:
            return [STPEmailAddressValidator stringIsValidPartialEmailAddress:self.contents];
        case STPAddressFieldTypePhone:
            return [STPPhoneNumberValidator stringIsValidPartialPhoneNumber:self.contents
                                                             forCountryCode:self.ourCountryCode];
    }
}

#pragma mark - UIPickerView

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.ourCountryCode = self.countryCodes[row];
    self.contents = self.ourCountryCode;
    self.textField.text = [self pickerView:pickerView titleForRow:row forComponent:component];
    [self textFieldTextDidChange:self.textField]; // UIControlEvent not fired for programmatic changes
    if ([self.delegate respondsToSelector:@selector(addressFieldTableViewCountryCode)]) {
        self.delegate.addressFieldTableViewCountryCode = self.ourCountryCode;
    }
}

- (NSString *)pickerView:(__unused UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(__unused NSInteger)component {
    NSString *countryCode = self.countryCodes[row];
    NSString *identifier = [NSLocale localeIdentifierFromComponents:@{NSLocaleCountryCode: countryCode}];
    return [[NSLocale autoupdatingCurrentLocale] displayNameForKey:NSLocaleIdentifier value:identifier];
}

- (NSInteger)numberOfComponentsInPickerView:(__unused UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(__unused UIPickerView *)pickerView numberOfRowsInComponent:(__unused NSInteger)component {
    return self.countryCodes.count;
}

@end
