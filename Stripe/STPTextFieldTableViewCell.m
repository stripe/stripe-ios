//
//  STPTextFieldTableViewCell.m
//  Stripe
//
//  Created by Ben Guo on 2/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPTextFieldTableViewCell.h"

#import "STPFormTextField.h"
#import "STPTheme.h"

@interface STPTextFieldTableViewCell()

@end

@implementation STPTextFieldTableViewCell

- (instancetype)init {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    if (self) {
        _theme = [STPTheme defaultTheme];
        STPFormTextField *textField = [[STPFormTextField alloc] init];
        textField.formDelegate = self;
        textField.autoFormattingBehavior = STPFormTextFieldAutoFormattingBehaviorNone;
        textField.selectionEnabled = YES;
        textField.preservesContentsOnPaste = YES;
        _textField = textField;
        _textValidationBlock = ^BOOL(NSString *contents, __unused BOOL editing) {
            return contents.length > 0;
        };
        [self.contentView addSubview:textField];
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
    self.textField.placeholderColor = self.theme.tertiaryForegroundColor;
    self.textField.defaultColor = self.theme.primaryForegroundColor;
    self.textField.errorColor = self.theme.errorColor;
    self.textField.font = self.theme.font;
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat textFieldX = 15;
    self.textField.frame = CGRectMake(textFieldX, 1, self.bounds.size.width - textFieldX, self.bounds.size.height - 1);
}

- (BOOL)becomeFirstResponder {
    return [self.textField becomeFirstResponder];
}

- (void)setPlaceholder:(NSString *)placeholder {
    self.textField.placeholder = placeholder;
}

- (NSString *)placeholder {
    return self.textField.placeholder;
}

- (void)setContents:(NSString *)contents {
    _contents = contents;
    self.textField.text = contents;
    if ([self.textField isFirstResponder]) {
        self.textField.validText = self.textValidationBlock(contents, YES);
    } else {
        self.textField.validText = self.textValidationBlock(contents, NO);
    }
}

- (void)setLastInList:(BOOL)lastInList {
    _lastInList = lastInList;
    self.textField.returnKeyType = lastInList ? UIReturnKeyDone : UIReturnKeyDefault;
}

- (BOOL)isValid {
    return self.contents.length > 0;
}

#pragma mark - STPFormTextFieldDelegate

- (void)formTextFieldTextDidChange:(STPFormTextField *)textField {
    _contents = textField.text;
    self.textField.validText = self.textValidationBlock(self.contents, YES);
    [self.delegate textFieldTableViewCellDidUpdateText:self];
}

- (BOOL)textFieldShouldReturn:(__unused UITextField *)textField {
    if ([self.delegate respondsToSelector:@selector(textFieldTableViewCellDidReturn:)]) {
        [self.delegate textFieldTableViewCellDidReturn:self];
    }
    return NO;
}

- (void)textFieldDidEndEditing:(__unused STPFormTextField *)textField {
    self.textField.validText = self.textValidationBlock(self.contents, NO);
}

- (void)formTextFieldDidBackspaceOnEmpty:(__unused STPFormTextField *)formTextField {
    if ([self.delegate respondsToSelector:@selector(textFieldTableViewCellDidBackspaceOnEmpty:)]) {
        [self.delegate textFieldTableViewCellDidBackspaceOnEmpty:self];
    }
}

@end
