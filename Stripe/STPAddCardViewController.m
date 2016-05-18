//
//  STPAddCardViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 3/23/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPAddCardViewController.h"
#import "STPPaymentCardTextField.h"
#import "STPToken.h"
#import "UIImage+Stripe.h"
#import "STPAddressFieldTableViewCell.h"
#import "STPAddressViewModel.h"
#import "NSArray+Stripe_BoundSafe.h"
#import "UIViewController+Stripe_KeyboardAvoiding.h"
#import "UIToolbar+Stripe_InputAccessory.h"
#import "STPCheckoutAPIClient.h"
#import "STPCheckoutAccount.h"
#import "STPEmailAddressValidator.h"
#import "STPSwitchTableViewCell.h"
#import "STPPhoneNumberValidator.h"
#import "STPSMSCodeViewController.h"
#import "STPObscuredCardView.h"
#import "STPPaymentActivityIndicatorView.h"
#import "UITableViewCell+Stripe_Borders.h"

@interface STPAddCardViewController ()<STPPaymentCardTextFieldDelegate, STPAddressViewModelDelegate, STPAddressFieldTableViewCellDelegate, STPSwitchTableViewCellDelegate, UITableViewDelegate, UITableViewDataSource, STPSMSCodeViewControllerDelegate, STPObscuredCardViewDelegate>
@property(nonatomic)STPAPIClient *apiClient;
@property(nonatomic)STPBillingAddressFields requiredBillingAddressFields;
@property(nonatomic, weak)UITableView *tableView;
@property(nonatomic, weak)UIImageView *cardImageView;
@property(nonatomic)UIBarButtonItem *doneItem;
@property(nonatomic)STPAddressFieldTableViewCell *emailCell;
@property(nonatomic)STPSwitchTableViewCell *rememberMeCell;
@property(nonatomic)STPAddressFieldTableViewCell *rememberMePhoneCell;
@property(nonatomic)UITableViewCell *cardNumberCell;
@property(nonatomic, copy)STPAddCardCompletionBlock completion;
@property(nonatomic, weak)STPPaymentCardTextField *textField;
@property(nonatomic, weak)STPObscuredCardView *obscuredCardView;
@property(nonatomic)BOOL loading;
@property(nonatomic)STPPaymentActivityIndicatorView *activityIndicator;
@property(nonatomic)STPAddressViewModel *addressViewModel;
@property(nonatomic)UIToolbar *inputAccessoryToolbar;
@property(nonatomic)STPCheckoutAPIClient *checkoutAPIClient;
@property(nonatomic)STPCheckoutAccount *checkoutAccount;
@property(nonatomic)STPCard *checkoutAccountCard;
@property(nonatomic)BOOL lookupSucceeded;
@end

#define FAUXPAS_IGNORED_IN_METHOD(...)

static NSString *const STPPaymentCardCellReuseIdentifier = @"STPPaymentCardCellReuseIdentifier";
static NSInteger STPPaymentCardEmailSection = 0;
static NSInteger STPPaymentCardNumberSection = 1;
static NSInteger STPPaymentCardBillingAddressSection = 2;
static NSInteger STPPaymentCardRememberMeSection = 3;

@implementation STPAddCardViewController

- (instancetype)initWithPublishableKey:(NSString *)publishableKey
          requiredBillingAddressFields:(STPBillingAddressFields)requiredBillingAddressFields
                            completion:(STPAddCardCompletionBlock)completion {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _apiClient = [[STPAPIClient alloc] initWithPublishableKey:publishableKey];
        _completion = completion;
        _requiredBillingAddressFields = requiredBillingAddressFields;
        _addressViewModel = [[STPAddressViewModel alloc] initWithRequiredBillingFields:requiredBillingAddressFields];
        _theme = [STPTheme new];
        _addressViewModel.delegate = self;
        _checkoutAPIClient = [[STPCheckoutAPIClient alloc] initWithPublishableKey:publishableKey];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    tableView.sectionHeaderHeight = 30;
    tableView.dataSource = self;
    tableView.delegate = self;
    [self.view addSubview:tableView];
    self.tableView = tableView;
    [self stp_beginAvoidingKeyboardWithScrollView:tableView];
    
    UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(nextPressed:)];
    self.doneItem = doneItem;
    self.navigationItem.rightBarButtonItem = doneItem;
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.navigationItem.title = NSLocalizedString(@"Add Card", nil);

    UIImageView *cardImageView = [[UIImageView alloc] initWithImage:[UIImage stp_largeCardFrontImage]];
    cardImageView.contentMode = UIViewContentModeCenter;
    cardImageView.frame = CGRectMake(0, 0, self.view.bounds.size.width, cardImageView.bounds.size.height + (57 * 2));
    self.cardImageView = cardImageView;
    self.tableView.tableHeaderView = cardImageView;
    
    self.emailCell = [[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypeEmail contents:nil lastInList:NO delegate:self];
    
    UITableViewCell *cardNumberCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    self.cardNumberCell = cardNumberCell;
    
    STPPaymentCardTextField *textField = [[STPPaymentCardTextField alloc] init];
    textField.delegate = self;
    [cardNumberCell addSubview:textField];
    self.textField = textField;
    
    STPObscuredCardView *obscuredCardView = [[STPObscuredCardView alloc] init];
    obscuredCardView.delegate = self;
    obscuredCardView.hidden = YES;
    [cardNumberCell addSubview:obscuredCardView];
    self.obscuredCardView = obscuredCardView;
    
    self.rememberMeCell = [[STPSwitchTableViewCell alloc] init];
    [self.rememberMeCell configureWithLabel:NSLocalizedString(@"Autofill my card in other apps", nil) delegate:self];
    
    self.rememberMePhoneCell = [[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypePhone contents:nil lastInList:YES delegate:self];
    self.rememberMePhoneCell.caption = NSLocalizedString(@"Phone", nil);
    
    self.addressViewModel.previousField = textField;
    
    self.activityIndicator = [[STPPaymentActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20.0f, 20.0f)];
    
    self.inputAccessoryToolbar = [UIToolbar stp_inputAccessoryToolbarWithTarget:self action:@selector(paymentFieldNextTapped)];
    [self.inputAccessoryToolbar stp_setEnabled:NO];
    if (self.requiredBillingAddressFields != STPBillingAddressFieldsNone) {
        textField.inputAccessoryView = self.inputAccessoryToolbar;
    }
    [self updateAppearance];
    [self.checkoutAPIClient.bootstrapPromise onCompletion:^(__unused id value, __unused NSError *error) {
        NSIndexSet *sections = [NSIndexSet indexSetWithIndex:STPPaymentCardRememberMeSection];
        [tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationFade];
    }];
}

- (void)setTheme:(STPTheme *)theme {
    _theme = theme;
    [self updateAppearance];
}

- (void)updateAppearance {
    self.view.backgroundColor = self.theme.primaryBackgroundColor;
    self.tableView.backgroundColor = self.theme.primaryBackgroundColor;
    self.tableView.separatorColor = self.theme.separatorColor;
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 18, 0, 0);
    self.textField.backgroundColor = self.theme.secondaryBackgroundColor;
    self.textField.placeholderColor = self.theme.tertiaryForegroundColor;
    self.textField.borderColor = [UIColor clearColor];
    self.textField.textColor = self.theme.primaryForegroundColor;
    self.textField.font = self.theme.font;
    self.obscuredCardView.theme = self.theme;
    self.cardImageView.tintColor = self.theme.accentColor;
    self.activityIndicator.tintColor = self.theme.accentColor;
    self.emailCell.theme = self.theme;
    for (STPAddressFieldTableViewCell *cell in self.addressViewModel.addressCells) {
        cell.theme = self.theme;
    }
    self.rememberMeCell.theme = self.theme;
    self.rememberMePhoneCell.theme = self.theme;
    [self.tableView reloadData];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.bounds;
    self.textField.frame = self.cardNumberCell.bounds;
    self.obscuredCardView.frame = self.cardNumberCell.bounds;
}

- (void)setLoading:(BOOL)loading {
    if (loading == _loading) {
        return;
    }
    _loading = loading;
    [self.navigationItem setHidesBackButton:loading animated:YES];
    self.navigationItem.leftBarButtonItem.enabled = !loading;
    self.activityIndicator.animating = loading;
    if (loading) {
        if ([self.textField isFirstResponder]) {
            [self.textField resignFirstResponder];
        } else {
            [self.tableView endEditing:YES];
        }
        UIBarButtonItem *loadingItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
        [self.navigationItem setRightBarButtonItem:loadingItem animated:YES];
    } else {
        [self.navigationItem setRightBarButtonItem:self.doneItem animated:YES];
    }
    NSArray *cells = self.addressViewModel.addressCells;
    for (UITableViewCell *cell in [cells arrayByAddingObjectsFromArray:@[self.emailCell, self.cardNumberCell, self.rememberMeCell, self.rememberMePhoneCell]] ) {
        cell.userInteractionEnabled = !loading;
        [UIView animateWithDuration:0.1f animations:^{
            cell.alpha = loading ? 0.7f : 1.0f;
        }];
    }
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.checkoutAccount) {
        [self.emailCell becomeFirstResponder];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
}

- (void)nextPressed:(__unused id)sender {
    self.loading = YES;
    STPCardParams *cardParams = self.textField.cardParams;
    cardParams.address = self.addressViewModel.address;
    if (self.checkoutAccountCard) {
        __weak typeof(self) weakself = self;
        [[[self.checkoutAPIClient createTokenWithAccount:self.checkoutAccount] onSuccess:^(STPToken *token) {
            __strong typeof(weakself) strongself = weakself;
            if (strongself.completion) {
                strongself.completion(token, ^(NSError *error) {
                    if (error) {
                        [strongself handleError:error];
                    }
                });
            }
        }] onFailure:^(NSError *error) {
            [weakself handleError:error];
        }];
    } else if (cardParams) {
        [self.apiClient createTokenWithCard:cardParams completion:^(STPToken *token, NSError *tokenError) {
            if (tokenError) {
                [self handleError:tokenError];
            } else {
                NSString *phone = self.rememberMePhoneCell.contents;
                NSString *email = self.emailCell.contents;
                if ([STPEmailAddressValidator stringIsValidEmailAddress:email] && [STPPhoneNumberValidator stringIsValidPartialPhoneNumber:phone] && self.rememberMeCell.on) {
                    [[self.checkoutAPIClient createAccountWithCardParams:cardParams email:email phone:phone] onSuccess:^(__unused STPCheckoutAccount *value) {
                        
                    }];
                }
                if (self.completion) {
                    self.completion(token, ^(NSError *error) {
                        if (error) {
                            [self handleError:error];
                        }
                    });
                }
            }
        }];
    }
}

- (void)handleError:(NSError *)error {
    FAUXPAS_IGNORED_IN_METHOD(APIAvailability);
    self.loading = NO;
    [self.textField becomeFirstResponder];
    if ([UIAlertController class]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:error.localizedDescription message:error.localizedFailureReason preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        [[[UIAlertView alloc] initWithTitle:error.localizedDescription message:error.localizedFailureReason delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles: nil] show];
    }
}

- (void)setCheckoutAccountCard:(STPCard *)checkoutAccountCard {
    _checkoutAccountCard = checkoutAccountCard;
    [self updateDoneButton];
}

- (void)updateDoneButton {
    self.navigationItem.rightBarButtonItem.enabled = (self.textField.isValid || self.checkoutAccountCard) && self.addressViewModel.isValid;
}

- (void)smsCodeViewControllerDidCancel:(__unused STPSMSCodeViewController *)smsCodeViewController {
    [self dismissViewControllerAnimated:YES completion:^{
        if (!self.textField.isValid) {
            [self.textField becomeFirstResponder];
        }
    }];
}

- (void)smsCodeViewController:(__unused STPSMSCodeViewController *)smsCodeViewController didAuthenticateAccount:(STPCheckoutAccount *)account {
    self.checkoutAccount = account;
    self.checkoutAccountCard = account.card;
    NSIndexSet *sections = [NSIndexSet indexSetWithIndex:STPPaymentCardRememberMeSection];
    [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationNone];
    [self.textField clear];
    self.obscuredCardView.hidden = NO;
    [self.obscuredCardView configureWithCard:account.card];
    self.addressViewModel.address = account.card.address;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)obscuredCardViewDidClear:(STPObscuredCardView *)cardView {
    self.checkoutAccountCard = nil;
    cardView.hidden = YES;
    [self.textField becomeFirstResponder];
}

#pragma mark - STPPaymentCardTextField

- (void)paymentCardTextFieldDidChange:(STPPaymentCardTextField *)textField {
    [self.inputAccessoryToolbar stp_setEnabled:textField.isValid];
    [self updateDoneButton];
}

- (void)paymentFieldNextTapped {
    [[self.addressViewModel.addressCells stp_boundSafeObjectAtIndex:0] becomeFirstResponder];
}

- (void)paymentCardTextFieldDidBeginEditingCVC:(__unused STPPaymentCardTextField *)textField {
    [UIView transitionWithView:self.cardImageView
                      duration:0.25
                       options:UIViewAnimationOptionTransitionFlipFromRight
                    animations:^{
                        self.cardImageView.image = [UIImage stp_largeCardBackImage];
                    } completion:nil];
}

- (void)paymentCardTextFieldDidEndEditingCVC:(__unused STPPaymentCardTextField *)textField {
    [UIView transitionWithView:self.cardImageView
                      duration:0.25
                       options:UIViewAnimationOptionTransitionFlipFromLeft
                    animations:^{
                        self.cardImageView.image = [UIImage stp_largeCardFrontImage];
                    } completion:nil];
}

#pragma mark - STPAddressViewModelDelegate

- (void)addressViewModelDidChange:(__unused STPAddressViewModel *)addressViewModel {
    [self updateDoneButton];
}

- (void)addressFieldTableViewCellDidReturn:(STPAddressFieldTableViewCell *)cell {
    if (cell == self.emailCell) {
        [self.textField becomeFirstResponder];
    }
}

- (void)addressFieldTableViewCellDidUpdateText:(STPAddressFieldTableViewCell *)cell {
    if (cell == self.emailCell) {
        NSString *contents = cell.contents;
        if (self.checkoutAccount) {
            return;
        }
        if ([STPEmailAddressValidator stringIsValidEmailAddress:contents] && !self.lookupSucceeded) {
            [[[self.checkoutAPIClient lookupEmail:contents] flatMap:^STPPromise *(STPCheckoutAccountLookup *lookup) {
                self.lookupSucceeded = YES;
                return [self.checkoutAPIClient sendSMSToAccountWithEmail:lookup.email];
            }] onSuccess:^(STPCheckoutAPIVerification *verification) {
                STPSMSCodeViewController *codeViewController = [[STPSMSCodeViewController alloc] initWithCheckoutAPIClient:self.checkoutAPIClient verification:verification];
                codeViewController.theme = self.theme;
                codeViewController.delegate = self;
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:codeViewController];
                [self presentViewController:nav animated:YES completion:nil];
            }];
        }
    }
}

- (void)addressFieldTableViewCellDidBackspaceOnEmpty:(__unused STPAddressFieldTableViewCell *)cell {
    
}

- (void)switchTableViewCell:(STPSwitchTableViewCell *)cell didToggleSwitch:(BOOL)on {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1
                                                inSection:STPPaymentCardRememberMeSection];
    [self.tableView beginUpdates];
    if (on) {
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
    } else {
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
    }
    [self.tableView endUpdates];
    
    // This updates the section borders so they're not drawn in both cells.
    NSIndexPath *switchIndexPath = [self.tableView indexPathForCell:cell];
    [self tableView:self.tableView willDisplayCell:cell forRowAtIndexPath:switchIndexPath];
    
    if (on) {
        [self.rememberMePhoneCell becomeFirstResponder];
    }
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == STPPaymentCardEmailSection) {
        if (self.smsAutofillDisabled) {
            return 0;
        }
        return 1;
    }
    else if (section == STPPaymentCardNumberSection) {
        return 1;
    } else if (section == STPPaymentCardBillingAddressSection) {
        return self.addressViewModel.addressCells.count;
    } else if (section == STPPaymentCardRememberMeSection) {
        if (!self.checkoutAPIClient.readyForLookups || self.checkoutAccount || self.smsAutofillDisabled) {
            return 0;
        }
        return self.rememberMeCell.on ? 2 : 1;
    }
    return 0;
}

- (UITableViewCell *)tableView:(__unused UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if (indexPath.section == STPPaymentCardEmailSection) {
        return self.emailCell;
    }
    else if (indexPath.section == STPPaymentCardNumberSection) {
        cell = self.cardNumberCell;
    } else if (indexPath.section == STPPaymentCardBillingAddressSection) {
        cell = [self.addressViewModel.addressCells stp_boundSafeObjectAtIndex:indexPath.row];
    } else if (indexPath.section == STPPaymentCardRememberMeSection) {
        if (indexPath.row == 0) {
            cell = self.rememberMeCell;
        } else {
            cell = self.rememberMePhoneCell;
        }
        
    }
    cell.backgroundColor = self.theme.secondaryBackgroundColor;
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL topRow = (indexPath.row == 0);
    BOOL bottomRow = ([self tableView:tableView numberOfRowsInSection:indexPath.section] - 1 == indexPath.row);
    [cell stp_setBorderColor:self.theme.tertiaryBackgroundColor];
    [cell stp_setTopBorderHidden:!topRow];
    [cell stp_setBottomBorderHidden:!bottomRow];
}

- (CGFloat)tableView:(__unused UITableView *)tableView heightForFooterInSection:(__unused NSInteger)section {
    if ([self tableView:tableView numberOfRowsInSection:section] == 0) {
        return 0.01f;
    }
    return 27.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(__unused NSInteger)section {
    if ([self tableView:tableView numberOfRowsInSection:section] == 0) {
        return 0.01f;
    }
    return tableView.sectionHeaderHeight;
}

- (UIView *)tableView:(__unused UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	if ([self tableView:tableView numberOfRowsInSection:section] == 0) {
		return nil;
	}
    if (section == STPPaymentCardEmailSection || section == STPPaymentCardRememberMeSection) {
        return [UIView new];
    } else {
        UILabel *label = [UILabel new];
        label.font = self.theme.smallFont;
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        style.firstLineHeadIndent = 15;
        NSDictionary *attributes = @{NSParagraphStyleAttributeName: style};
        label.textColor = self.theme.secondaryForegroundColor;
        if (section == STPPaymentCardNumberSection) {
            label.attributedText = [[NSAttributedString alloc] initWithString:@"Card" attributes:attributes];
            return label;
        } else if (section == STPPaymentCardBillingAddressSection) {
            label.attributedText = [[NSAttributedString alloc] initWithString:@"Billing Address" attributes:attributes];
            return label;
        }
    }
    return nil;
}

@end
