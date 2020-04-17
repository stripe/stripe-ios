//
//  STPAddCardViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 3/23/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPAddCardViewController.h"

#import "NSArray+Stripe.h"
#import "STPAddressFieldTableViewCell.h"
#import "STPAddressViewModel.h"
#import "STPAnalyticsClient.h"
#import "STPCardIOProxy.h"
#import "STPCardValidator.h"
#import "STPColorUtils.h"
#import "STPCoreTableViewController+Private.h"
#import "STPDispatchFunctions.h"
#import "STPEmailAddressValidator.h"
#import "STPImageLibrary+Private.h"
#import "STPImageLibrary.h"
#import "STPLocalizationUtils.h"
#import "STPPaymentActivityIndicatorView.h"
#import "STPPaymentCardTextField.h"
#import "STPPaymentConfiguration+Private.h"
#import "STPPhoneNumberValidator.h"
#import "STPPaymentCardTextFieldCell.h"
#import "STPPromise.h"
#import "STPSectionHeaderView.h"
#import "StripeError.h"
#import "UIBarButtonItem+Stripe.h"
#import "UINavigationBar+Stripe_Theme.h"
#import "UITableViewCell+Stripe_Borders.h"
#import "UIToolbar+Stripe_InputAccessory.h"
#import "UIView+Stripe_FirstResponder.h"
#import "UIViewController+Stripe_KeyboardAvoiding.h"
#import "UIViewController+Stripe_NavigationItemProxy.h"
#import "UIViewController+Stripe_ParentViewController.h"
#import "UIViewController+Stripe_Promises.h"

@interface STPAddCardViewController ()<
    STPAddressViewModelDelegate,
    STPCardIOProxyDelegate,
    STPPaymentCardTextFieldDelegate,
    UITableViewDelegate,
    UITableViewDataSource>

@property (nonatomic) BOOL alwaysShowScanCardButton;
@property (nonatomic) BOOL alwaysEnableDoneButton;
@property (nonatomic) STPPaymentConfiguration *configuration;
@property (nonatomic) STPAddress *shippingAddress;
@property (nonatomic) BOOL hasUsedShippingAddress;
@property (nonatomic, weak) UIImageView *cardImageView;
@property (nonatomic) UIBarButtonItem *doneItem;
@property (nonatomic) STPSectionHeaderView *cardHeaderView;
@property (nonatomic) STPCardIOProxy *cardIOProxy;
@property (nonatomic) STPSectionHeaderView *addressHeaderView;
@property (nonatomic) STPPaymentCardTextFieldCell *paymentCell;
@property (nonatomic) BOOL loading;
@property (nonatomic) STPPaymentActivityIndicatorView *activityIndicator;
@property (nonatomic, weak) STPPaymentActivityIndicatorView *lookupActivityIndicator;
@property (nonatomic) STPAddressViewModel *addressViewModel;
@property (nonatomic) UIToolbar *inputAccessoryToolbar;
@property (nonatomic) BOOL lookupSucceeded;
@end

static NSString *const STPPaymentCardCellReuseIdentifier = @"STPPaymentCardCellReuseIdentifier";

typedef NS_ENUM(NSUInteger, STPPaymentCardSection) {
    STPPaymentCardNumberSection = 0,
    STPPaymentCardBillingAddressSection = 1,
};

@implementation STPAddCardViewController

+ (void)initialize{
    [[STPAnalyticsClient sharedClient] addClassToProductUsageIfNecessary:[self class]];
}

- (instancetype)init {
    return [self initWithConfiguration:[STPPaymentConfiguration sharedConfiguration] theme:[STPTheme defaultTheme]];
}

- (instancetype)initWithConfiguration:(STPPaymentConfiguration *)configuration theme:(STPTheme *)theme {
    self = [super initWithTheme:theme];
    if (self) {
        [self commonInitWithConfiguration:configuration];
    }
    return self;
}

- (void)commonInitWithConfiguration:(STPPaymentConfiguration *)configuration {
    _configuration = configuration;
    _shippingAddress = nil;
    _hasUsedShippingAddress = NO;
    _apiClient = [STPAPIClient sharedClient];
    _addressViewModel = [[STPAddressViewModel alloc] initWithRequiredBillingFields:configuration.requiredBillingAddressFields availableCountries:configuration._availableCountries];
    _addressViewModel.delegate = self;
    self.title = STPLocalizedString(@"Add a Card", @"Title for Add a Card view");
}

- (void)createAndSetupViews {
    [super createAndSetupViews];
    
    UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(nextPressed:)];
    self.doneItem = doneItem;
    self.stp_navigationItemProxy.rightBarButtonItem = doneItem;
    [self updateDoneButton];

    self.stp_navigationItemProxy.leftBarButtonItem.accessibilityIdentifier = @"AddCardViewControllerNavBarCancelButtonIdentifier";
    self.stp_navigationItemProxy.rightBarButtonItem.accessibilityIdentifier = @"AddCardViewControllerNavBarDoneButtonIdentifier";
    
    UIImageView *cardImageView = [[UIImageView alloc] initWithImage:[STPImageLibrary largeCardFrontImage]];
    cardImageView.contentMode = UIViewContentModeCenter;
    cardImageView.frame = CGRectMake(0, 0, self.view.bounds.size.width, cardImageView.bounds.size.height + (57 * 2));
    self.cardImageView = cardImageView;
    self.tableView.tableHeaderView = cardImageView;

    STPPaymentCardTextFieldCell *paymentCell = [[STPPaymentCardTextFieldCell alloc] init];
    paymentCell.paymentField.delegate = self;
    if (self.configuration.requiredBillingAddressFields == STPBillingAddressFieldsPostalCode) {
        // If postal code collection is enabled, move the postal code field into the card entry field.
        // Otherwise, this will be picked up by the billing address fields below.
        paymentCell.paymentField.postalCodeEntryEnabled = YES;
    }
    self.paymentCell = paymentCell;
    
    self.activityIndicator = [[STPPaymentActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20.0f, 20.0f)];
    
    self.inputAccessoryToolbar = [UIToolbar stp_inputAccessoryToolbarWithTarget:self action:@selector(paymentFieldNextTapped)];
    [self.inputAccessoryToolbar stp_setEnabled:NO];
    [self updateInputAccessoryVisiblity];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView reloadData];
    if (self.prefilledInformation.billingAddress != nil) {
        self.addressViewModel.address = self.prefilledInformation.billingAddress;
    }

    STPSectionHeaderView *addressHeaderView = [STPSectionHeaderView new];
    addressHeaderView.theme = self.theme;
    addressHeaderView.title = STPLocalizedString(@"Billing Address", @"Title for billing address entry section");
    switch (self.configuration.shippingType) {
        case STPShippingTypeShipping:
            [addressHeaderView.button setTitle:STPLocalizedString(@"Use Shipping", @"Button to fill billing address from shipping address.")
                                      forState:UIControlStateNormal];
            break;
        case STPShippingTypeDelivery:
            [addressHeaderView.button setTitle:STPLocalizedString(@"Use Delivery", @"Button to fill billing address from delivery address.")
                                      forState:UIControlStateNormal];
            break;
    }
    [addressHeaderView.button addTarget:self action:@selector(useShippingAddress:)
                       forControlEvents:UIControlEventTouchUpInside];
    STPBillingAddressFields requiredFields = self.configuration.requiredBillingAddressFields;
    BOOL needsAddress = requiredFields != STPBillingAddressFieldsNone && !self.addressViewModel.isValid;
    BOOL buttonVisible = (needsAddress &&
                          [self.shippingAddress containsContentForBillingAddressFields:requiredFields]
                          && !self.hasUsedShippingAddress);
    addressHeaderView.buttonHidden = !buttonVisible;
    [addressHeaderView setNeedsLayout];
    _addressHeaderView = addressHeaderView;
    STPSectionHeaderView *cardHeaderView = [STPSectionHeaderView new];
    cardHeaderView.theme = self.theme;
    cardHeaderView.title = STPLocalizedString(@"Card", @"Title for credit card number entry field");
    cardHeaderView.buttonHidden = YES;
    _cardHeaderView = cardHeaderView;

    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(endEditing)]];

    [self setUpCardScanningIfAvailable];

    [[STPAnalyticsClient sharedClient] clearAdditionalInfo];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    // Resetting it re-calculates the size based on new view width
    // UITableView requires us to call setter again to actually pick up frame
    // change on footers
    if (self.tableView.tableFooterView) {
        self.customFooterView = self.tableView.tableFooterView;
    }
}

- (void)setUpCardScanningIfAvailable {
    if ([STPCardIOProxy isCardIOAvailable] || self.alwaysShowScanCardButton) {
        self.cardIOProxy = [[STPCardIOProxy alloc] initWithDelegate:self];
        self.cardHeaderView.buttonHidden = NO;
        [self.cardHeaderView.button setTitle:STPLocalizedString(@"Scan Card", @"Text for button to scan a credit card") forState:UIControlStateNormal];
        [self.cardHeaderView.button addTarget:self action:@selector(presentCardIO) forControlEvents:UIControlEventTouchUpInside];
        [self.cardHeaderView setNeedsLayout];
    }
}

- (void)setAlwaysEnableDoneButton:(BOOL)alwaysEnableDoneButton {
    if (alwaysEnableDoneButton != _alwaysEnableDoneButton) {
        _alwaysEnableDoneButton = alwaysEnableDoneButton;
        [self updateDoneButton];
    }
}

- (void)presentCardIO {
    [self.cardIOProxy presentCardIOFromViewController:self];
}

- (void)endEditing {
    [self.view endEditing:NO];
}

- (void)updateAppearance {
    [super updateAppearance];

    self.view.backgroundColor = self.theme.primaryBackgroundColor;

    STPTheme *navBarTheme = self.navigationController.navigationBar.stp_theme ?: self.theme;
    [self.doneItem stp_setTheme:navBarTheme];
    self.tableView.allowsSelection = NO;
    
    self.cardImageView.tintColor = self.theme.accentColor;
    self.activityIndicator.tintColor = self.theme.accentColor;
    
    self.paymentCell.theme = self.theme;
    self.cardHeaderView.theme = self.theme;
    self.addressHeaderView.theme = self.theme;
    
    for (STPAddressFieldTableViewCell *cell in self.addressViewModel.addressCells) {
        cell.theme = self.theme;
    }
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)setLoading:(BOOL)loading {
    if (loading == _loading) {
        return;
    }
    _loading = loading;
    [self.stp_navigationItemProxy setHidesBackButton:loading animated:YES];
    self.stp_navigationItemProxy.leftBarButtonItem.enabled = !loading;
    self.activityIndicator.animating = loading;
    if (loading) {
        [self.tableView endEditing:YES];
        UIBarButtonItem *loadingItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
        [self.stp_navigationItemProxy setRightBarButtonItem:loadingItem animated:YES];
        self.cardHeaderView.buttonHidden = YES;
    } else {
        [self.stp_navigationItemProxy setRightBarButtonItem:self.doneItem animated:YES];
        self.cardHeaderView.buttonHidden = NO;
    }
    NSArray *cells = self.addressViewModel.addressCells;
    for (UITableViewCell *cell in [cells arrayByAddingObject:self.paymentCell]) {
        cell.userInteractionEnabled = !loading;
        [UIView animateWithDuration:0.1f animations:^{
            cell.alpha = loading ? 0.7f : 1.0f;
        }];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self stp_beginObservingKeyboardAndInsettingScrollView:self.tableView
                                             onChangeBlock:nil];
    [[self firstEmptyField] becomeFirstResponder];
}

- (UIResponder *)firstEmptyField {

    if (self.paymentCell.isEmpty) {
        return self.paymentCell;
    }
    for (STPAddressFieldTableViewCell *cell in self.addressViewModel.addressCells) {
        if (cell.contents.length == 0) {
            return cell;
        }
    }
    return nil;
}

- (void)handleCancelTapped:(__unused id)sender {
    [self.delegate addCardViewControllerDidCancel:self];
}

- (void)nextPressed:(__unused id)sender {
    self.loading = YES;
    STPPaymentMethodCardParams *cardParams = self.paymentCell.paymentField.cardParams;
    if (!cardParams) {
        return;
    }
    // Create and return a Payment Method
    STPPaymentMethodBillingDetails *billingDetails = [[STPPaymentMethodBillingDetails alloc] init];
    if (self.configuration.requiredBillingAddressFields == STPBillingAddressFieldsPostalCode) {
        STPAddress *address = [[STPAddress alloc] init];
        address.postalCode = self.paymentCell.paymentField.postalCode;
        billingDetails.address = [[STPPaymentMethodAddress alloc] initWithAddress:address];
    } else {
        billingDetails.address = [[STPPaymentMethodAddress alloc] initWithAddress:self.addressViewModel.address];
        billingDetails.email = self.addressViewModel.address.email;
        billingDetails.name = self.addressViewModel.address.name;
        billingDetails.phone = self.addressViewModel.address.phone;
    }
    STPPaymentMethodParams *paymentMethodParams = [STPPaymentMethodParams paramsWithCard:cardParams
                                                                          billingDetails:billingDetails
                                                                                metadata:nil];
    [self.apiClient createPaymentMethodWithParams:paymentMethodParams completion:^(STPPaymentMethod * _Nullable paymentMethod, NSError * _Nullable createPaymentMethodError) {
        if (createPaymentMethodError) {
            [self handleError:createPaymentMethodError];
        } else {
            if ([self.delegate respondsToSelector:@selector(addCardViewController:didCreatePaymentMethod:completion:)]) {
                [self.delegate addCardViewController:self didCreatePaymentMethod:paymentMethod completion:^(NSError * _Nullable attachToCustomerError) {
                    stpDispatchToMainThreadIfNecessary(^{
                        if (attachToCustomerError) {
                            [self handleError:attachToCustomerError];
                        } else {
                            self.loading = NO;
                        }
                    });
                }];
            }
        }
    }];
}

- (void)handleError:(NSError *)error {
    self.loading = NO;
    [[self firstEmptyField] becomeFirstResponder];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:error.localizedDescription
                                                                             message:error.localizedFailureReason 
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:STPLocalizedString(@"OK", nil) 
                                                        style:UIAlertActionStyleCancel 
                                                      handler:nil]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)updateDoneButton {
    self.stp_navigationItemProxy.rightBarButtonItem.enabled = (self.paymentCell.paymentField.isValid
                                                               && self.addressViewModel.isValid
                                                               ) || self.alwaysEnableDoneButton;
}

- (void)updateInputAccessoryVisiblity {
    // The inputAccessoryToolbar switches from the paymentCell to the first address field.
    // It should only be shown when there *is* an address field. This compensates for the lack
    // of a 'Return' key on the number pad used for paymentCell entry
    BOOL hasAddressCells = self.addressViewModel.addressCells.count > 0;
    self.paymentCell.inputAccessoryView = hasAddressCells ? self.inputAccessoryToolbar : nil;
}

- (void)setCustomFooterView:(UIView *)footerView {
    _customFooterView = footerView;
    [self.stp_willAppearPromise voidOnSuccess:^{
        CGSize size = [footerView sizeThatFits:CGSizeMake(self.view.bounds.size.width, CGFLOAT_MAX)];
        footerView.frame = CGRectMake(0, 0, size.width, size.height);

        self.tableView.tableFooterView = footerView;
    }];
}

#pragma mark - STPPaymentCardTextField

- (void)paymentCardTextFieldDidChange:(STPPaymentCardTextField *)textField {
    [self.inputAccessoryToolbar stp_setEnabled:textField.isValid];
    [self updateDoneButton];
}

- (void)paymentFieldNextTapped {
    [[self.addressViewModel.addressCells stp_boundSafeObjectAtIndex:0] becomeFirstResponder];
}

- (void)paymentCardTextFieldWillEndEditingForReturn:(__unused STPPaymentCardTextField *)textField {
    [self paymentFieldNextTapped];
}

- (void)paymentCardTextFieldDidBeginEditingCVC:(STPPaymentCardTextField *)textField {
    BOOL isAmex = [STPCardValidator brandForNumber:textField.cardNumber] == STPCardBrandAmex;
    UIImage *newImage;
    UIViewAnimationOptions animationTransition;

    if (isAmex) {
        newImage = [STPImageLibrary largeCardAmexCVCImage];
        animationTransition = UIViewAnimationOptionTransitionCrossDissolve;
    } else {
        newImage = [STPImageLibrary largeCardBackImage];
        animationTransition = UIViewAnimationOptionTransitionFlipFromRight;
    }

    [UIView transitionWithView:self.cardImageView
                      duration:0.2
                       options:animationTransition
                    animations:^{
                        self.cardImageView.image = newImage;
                    } completion:nil];
}

- (void)paymentCardTextFieldDidEndEditingCVC:(STPPaymentCardTextField *)textField {
    BOOL isAmex = [STPCardValidator brandForNumber:textField.cardNumber] == STPCardBrandAmex;
    UIViewAnimationOptions animationTransition = isAmex ? UIViewAnimationOptionTransitionCrossDissolve : UIViewAnimationOptionTransitionFlipFromLeft;

    [UIView transitionWithView:self.cardImageView
                      duration:0.2
                       options:animationTransition
                    animations:^{
                        self.cardImageView.image = [STPImageLibrary largeCardFrontImage];
                    } completion:nil];
}

#pragma mark - STPAddressViewModelDelegate

- (void)addressViewModel:(__unused STPAddressViewModel *)addressViewModel addedCellAtIndex:(NSUInteger)index {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:STPPaymentCardBillingAddressSection];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self updateInputAccessoryVisiblity];
}

- (void)addressViewModel:(__unused STPAddressViewModel *)addressViewModel removedCellAtIndex:(NSUInteger)index {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:STPPaymentCardBillingAddressSection];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self updateInputAccessoryVisiblity];
}

- (void)addressViewModelDidChange:(__unused STPAddressViewModel *)addressViewModel {
    [self updateDoneButton];
}

- (void)addressViewModelWillUpdate:(__unused STPAddressViewModel *)addressViewModel {
    [self.tableView beginUpdates];
}

- (void)addressViewModelDidUpdate:(__unused STPAddressViewModel *)addressViewModel {
    [self.tableView endUpdates];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == STPPaymentCardNumberSection) {
        return 1;
    } else if (section == STPPaymentCardBillingAddressSection) {
        return self.addressViewModel.addressCells.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(__unused UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    switch (indexPath.section) {
        case STPPaymentCardNumberSection:
            cell = self.paymentCell;
            break;
        case STPPaymentCardBillingAddressSection:
            cell = [self.addressViewModel.addressCells stp_boundSafeObjectAtIndex:indexPath.row];
            break;
        default:
            return [UITableViewCell new]; // won't be called; exists to make the static analyzer happy
    }
    cell.backgroundColor = self.theme.secondaryBackgroundColor;
    cell.contentView.backgroundColor = [UIColor clearColor];
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL topRow = (indexPath.row == 0);
    BOOL bottomRow = ([self tableView:tableView numberOfRowsInSection:indexPath.section] - 1 == indexPath.row);
    [cell stp_setBorderColor:self.theme.tertiaryBackgroundColor];
    [cell stp_setTopBorderHidden:!topRow];
    [cell stp_setBottomBorderHidden:!bottomRow];
    [cell stp_setFakeSeparatorColor:self.theme.quaternaryBackgroundColor];
    [cell stp_setFakeSeparatorLeftInset:15.0f];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if ([self tableView:tableView numberOfRowsInSection:section] == 0) {
        return 0.01f;
    }
    return 27.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    CGSize fittingSize = CGSizeMake(self.view.bounds.size.width, CGFLOAT_MAX);
    NSInteger numberOfRows = [self tableView:tableView numberOfRowsInSection:section];
    if (section == STPPaymentCardNumberSection) {
        return [self.cardHeaderView sizeThatFits:fittingSize].height;
    } else if (section == STPPaymentCardBillingAddressSection && numberOfRows != 0) {
        return [self.addressHeaderView sizeThatFits:fittingSize].height;
    } else if (numberOfRows != 0) {
        return tableView.sectionHeaderHeight;
    }
    return 0.01f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if ([self tableView:tableView numberOfRowsInSection:section] == 0) {
        return [UIView new];
    } else {
        if (section == STPPaymentCardNumberSection) {
            return self.cardHeaderView;
        } else if (section == STPPaymentCardBillingAddressSection) {
            return self.addressHeaderView;
        }
    }
    return nil;
}

- (UIView *)tableView:(__unused UITableView *)tableView viewForFooterInSection:(__unused NSInteger)section {
    return [UIView new];
}

- (void)useShippingAddress:(__unused UIButton *)sender {
    [self.tableView beginUpdates];
    self.addressViewModel.address = self.shippingAddress;
    self.hasUsedShippingAddress = YES;
    [[self firstEmptyField] becomeFirstResponder];
    [UIView animateWithDuration:0.2f animations:^{
        self.addressHeaderView.buttonHidden = YES;
    }];
    [self.tableView endUpdates];
}

#pragma mark - STPCardIOProxyDelegate

- (void)cardIOProxy:(__unused STPCardIOProxy *)proxy didFinishWithCardParams:(STPPaymentMethodCardParams *)cardParams {
    if (cardParams) {
        self.paymentCell.paymentField.cardParams = cardParams;
    }
}


@end
