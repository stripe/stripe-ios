//
//  STPAddressFieldTableViewCell.m
//  Stripe
//
//  Created by Ben Guo on 4/13/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPAddressFieldTableViewCell.h"
#import "STPPostalCodeValidator.h"
#import "STPPhoneNumberValidator.h"
#import "STPEmailAddressValidator.h"
#import "STPCardValidator.h"

@interface STPAddressFieldTableViewCell() <STPFormTextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property(nonatomic, weak) UILabel *captionLabel;
@property(nonatomic, weak) STPFormTextField *textField;
@property(nonatomic) UIToolbar *inputAccessoryToolbar;
@property(nonatomic) UIPickerView *countryPickerView;
@property(nonatomic, strong) NSArray *countryCodes;
@property(nonatomic, weak)id<STPAddressFieldTableViewCellDelegate>delegate;

@end

@implementation STPAddressFieldTableViewCell

- (instancetype)initWithType:(STPAddressFieldType)type
                    contents:(NSString *)contents
                  lastInList:(BOOL)lastInList
                    delegate:(id<STPAddressFieldTableViewCellDelegate>)delegate {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    if (self) {
        _delegate = delegate;
        _theme = [STPTheme new];
        
        UILabel *captionLabel = [UILabel new];
        _captionLabel = captionLabel;
        [self.contentView addSubview:captionLabel];
        
        STPFormTextField *textField = [[STPFormTextField alloc] init];
        textField.formDelegate = self;
        textField.autoFormattingBehavior = STPFormTextFieldAutoFormattingBehaviorNone;
        textField.selectionEnabled = YES;
        textField.preservesContentsOnPaste = YES;
        _textField = textField;
        [self.contentView addSubview:textField];
        
        UIToolbar *toolbar = [UIToolbar new];
        UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *nextItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStyleDone target:self action:@selector(nextTapped:)];
        toolbar.items = @[flexibleItem, nextItem];
        _inputAccessoryToolbar = toolbar;
        
        NSString *countryCode = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
        NSMutableArray *otherCountryCodes = [[NSLocale ISOCountryCodes] mutableCopy];
        [otherCountryCodes removeObject:countryCode];
        _countryCodes = [@[@"", countryCode] arrayByAddingObjectsFromArray:otherCountryCodes];
        UIPickerView *pickerView = [UIPickerView new];
        pickerView.dataSource = self;
        pickerView.delegate = self;
        _countryPickerView = pickerView;
        
        _type = type;
        self.textField.text = contents;
        if (!lastInList) {
            self.textField.returnKeyType = UIReturnKeyNext;
        }
        switch (type) {
            case STPAddressFieldTypeName:
                self.captionLabel.text = NSLocalizedString(@"Name", nil);
                self.textField.placeholder = NSLocalizedString(@"John Appleseed", nil);
                self.textField.keyboardType = UIKeyboardTypeDefault;
                break;
            case STPAddressFieldTypeLine1:
                self.captionLabel.text = NSLocalizedString(@"Address", nil);
                self.textField.placeholder = NSLocalizedString(@"123 Address St", nil);
                self.textField.keyboardType = UIKeyboardTypeDefault;
                break;
            case STPAddressFieldTypeLine2:
                self.captionLabel.text = NSLocalizedString(@"Apt.", nil);
                self.textField.placeholder = NSLocalizedString(@"#23", nil);
                self.textField.keyboardType = UIKeyboardTypeDefault;
                break;
            case STPAddressFieldTypeCity:
                self.captionLabel.text = NSLocalizedString(@"City", nil);
                self.textField.placeholder = NSLocalizedString(@"San Francisco", nil);
                self.textField.keyboardType = UIKeyboardTypeDefault;
                break;
            case STPAddressFieldTypeState:
                if ([STPPhoneNumberValidator isUSLocale]) {
                    self.captionLabel.text = NSLocalizedString(@"State", nil);
                    self.textField.placeholder = NSLocalizedString(@"CA", nil);
                } else {
                    self.captionLabel.text = NSLocalizedString(@"County", nil);
                    self.textField.placeholder = nil;
                }
                self.textField.keyboardType = UIKeyboardTypeDefault;
                break;
            case STPAddressFieldTypeZip:
                if ([STPPhoneNumberValidator isUSLocale]) {
                    self.captionLabel.text = NSLocalizedString(@"ZIP Code", nil);
                } else {
                    self.captionLabel.text = NSLocalizedString(@"Postal Code", nil);
                }
                
                self.textField.placeholder = NSLocalizedString(@"12345", nil);
                self.textField.keyboardType = UIKeyboardTypeNumberPad;
                self.textField.preservesContentsOnPaste = NO;
                self.textField.selectionEnabled = NO;
                if (!lastInList) {
                    self.textField.inputAccessoryView = self.inputAccessoryToolbar;
                }
                break;
            case STPAddressFieldTypeCountry:
                self.captionLabel.text = NSLocalizedString(@"Country", nil);
                self.textField.placeholder = nil;
                self.textField.keyboardType = UIKeyboardTypeDefault;
                self.textField.keyboardType = UIKeyboardTypeDefault;
                self.textField.inputView = self.countryPickerView;
                NSInteger index = [self.countryCodes indexOfObject:self.contents];
                if (index == NSNotFound) {
                    self.textField.text = @"";
                }
                else {
                    [self.countryPickerView selectRow:index inComponent:0 animated:NO];
                }
                break;
            case STPAddressFieldTypePhone:
                self.captionLabel.text = NSLocalizedString(@"Phone", nil);
                self.textField.keyboardType = UIKeyboardTypePhonePad;
                if ([STPPhoneNumberValidator isUSLocale]) {
                    self.textField.placeholder = NSLocalizedString(@"(555) 123-1234", nil);
                    self.textField.autoFormattingBehavior = STPFormTextFieldAutoFormattingBehaviorPhoneNumbers;
                } else {
                    self.textField.placeholder = nil;
                    self.textField.autoFormattingBehavior = STPFormTextFieldAutoFormattingBehaviorNone;
                }
                self.textField.preservesContentsOnPaste = NO;
                self.textField.selectionEnabled = NO;
                if (!lastInList) {
                    self.textField.inputAccessoryView = self.inputAccessoryToolbar;
                }
                break;
            case STPAddressFieldTypeEmail:
                self.captionLabel.text = NSLocalizedString(@"Email", nil);
                self.textField.placeholder = NSLocalizedString(@"you@email.com", @"email field placeholder");
                self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
                self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
                self.textField.keyboardType = UIKeyboardTypeEmailAddress;
                break;
                
        }
        [self updateAppearance];
    }
    return self;
}

- (void)setTheme:(STPTheme *)theme {
    _theme = theme;
    [self updateAppearance];
}

- (void)updateAppearance {
    self.contentView.backgroundColor = self.theme.secondaryBackgroundColor;
    self.backgroundColor = [UIColor clearColor];
    self.captionLabel.font = self.theme.font;
    self.captionLabel.textColor = self.theme.secondaryForegroundColor;
    self.textField.placeholderColor = self.theme.tertiaryForegroundColor;
    self.textField.defaultColor = self.theme.primaryForegroundColor;
    self.textField.errorColor = self.theme.errorColor;
    self.textField.font = self.theme.font;
    [self setNeedsLayout];
}

- (NSString *)longestPossibleCaption {
    NSArray *captions = @[
                          NSLocalizedString(@"Name", nil),
                          NSLocalizedString(@"Address", nil),
                          NSLocalizedString(@"Apt.", nil),
                          NSLocalizedString(@"City", nil),
                          ([STPPhoneNumberValidator isUSLocale] ? NSLocalizedString(@"State", nil) : NSLocalizedString(@"County", nil)),
                          ([STPPhoneNumberValidator isUSLocale] ? NSLocalizedString(@"ZIP Code", nil) : NSLocalizedString(@"Postal Code", nil)),
                          NSLocalizedString(@"Country", nil),
                          NSLocalizedString(@"Email", nil),
                          NSLocalizedString(@"Phone", nil),
                          ];
    NSString *longestCaption = @"";
    for (NSString *caption in captions) {
        if ([caption length] > [longestCaption length]) {
            longestCaption = caption;
        }
    }
    return longestCaption;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    NSDictionary *attributes = @{ NSFontAttributeName: self.theme.font };
    CGFloat captionWidth = [[self longestPossibleCaption] sizeWithAttributes:attributes].width + 5;
    self.captionLabel.frame = CGRectMake(15, 0, captionWidth, self.bounds.size.height);
    CGFloat textFieldX = CGRectGetMaxX(self.captionLabel.frame) + 10;
    self.textField.frame = CGRectMake(textFieldX, 1, self.bounds.size.width - textFieldX, self.bounds.size.height - 1);
    self.inputAccessoryToolbar.frame = CGRectMake(0, 0, self.bounds.size.width, 44);
}

- (BOOL)becomeFirstResponder {
    return [self.textField becomeFirstResponder];
}

- (void)nextTapped:(__unused id)sender {
    if ([self.delegate respondsToSelector:@selector(addressFieldTableViewCellDidReturn:)]) {
        [self.delegate addressFieldTableViewCellDidReturn:self];
    }
}

#pragma mark - STPFormTextFieldDelegate

- (void)formTextFieldTextDidChange:(STPFormTextField *)textField {
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
}

- (void)formTextFieldDidBackspaceOnEmpty:(__unused STPFormTextField *)formTextField {
    [self.delegate addressFieldTableViewCellDidBackspaceOnEmpty:self];
}

- (void)setCaption:(NSString *)caption {
    self.captionLabel.text = caption;
}

- (NSString *)caption {
    return self.captionLabel.text;
}

- (void)setContents:(NSString *)contents {
    _contents = contents;
    self.textField.text = contents;
    if ([self.textField isFirstResponder]) {
        self.textField.validText = [self potentiallyValidContents];
    } else {
        self.textField.validText = [self validContents];
    }
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
            return [STPPostalCodeValidator stringIsValidPostalCode:self.contents];
        case STPAddressFieldTypeEmail:
            return [STPEmailAddressValidator stringIsValidEmailAddress:self.contents];
        case STPAddressFieldTypePhone:
            return [STPPhoneNumberValidator stringIsValidPhoneNumber:self.contents];
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
        case STPAddressFieldTypeZip:
            return [STPCardValidator stringIsNumeric:self.contents];
        case STPAddressFieldTypeEmail:
            return [STPEmailAddressValidator stringIsValidPartialEmailAddress:self.contents];
        case STPAddressFieldTypePhone:
            return [STPPhoneNumberValidator stringIsValidPartialPhoneNumber:self.contents];
    }
}

#pragma mark - UIPickerView

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.contents = self.countryCodes[row];
    self.textField.text = [self pickerView:pickerView titleForRow:row forComponent:component];
}

- (NSString *)pickerView:(__unused UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(__unused NSInteger)component {
    NSString *countryCode = self.countryCodes[row];
    NSString *identifier = [NSLocale localeIdentifierFromComponents:@{NSLocaleCountryCode: countryCode}];
    return [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:identifier];
}

- (NSInteger)numberOfComponentsInPickerView:(__unused UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(__unused UIPickerView *)pickerView numberOfRowsInComponent:(__unused NSInteger)component {
    return self.countryCodes.count;
}

@end
