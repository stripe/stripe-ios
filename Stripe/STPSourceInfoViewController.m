//
//  STPSourceInfoViewController.m
//  Stripe
//
//  Created by Ben Guo on 2/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPSourceInfoViewController.h"

#import "NSArray+Stripe_BoundSafe.h"
#import "STPBancontactSourceInfoDataSource.h"
#import "STPBankPickerDataSource.h"
#import "STPCoreTableViewController+Private.h"
#import "STPCountryPickerDataSource.h"
#import "STPGiropaySourceInfoDataSource.h"
#import "STPIDEALSourceInfoDataSource.h"
#import "STPLocalizationUtils.h"
#import "STPPickerTableViewCell.h"
#import "STPSofortSourceInfoDataSource.h"
#import "STPSourceParams.h"
#import "STPSource+Private.h"
#import "STPTextFieldTableViewCell.h"
#import "UIBarButtonItem+Stripe.h"
#import "UINavigationBar+Stripe_Theme.h"
#import "UITableViewCell+Stripe_Borders.h"
#import "UIViewController+Stripe_KeyboardAvoiding.h"
#import "UIViewController+Stripe_NavigationItemProxy.h"

@interface STPSourceInfoViewController () <UITableViewDelegate, UITableViewDataSource, STPTextFieldTableViewCellDelegate>

@property(nonatomic)UIBarButtonItem *doneItem;
@property(nonatomic)STPSourceInfoDataSource *dataSource;

@end

@implementation STPSourceInfoViewController

+ (BOOL)canCollectInfoForSourceType:(STPSourceType)type {
    switch (type) {
        case STPSourceTypeBancontact:
        case STPSourceTypeGiropay:
        case STPSourceTypeIDEAL:
        case STPSourceTypeSofort:
            return YES;
        default:
            return NO;
    }
}

- (instancetype)initWithSourceParams:(STPSourceParams *)sourceParams
                               theme:(STPTheme *)theme {
    self = [super initWithTheme:theme];
    if (![[self class] canCollectInfoForSourceType:sourceParams.type]) {
        return nil;
    }
    if (self) {
        STPSourceInfoDataSource *dataSource;
        switch (sourceParams.type) {
            case STPSourceTypeBancontact:
                dataSource = [[STPBancontactSourceInfoDataSource alloc] initWithSourceParams:sourceParams];
                break;
            case STPSourceTypeGiropay:
                dataSource = [[STPGiropaySourceInfoDataSource alloc] initWithSourceParams:sourceParams];
                break;
            case STPSourceTypeIDEAL:
                dataSource = [[STPIDEALSourceInfoDataSource alloc] initWithSourceParams:sourceParams];
                break;
            case STPSourceTypeSofort:
                dataSource = [[STPSofortSourceInfoDataSource alloc] initWithSourceParams:sourceParams];
                break;
            default:
                dataSource = [[STPSourceInfoDataSource alloc] init];
                break;
        }
        self.dataSource = dataSource;
        self.title = dataSource.title;
    }
    return self;
}

- (void)createAndSetupViews {
    [super createAndSetupViews];
    UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(nextPressed:)];
    self.doneItem = doneItem;
    self.stp_navigationItemProxy.rightBarButtonItem = doneItem;
    self.stp_navigationItemProxy.rightBarButtonItem.enabled = NO;

    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    STPTextFieldTableViewCell *lastCell = [self.dataSource.cells lastObject];
    for (STPTextFieldTableViewCell *cell in self.dataSource.cells) {
        cell.delegate = self;
        cell.lastInList = (cell == lastCell);
    }

    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(endEditing)]];
}

- (void)endEditing {
    [self.view endEditing:NO];
}

- (void)updateAppearance {
    [super updateAppearance];

    self.view.backgroundColor = self.theme.primaryBackgroundColor;

    STPTheme *navBarTheme = self.navigationController.navigationBar.stp_theme ?: self.theme;
    [self.doneItem stp_setTheme:navBarTheme];

    for (STPTextFieldTableViewCell *cell in self.dataSource.cells) {
        cell.theme = self.theme;
    }

    self.tableView.allowsSelection = NO;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self stp_beginObservingKeyboardAndInsettingScrollView:self.tableView
                                             onChangeBlock:nil];
    [[self firstEmptyField] becomeFirstResponder];
}

- (UIResponder *)firstEmptyField {
    for (STPTextFieldTableViewCell *cell in self.dataSource.cells) {
        if (cell.contents.length == 0) {
            return cell;
        }
    }
    return nil;
}

- (void)handleBackOrCancelTapped:(__unused id)sender {
    [self.delegate sourceInfoViewControllerDidCancel:self];
}

- (void)nextPressed:(__unused id)sender {
    STPSourceParams *params = [self.dataSource completedSourceParams];
    [self.delegate sourceInfoViewController:self
                  didFinishWithSourceParams:params];
}

- (void)updateDoneButton {
    self.stp_navigationItemProxy.rightBarButtonItem.enabled = self.validContents;
}

- (BOOL)validContents {
    BOOL valid = YES;
    for (STPTextFieldTableViewCell *cell in self.dataSource.cells) {
        valid = valid && cell.isValid;
    }
    return valid;
}

- (STPTextFieldTableViewCell *)cellBeforeCell:(STPTextFieldTableViewCell *)cell {
    NSInteger index = [self.dataSource.cells indexOfObject:cell];
    return [self.dataSource.cells stp_boundSafeObjectAtIndex:index - 1];
}

- (STPTextFieldTableViewCell *)cellAfterCell:(STPTextFieldTableViewCell *)cell {
    NSInteger index = [self.dataSource.cells indexOfObject:cell];
    return [self.dataSource.cells stp_boundSafeObjectAtIndex:index + 1];
}

#pragma mark - STPTextFieldTableViewCellDelegate

- (void)textFieldTableViewCellDidUpdateText:(__unused STPTextFieldTableViewCell *)cell {
    [self updateDoneButton];
}

- (void)textFieldTableViewCellDidReturn:(STPTextFieldTableViewCell *)cell {
    [[self cellAfterCell:cell] becomeFirstResponder];
}

- (void)textFieldTableViewCellDidBackspaceOnEmpty:(STPTextFieldTableViewCell *)cell {
    [[self cellBeforeCell:cell] becomeFirstResponder];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return [self.dataSource.cells count];
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(__unused UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.dataSource.cells stp_boundSafeObjectAtIndex:indexPath.row];
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

@end
