//
//  MenuViewController.m
//  Ceaseless
//
//  Created by Lori Hill on 3/20/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "MenuViewController.h"
#import "AppConstants.h"
#import "AppUtils.h"
#import <MessageUI/MessageUI.h>
#import "WebCardViewController.h"
#import "CeaselessService.h"
#import "AppConstants.h"

@import StoreKit;
@interface MenuViewController () <MFMailComposeViewControllerDelegate, SKStoreProductViewControllerDelegate>

@end

@implementation MenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

	[self.navigationItem setHidesBackButton:YES];

	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.menuInfoArray = [[NSMutableArray alloc] initWithObjects: @"People", @"Settings", @"Help", @"Contact Us", @"About", @"Review Ceaseless", @"Subscribe to Newsletter", nil];
    [self.menuInfoArray addObject: @""]; // for the developer mode row
    UIImage *background = [AppUtils getDynamicBackgroundImage];
    if(background != nil) {
        self.menuBackground.image = background;
    }
}

- (void) viewWillDisappear:(BOOL)animated {
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:animated];
	[super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.menuInfoArray count];

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	[self configureCell:cell atIndexPath:indexPath];
	return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	cell.textLabel.text = [self.menuInfoArray objectAtIndex: indexPath.row];
	cell.backgroundColor = [UIColor clearColor];

	if (indexPath.row == 7) {
        [cell setAccessoryType: UITableViewCellAccessoryNone];
        UITapGestureRecognizer *tripleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTripleTap:)];
        tripleTap.numberOfTapsRequired = 3;
        [cell addGestureRecognizer:tripleTap];
	}
}

- (void)handleTripleTap:(UIGestureRecognizer *)gestureRecognizer {
    NSLog(@"Triple Tap Detected..");
    UITableViewCell *cell = (UITableViewCell*)gestureRecognizer.view;
    cell.textLabel.text = @"Developer mode";
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
    cell.accessoryView = switchView;
    
    BOOL developerMode = [[NSUserDefaults standardUserDefaults] boolForKey: kDeveloperMode];
    [switchView setOn: developerMode animated:NO];
    [switchView addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
		// Return NO if you do not want the specified item to be editable.
	return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == 0) {
		[self performSegueWithIdentifier:@"ShowContactsLists" sender: self];
	}
    
	if (indexPath.row == 1) {
		[self performSegueWithIdentifier:@"ShowSettings" sender: self];
	}
    
    if (indexPath.row == 2) {
        WebCardViewController *webView = [[WebCardViewController alloc]init];
		webView.title = [self.menuInfoArray objectAtIndex: indexPath.row];
        webView.dataObject = [[CeaselessService sharedCeaselessService]getUrlForKey:kHelpURL];
        [self.navigationController pushViewController:webView animated:YES];
    }
    
    if (indexPath.row == 3) {
        [self showFeedbackForm];
    }
    
    if (indexPath.row == 4) {
        WebCardViewController *webView = [[WebCardViewController alloc]init];
		webView.title = [self.menuInfoArray objectAtIndex: indexPath.row];
        webView.dataObject = [[CeaselessService sharedCeaselessService]getUrlForKey:kCeaselessAboutURL];
        [self.navigationController pushViewController:webView animated:YES];
    }

    if (indexPath.row == 5) {
        SKStoreProductViewController *productViewController = [[SKStoreProductViewController alloc]init];
        productViewController.delegate = self;
        // TODO why is the completionBlock not being called? Because the ID doesn't work yet.
        [productViewController loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier: [NSNumber numberWithInteger:[kCeaselessAppstoreAppId integerValue]]} completionBlock:^(BOOL result, NSError *error) {
            if(result) {
                [self presentViewController:productViewController animated:YES completion:nil];
//                [self.navigationController pushViewController:productViewController animated:YES];
            } else {
                UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Could not show Ceaseless in App Store.", nil) delegate:nil
                                                             cancelButtonTitle:@"OK"
                                                             otherButtonTitles:nil];
                [warningAlert show];
            }
        }];
    }

    if (indexPath.row == 6) {
        WebCardViewController *webView = [[WebCardViewController alloc]init];
		webView.title = [self.menuInfoArray objectAtIndex: indexPath.row];
        webView.dataObject = [[CeaselessService sharedCeaselessService]getUrlForKey:kSubscribeToMailingListURL];
        [self.navigationController pushViewController:webView animated:YES];
    }

}

- (void) productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

- (void) switchChanged:(id)sender {
	UISwitch* switchControl = sender;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	BOOL developerMode = switchControl.on ? YES : NO;
	[defaults setBool: developerMode forKey:kDeveloperMode];
	[defaults synchronize];
	NSLog( @"The switch is %@", switchControl.on ? @"YES" : @"NO" );
}

	// Action receiver for the clicking of Cancel button
- (IBAction)menuDoneClicked:(id)sender
{
	[self.delegate menuViewControllerDidFinish: self];
}

#pragma mark - Give Feedback
- (void)showFeedbackForm {
    NSArray *recipents = [NSArray arrayWithObjects:@"ceaseless@theotech.org", nil];
    NSString *subject = @"Ceaseless for iOS Feedback";
    
    MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
    mailController.mailComposeDelegate = self;
    [mailController setToRecipients: recipents];
    [mailController setSubject:subject];
    
    // Present mail view controller on screen
    [self presentViewController:mailController animated:YES completion:nil];
}

#pragma mark - MessageUI delegate methods

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult) result error: (NSError*) error
{
    UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Did not send feedback.", nil) delegate:nil
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
    UIAlertView *thanksAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Thank you!", nil) message:NSLocalizedString(@"Thanks for your feedback.", nil) delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
    
    if(error) {
        [warningAlert show];
    } else {
        switch (result) {
            case MFMailComposeResultCancelled:
                break;
                
            case MFMailComposeResultFailed:
            {
                [warningAlert show];
            }
                break;
                
            case MFMailComposeResultSent:
            {
                [thanksAlert show];
            }
                break;
                
            default:
                break;
        }
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
