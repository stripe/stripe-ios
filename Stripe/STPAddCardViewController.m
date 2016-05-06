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
#import "STPEmailAddressValidator.h"

@interface STPAddCardViewController ()<STPPaymentCardTextFieldDelegate, STPAddressViewModelDelegate, STPAddressFieldTableViewCellDelegate, UITableViewDelegate, UITableViewDataSource>
@property(nonatomic)STPAPIClient *apiClient;
@property(nonatomic)STPBillingAddressFields requiredBillingAddressFields;
@property(nonatomic, weak)UITableView *tableView;
@property(nonatomic, weak)UIImageView *cardImageView;
@property(nonatomic)UIBarButtonItem *doneItem;
@property(nonatomic)STPAddressFieldTableViewCell *emailCell;
@property(nonatomic)UITableViewCell *cardNumberCell;
@property(nonatomic, copy)STPAddCardCompletionBlock completion;
@property(nonatomic, weak)STPPaymentCardTextField *textField;
@property(nonatomic)BOOL loading;
@property(nonatomic)UIActivityIndicatorView *activityIndicator;
@property(nonatomic)STPAddressViewModel *addressViewModel;
@property(nonatomic)UIToolbar *inputAccessoryToolbar;
@property(nonatomic)STPCheckoutAPIClient *checkoutAPIClient;
@end

#define FAUXPAS_IGNORED_IN_METHOD(...)

static NSString *const STPPaymentCardCellReuseIdentifier = @"STPPaymentCardCellReuseIdentifier";
static NSInteger STPPaymentCardEmailSection = 0;
static NSInteger STPPaymentCardNumberSection = 1;
static NSInteger STPPaymentCardBillingAddressSection = 2;

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
    STPPaymentCardTextField *textField = [[STPPaymentCardTextField alloc] init];
    textField.delegate = self;
    [cardNumberCell addSubview:textField];
    self.textField = textField;
    self.cardNumberCell = cardNumberCell;
    
    self.addressViewModel.previousField = textField;
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    
    self.inputAccessoryToolbar = [UIToolbar stp_inputAccessoryToolbarWithTarget:self action:@selector(paymentFieldNextTapped)];
    [self.inputAccessoryToolbar stp_setEnabled:NO];
    if (self.requiredBillingAddressFields != STPBillingAddressFieldsNone) {
        textField.inputAccessoryView = self.inputAccessoryToolbar;
    }
    [self updateAppearance];
    self.tableView.alpha = 0;
    [self.checkoutAPIClient.bootstrapPromise onCompletion:^(__unused id value, __unused NSError *error) {
        [tableView reloadData];
        [UIView animateWithDuration:0.2 animations:^{
            tableView.alpha = 1;
        }];
    }];
}

- (void)setTheme:(STPTheme *)theme {
    _theme = theme;
    [self updateAppearance];
}

- (void)updateAppearance {
    self.view.backgroundColor = self.theme.primaryBackgroundColor;
    self.tableView.backgroundColor = self.theme.primaryBackgroundColor;
    self.tableView.separatorColor = self.theme.primaryBackgroundColor;
    self.textField.backgroundColor = self.theme.secondaryBackgroundColor;
    self.textField.placeholderColor = self.theme.tertiaryTextColor;
    self.textField.borderColor = [UIColor clearColor];
    self.textField.textColor = self.theme.primaryTextColor;
    self.textField.font = self.theme.font;
    self.cardImageView.tintColor = self.theme.accentColor;
    self.activityIndicator.color = self.theme.accentColor;
    self.emailCell.theme = self.theme;
    [self.tableView reloadData];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.bounds;
    self.textField.frame = self.cardNumberCell.bounds;
}

- (void)setLoading:(BOOL)loading {
    if (loading == _loading) {
        return;
    }
    _loading = loading;
    NSArray *cells = self.addressViewModel.addressCells;
    for (UITableViewCell *cell in [cells arrayByAddingObject:self.cardNumberCell]) {
        cell.userInteractionEnabled = !loading;
        [UIView animateWithDuration:0.1f animations:^{
            cell.alpha = loading ? 0.7f : 1.0f;
        }];
    }
    [self.navigationItem setHidesBackButton:loading animated:YES];
    self.navigationItem.leftBarButtonItem.enabled = !loading;
    if (loading) {
        [self.tableView endEditing:YES];
        [self.activityIndicator startAnimating];
        UIBarButtonItem *loadingItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
        [self.navigationItem setRightBarButtonItem:loadingItem animated:YES];
    } else {
        [self.navigationItem setRightBarButtonItem:self.doneItem animated:YES];
    }
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.textField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
}

- (void)nextPressed:(__unused id)sender {
    self.loading = YES;
    STPCardParams *cardParams = self.textField.cardParams;
    cardParams.address = self.addressViewModel.address;
    [self.textField resignFirstResponder];
    [self.apiClient createTokenWithCard:cardParams completion:^(STPToken *token, NSError *tokenError) {
        if (tokenError) {
            [self handleError:tokenError];
        } else {
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

- (void)updateDoneButton {
    self.navigationItem.rightBarButtonItem.enabled = self.textField.isValid && self.addressViewModel.isValid;
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

- (void)addressFieldTableViewCellDidReturn:(__unused STPAddressFieldTableViewCell *)cell {
    
}

- (void)addressFieldTableViewCellDidUpdateText:(STPAddressFieldTableViewCell *)cell {
    if (cell == self.emailCell) {
        NSString *contents = cell.contents;
        if ([STPEmailAddressValidator stringIsValidEmailAddress:contents]) {
            [[[self.checkoutAPIClient lookupEmail:contents] flatMap:^STPPromise *(STPCheckoutAccountLookup *lookup) {
                return [self.checkoutAPIClient sendSMSToAccountWithEmail:lookup.email];
            }] onSuccess:^(STPCheckoutAPIVerification *verification) {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Enter teh code" message:nil preferredStyle:UIAlertControllerStyleAlert];
                __block UITextField *alertTextField;
                [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                    alertTextField = textField;
                }];
                [alertController addAction:[UIAlertAction actionWithTitle:@"Send" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction * _Nonnull action) {
                    [[[self.checkoutAPIClient submitSMSCode:alertTextField.text forVerification:verification] flatMap:^STPPromise * _Nonnull(STPCheckoutAccount * _Nonnull account) {
                        return [self.checkoutAPIClient createTokenWithAccount:account];
                    }] onSuccess:^(__unused STPToken *value) {
                        
                    }];
                }]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self presentViewController:alertController animated:YES completion:nil];
                });
            }];
        }
    }
}

- (void)addressFieldTableViewCellDidBackspaceOnEmpty:(__unused STPAddressFieldTableViewCell *)cell {
    
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == STPPaymentCardEmailSection) {
        return self.checkoutAPIClient.readyForLookups ? 1 : 0;
    }
    else if (section == STPPaymentCardNumberSection) {
        return 1;
    } else if (section == STPPaymentCardBillingAddressSection) {
        return self.addressViewModel.addressCells.count;
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
        STPAddressFieldTableViewCell *addressCell = [self.addressViewModel.addressCells stp_boundSafeObjectAtIndex:indexPath.row];
        addressCell.theme = self.theme;
        cell = addressCell;
    }
    cell.backgroundColor = self.theme.secondaryBackgroundColor;
    return cell;
}

- (CGFloat)tableView:(__unused UITableView *)tableView heightForFooterInSection:(__unused NSInteger)section {
    return 27.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(__unused NSInteger)section {
    return tableView.sectionHeaderHeight;
}

- (UIView *)tableView:(__unused UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == STPPaymentCardEmailSection) {
        return nil;
    }
    UILabel *label = [UILabel new];
    label.font = self.theme.smallFont;
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.firstLineHeadIndent = 15;
    NSDictionary *attributes = @{NSParagraphStyleAttributeName: style};
    label.textColor = self.theme.secondaryTextColor;
    if (section == STPPaymentCardNumberSection) {
        label.attributedText = [[NSAttributedString alloc] initWithString:@"Card" attributes:attributes];
        return label;
    } else if (section == STPPaymentCardBillingAddressSection) {
        label.attributedText = [[NSAttributedString alloc] initWithString:@"Billing Address" attributes:attributes];
        return label;
    }
    return nil;
}

@end
