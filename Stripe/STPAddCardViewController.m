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
#import "STPRememberMeTermsView.h"
#import "UIBarButtonItem+Stripe.h"
#import "STPEmailAddressValidator.h"
#import "UINavigationBar+Stripe_Theme.h"
#import "UIViewController+Stripe_Alerts.h"
#import "StripeError.h"

@interface STPAddCardViewController ()<STPPaymentCardTextFieldDelegate, STPAddressViewModelDelegate, STPAddressFieldTableViewCellDelegate, STPSwitchTableViewCellDelegate, UITableViewDelegate, UITableViewDataSource, STPSMSCodeViewControllerDelegate, STPObscuredCardViewDelegate>
@property(nonatomic)STPPaymentConfiguration *configuration;
@property(nonatomic)STPAPIClient *apiClient;
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
@property(nonatomic)STPRememberMeTermsView *rememberMeTermsView;
@property(nonatomic)STPVoidPromise *didAppearPromise;
@end

static NSString *const STPPaymentCardCellReuseIdentifier = @"STPPaymentCardCellReuseIdentifier";
static NSInteger STPPaymentCardEmailSection = 0;
static NSInteger STPPaymentCardNumberSection = 1;
static NSInteger STPPaymentCardBillingAddressSection = 2;
static NSInteger STPPaymentCardRememberMeSection = 3;

@implementation STPAddCardViewController

- (instancetype)initWithConfiguration:(STPPaymentConfiguration *)configuration
                           completion:(STPAddCardCompletionBlock)completion {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _configuration = configuration;
        _apiClient = [[STPAPIClient alloc] initWithPublishableKey:configuration.publishableKey];
        _completion = completion;
        _addressViewModel = [[STPAddressViewModel alloc] initWithRequiredBillingFields:configuration.requiredBillingAddressFields];
        _addressViewModel.delegate = self;
        _checkoutAPIClient = [[STPCheckoutAPIClient alloc] initWithPublishableKey:configuration.publishableKey];
        _didAppearPromise = [STPVoidPromise new];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    tableView.sectionHeaderHeight = 30;
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
    if ([STPEmailAddressValidator stringIsValidEmailAddress:self.configuration.prefilledUserEmail]) {
        self.emailCell.contents = self.configuration.prefilledUserEmail;
    }
    
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
    self.rememberMeCell.accessibilityIdentifier = @"rememberMeCell";
    [self.rememberMeCell configureWithLabel:NSLocalizedString(@"Autofill my card in other apps", nil) delegate:self];
    
    self.rememberMePhoneCell = [[STPAddressFieldTableViewCell alloc] initWithType:STPAddressFieldTypePhone contents:nil lastInList:YES delegate:self];
    self.rememberMePhoneCell.caption = NSLocalizedString(@"Phone", nil);
    
    self.rememberMeTermsView = [STPRememberMeTermsView new];
    self.rememberMeTermsView.textView.alpha = 0;
    
    self.addressViewModel.previousField = textField;
    
    self.activityIndicator = [[STPPaymentActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20.0f, 20.0f)];
    
    self.inputAccessoryToolbar = [UIToolbar stp_inputAccessoryToolbarWithTarget:self action:@selector(paymentFieldNextTapped)];
    [self.inputAccessoryToolbar stp_setEnabled:NO];
    if (self.configuration.requiredBillingAddressFields != STPBillingAddressFieldsNone) {
        textField.inputAccessoryView = self.inputAccessoryToolbar;
    }
    tableView.dataSource = self;
    tableView.delegate = self;
    [self updateAppearance];
    __weak typeof(self) weakself = self;
    [self.checkoutAPIClient.bootstrapPromise onCompletion:^(__unused id value, __unused NSError *error) {
        [weakself reloadRememberMeCellAnimated:YES];
    }];
}

- (void)updateAppearance {
    self.view.backgroundColor = self.configuration.theme.primaryBackgroundColor;
    [self.doneItem stp_setTheme:self.configuration.theme];
    self.tableView.allowsSelection = NO;
    self.tableView.backgroundColor = self.configuration.theme.primaryBackgroundColor;
    self.tableView.separatorColor = self.configuration.theme.quaternaryBackgroundColor;
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 18, 0, 0);
    
    self.cardNumberCell.backgroundColor = self.configuration.theme.secondaryBackgroundColor;
    self.textField.backgroundColor = [UIColor clearColor];
    self.textField.placeholderColor = self.configuration.theme.tertiaryForegroundColor;
    self.textField.borderColor = [UIColor clearColor];
    self.textField.textColor = self.configuration.theme.primaryForegroundColor;
    self.textField.font = self.configuration.theme.font;
    
    self.obscuredCardView.theme = self.configuration.theme;
    self.cardImageView.tintColor = self.configuration.theme.accentColor;
    self.activityIndicator.tintColor = self.configuration.theme.accentColor;
    self.emailCell.theme = self.configuration.theme;
    for (STPAddressFieldTableViewCell *cell in self.addressViewModel.addressCells) {
        cell.theme = self.configuration.theme;
    }
    self.rememberMeCell.theme = self.configuration.theme;
    self.rememberMePhoneCell.theme = self.configuration.theme;
    self.rememberMeTermsView.theme = self.configuration.theme;
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadRememberMeCellAnimated:NO];
    [self.tableView reloadData];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.didAppearPromise.completed) {
        [self.didAppearPromise succeed];
    }
    if (!self.checkoutAccount && !self.emailCell.contents) {
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
                    [[[self.checkoutAPIClient createAccountWithCardParams:cardParams email:email phone:phone] onSuccess:^(__unused STPCheckoutAccount *value) {
                        // TODO remove
                    }] onFailure:^(__unused NSError *error) {
                        
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
    self.loading = NO;
    if ([error stp_isUnknownCheckoutError]) {
        // TODO log error
        STPObscuredCardView *obscuredView = self.obscuredCardView;
        NSArray *tuples = @[
                            [STPAlertTuple tupleWithTitle:NSLocalizedString(@"Enter card details manually", nil) style:STPAlertStyleDefault action:^{
                                [obscuredView clear];
                            }],
                            ];
        [self stp_showAlertWithTitle:NSLocalizedString(@"There was an error submitting your autofilled card details.", nil)
                             message:nil
                              tuples:tuples];
    } else {
        [self.textField becomeFirstResponder];
        NSArray *tuples = @[
                            [STPAlertTuple tupleWithTitle:NSLocalizedString(@"OK", nil) style:STPAlertStyleCancel action:nil],
                            ];
        [self stp_showAlertWithTitle:error.localizedDescription
                             message:error.localizedFailureReason
                              tuples:tuples];
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
    [self reloadRememberMeCellAnimated:NO];
    [self dismissViewControllerAnimated:YES completion:^{
        if (!self.textField.isValid) {
            [self.textField becomeFirstResponder];
        }
    }];
}

- (void)smsCodeViewController:(__unused STPSMSCodeViewController *)smsCodeViewController didAuthenticateAccount:(STPCheckoutAccount *)account {
    self.checkoutAccount = account;
    self.checkoutAccountCard = account.card;
    [self reloadRememberMeCellAnimated:NO];
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
        [self lookupAndSendSMS:cell.contents];
    }
}

- (void)lookupAndSendSMS:(NSString *)email {
    if (self.checkoutAccount) {
        return;
    }
    __weak typeof(self) weakself = self;
    if ([STPEmailAddressValidator stringIsValidEmailAddress:email] && !self.lookupSucceeded) {
        [[[self.didAppearPromise voidFlatMap:^STPPromise * _Nonnull{
            return [weakself.checkoutAPIClient lookupEmail:email];
        }] flatMap:^STPPromise * _Nonnull(STPCheckoutAccountLookup *lookup) {
            weakself.lookupSucceeded = YES;
            return [weakself.checkoutAPIClient sendSMSToAccountWithEmail:lookup.email];
        }] onSuccess:^(STPCheckoutAPIVerification *verification) {
            STPSMSCodeViewController *codeViewController = [[STPSMSCodeViewController alloc] initWithCheckoutAPIClient:self.checkoutAPIClient verification:verification];
            codeViewController.theme = self.configuration.theme;
            codeViewController.delegate = self;
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:codeViewController];
            [nav.navigationBar stp_setTheme:self.configuration.theme];
            [weakself presentViewController:nav animated:YES completion:nil];
        }];
    }
}

- (void)addressFieldTableViewCellDidBackspaceOnEmpty:(__unused STPAddressFieldTableViewCell *)cell {
    // TODO?
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
    
    [UIView animateWithDuration:0.1 animations:^{
        self.rememberMeTermsView.textView.alpha = on ? 1.0f : 0.0f;
    }];
    
    // This updates the section borders so they're not drawn in both cells.
    NSIndexPath *switchIndexPath = [self.tableView indexPathForCell:cell];
    [self tableView:self.tableView willDisplayCell:cell forRowAtIndexPath:switchIndexPath];
    
    if (on) {
        [self.rememberMePhoneCell becomeFirstResponder];
    }
}

#pragma mark - UITableView

- (void)reloadRememberMeCellAnimated:(BOOL)animated {
    BOOL disabled = !self.checkoutAPIClient.readyForLookups || self.checkoutAccount || self.configuration.smsAutofillDisabled || self.lookupSucceeded;
    [UIView animateWithDuration:(0.2f * animated) animations:^{
        self.rememberMeCell.stp_contentAlpha = disabled ? 0 : 1;
    } completion:^(__unused BOOL finished) {
        [self tableView:self.tableView willDisplayCell:self.rememberMeCell forRowAtIndexPath:[self.tableView indexPathForCell:self.rememberMeCell]];
    }];
}

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == STPPaymentCardEmailSection) {
        if (self.configuration.smsAutofillDisabled) {
            return 0;
        }
        return 1;
    }
    else if (section == STPPaymentCardNumberSection) {
        return 1;
    } else if (section == STPPaymentCardBillingAddressSection) {
        return self.addressViewModel.addressCells.count;
    } else if (section == STPPaymentCardRememberMeSection) {
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
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = self.configuration.theme.secondaryBackgroundColor;
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL topRow = (indexPath.row == 0);
    BOOL bottomRow = ([self tableView:tableView numberOfRowsInSection:indexPath.section] - 1 == indexPath.row);
    [cell stp_setBorderColor:self.configuration.theme.tertiaryBackgroundColor];
    [cell stp_setTopBorderHidden:!topRow];
    [cell stp_setBottomBorderHidden:!bottomRow];
}

- (CGFloat)tableView:(__unused UITableView *)tableView heightForFooterInSection:(__unused NSInteger)section {
    if (section == STPPaymentCardRememberMeSection) {
        return 140.0f;
    } else if ([self tableView:tableView numberOfRowsInSection:section] == 0) {
        return 0.01f;
    }
    return 27.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(__unused NSInteger)section {
    if (section == STPPaymentCardRememberMeSection || [self tableView:tableView numberOfRowsInSection:section] != 0) {
        return tableView.sectionHeaderHeight;
    }
    return 0.01f;
}

- (UIView *)tableView:(__unused UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == STPPaymentCardEmailSection || section == STPPaymentCardRememberMeSection) {
        return [UIView new];
    } else if ([self tableView:tableView numberOfRowsInSection:section] == 0) {
        return [UIView new];
    } else {
        UILabel *label = [UILabel new];
        label.font = self.configuration.theme.smallFont;
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        style.firstLineHeadIndent = 15;
        NSDictionary *attributes = @{NSParagraphStyleAttributeName: style};
        label.textColor = self.configuration.theme.secondaryForegroundColor;
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

- (UIView *)tableView:(__unused UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section != STPPaymentCardRememberMeSection) {
        return [UIView new];
    }
    return self.rememberMeTermsView;
}

@end
