//
//  PersonViewController.m
//  Ceaseless
//
//  Created by Christopher Lim on 3/6/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "PersonViewController.h"
#import "PersonNotesViewController.h"
#import "PersonInfo.h"
#import "Name.h"
#import "NoteViewController.h"
#import "AppDelegate.h"
#import "ModelController.h"
#import "AppUtils.h"
#import "CeaselessLocalContacts.h"
#import <MessageUI/MessageUI.h>
#import <AddressBookUI/AddressBookUI.h>
#import "ContactsListsViewController.h"

@interface PersonViewController () <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, ABPersonViewControllerDelegate>

@property (strong, nonatomic) UINavigationController *navController;
@end

@implementation PersonViewController

static NSString *kInviteMessage;
static NSString *kSMSMessage;


+(void)initialize
{
    kInviteMessage =  NSLocalizedString(@"I prayed for you using the Ceaseless app today. You would like it. Search for Ceaseless Prayer in the App Store.", nil);
    kSMSMessage = NSLocalizedString(@"I prayed for you today when you came up in my Ceaseless app.", nil);
}

- (void)viewDidLoad {

    [super viewDidLoad];

	NSArray *subviewArray = [[NSBundle mainBundle] loadNibNamed:@"PersonView" owner:self options:nil];
	self.personView = [subviewArray objectAtIndex:0];
	[self.mainView addSubview: self.personView];

	AppDelegate *appDelegate = (id) [[UIApplication sharedApplication] delegate];
	self.managedObjectContext = appDelegate.managedObjectContext;
    
    CeaselessLocalContacts *ceaselessContacts = [CeaselessLocalContacts sharedCeaselessLocalContacts];

    self.person = self.dataObject;
    
	self.personView.nameLabel.text = [ceaselessContacts compositeNameForPerson:self.person];
    UIImage *profileImage = [ceaselessContacts getImageForPersonIdentifier:self.person];
	if (profileImage) {
		self.personView.personImageView.image = profileImage;
		self.personView.personImageView.hidden = NO;
		self.personView.placeholderText.hidden = YES;
		self.personView.personImageView.layer.cornerRadius = 6.0f;
		[self.personView.personImageView setClipsToBounds:YES];
	} else {
		self.personView.personImageView.hidden = YES;
		self.personView.placeholderText.hidden = NO;
		self.personView.placeholderText.text = [ceaselessContacts initialsForPerson:self.person];
	}
    
    UIImage *backgroundImage = [AppUtils getDynamicBackgroundImage];
    if(backgroundImage != nil) {
        self.personView.personCardBackground.image = backgroundImage;
    }

	[self.personView.moreButton addTarget:self
								   action:@selector(presentActionSheet:)forControlEvents:UIControlEventTouchUpInside];
	UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
	self.personNotesViewController = [sb instantiateViewControllerWithIdentifier:@"PersonNotesViewController"];
    self.personNotesViewController.person = self.person;
	[self.personView.notesView addSubview: self.personNotesViewController.tableView];
	self.personNotesViewController.tableView.delegate = self;
	[self setDynamicViewConstraintsToView: self.personView.notesView forSubview: self.personNotesViewController.tableView ];

    [self registerForNotifications];

	[self formatCardView: self.personView.cardView withShadowView: self.personView.shadowView];

    // fallback if user disables transparency/blur effect
    if(UIAccessibilityIsReduceTransparencyEnabled()) {
        ((UIView *) self.personView.blurEffect.subviews[0]).backgroundColor = [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.5f];
    }
		//force the view down below the navigation bar is segued from People Table
	if ([[self backViewController] isMemberOfClass:[ContactsListsViewController class]]) {
		self.personView.topToCardViewConstraint.constant = 64;
	}

}
- (UIViewController *)backViewController
{
	NSInteger numberOfViewControllers = self.navigationController.viewControllers.count;

	if (numberOfViewControllers < 2)
		return nil;
	else
		return [self.navigationController.viewControllers objectAtIndex:numberOfViewControllers - 2];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)setDynamicViewConstraintsToView: (UIView *) parentView forSubview: (UIView *) newSubview {
	[newSubview setTranslatesAutoresizingMaskIntoConstraints:NO];

	[parentView addConstraint:[NSLayoutConstraint constraintWithItem:newSubview
															  attribute:NSLayoutAttributeTop
															  relatedBy:NSLayoutRelationEqual
																 toItem:parentView
															  attribute:NSLayoutAttributeTop
															 multiplier:1.0
															   constant:0.0]];

	[parentView addConstraint:[NSLayoutConstraint constraintWithItem:newSubview
															  attribute:NSLayoutAttributeLeading
															  relatedBy:NSLayoutRelationEqual
																 toItem:parentView
															  attribute:NSLayoutAttributeLeading
															 multiplier:1.0
															   constant:0.0]];

	[parentView addConstraint:[NSLayoutConstraint constraintWithItem:newSubview
															  attribute:NSLayoutAttributeBottom
															  relatedBy:NSLayoutRelationEqual
																 toItem:parentView
															  attribute:NSLayoutAttributeBottom
															 multiplier:1.0
															   constant:0.0]];

	[parentView addConstraint:[NSLayoutConstraint constraintWithItem:newSubview
															  attribute:NSLayoutAttributeTrailing
															  relatedBy:NSLayoutRelationEqual
																 toItem:parentView
															  attribute:NSLayoutAttributeTrailing
															 multiplier:1.0
															   constant:0.0]];
}

#pragma mark - Saving context for changes to PersonIdentifier
- (void) save {
    // save
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
    }
}

#pragma mark - TableView Delegate

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NoteViewController *noteViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"NoteViewController"];
	noteViewController.delegate = self;

	if (self.personNotesViewController.notesAvailable == YES) {
		noteViewController.currentNote = [self.personNotesViewController.fetchedResultsController objectAtIndexPath:indexPath];
	} else {
		noteViewController.personForNewNote = self.personNotesViewController.person;
	}

	[self presentViewController:noteViewController animated:YES completion:NULL];

}
#pragma mark - NoteViewControllerDelegate protocol conformance

- (void)noteViewControllerDidFinish:(NoteViewController *)noteViewController
{

	[noteViewController dismissViewControllerAnimated:YES completion:NULL];

}

- (void)noteViewControllerDidCancel:(NoteViewController *)noteViewController
{
	[noteViewController dismissViewControllerAnimated:YES completion:NULL];

}
#pragma mark - Action Sheet

-(void) presentActionSheet: (UIButton *) sender {
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:nil
                                          message:nil
                                          preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel action")
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
                                       NSLog(@"Cancel action");
                                   }];

    UIAlertAction *inviteAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"Invite to Ceaseless", @"Invite to Ceaseless")
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       [self showSMS: kInviteMessage];
                                       NSLog(@"Invite to Ceaseless");
                                   }];
    
    UIAlertAction *sendMessageAction = [UIAlertAction
                                        actionWithTitle:NSLocalizedString(@"Send Message", @"Send Message")
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction *action)
                                        {
                                            PersonInfo *info = self.person.representativeInfo;
                                            // TODO should we switch the order?
                                            if(info.primaryPhoneNumber) {
                                                [self showSMS: kSMSMessage];
                                            } else if(info.primaryEmail) {
                                                [self showEmailForm];
                                            } else {
                                                UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Error", nil)
                                                                                                       message:NSLocalizedString(@"Could not send a message because this person is missing contact information.", nil)
                                                                                                      delegate:nil
                                                                                             cancelButtonTitle:@"OK"
                                                                                             otherButtonTitles:nil];
                                                
                                                [warningAlert show];
                                            }
                                            NSLog(@"Send Message");
                                        }];
    
    UIAlertAction *removeFromCeaselessAction = [UIAlertAction
                                        actionWithTitle:NSLocalizedString(@"Remove from Ceaseless", @"Remove from Ceaseless")
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction *action)
                                        {
                                            [self removePersonFromCeaseless];
                                            NSLog(@"Remove from Ceaseless");
                                        }];
    
    UIAlertAction *addToFavoritesAction = [UIAlertAction
                                        actionWithTitle:NSLocalizedString(@"Add to Favorites", @"Add to Favorites")
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction *action)
                                        {
                                            [self addPersonToFavorites];
                                            NSLog(@"Add to Favorites");
                                        }];
    
    UIAlertAction *unfavoriteAction = [UIAlertAction
                                           actionWithTitle:NSLocalizedString(@"Remove from Favorites", @"Remove from Favorites")
                                           style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction *action)
                                           {
                                               [self removePersonFromFavorites];
                                               NSLog(@"Remove from Favorites");
                                           }];
    
    UIAlertAction *addNote = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"Add note", @"Add note")
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action)
                                       {
                                           [self addNote];
                                           NSLog(@"Add note");
                                       }];
    
    UIAlertAction *viewContact = [UIAlertAction
                              actionWithTitle:NSLocalizedString(@"View contact", @"View contact")
                              style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction *action)
                              {
                                  [self showABPerson];
                                  NSLog(@"Showing contact");
                              }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:removeFromCeaselessAction];
    [alertController addAction:inviteAction];
    [alertController addAction:sendMessageAction];
    [alertController addAction:addNote];
    [alertController addAction:viewContact];
    
    // TODO this should toggle between adding or removing from favorites.
    // for now only show it if it isn't already favorited
    if (self.person.favoritedDate == nil) {
        [alertController addAction: addToFavoritesAction];
    } else {
        [alertController addAction: unfavoriteAction];
    }
    
    //this prevents crash on iPad in iOS 8 - known Apple bug
    UIPopoverPresentationController *popover = alertController.popoverPresentationController;
    if (popover)
    {
        popover.sourceView = sender;
        popover.sourceRect = sender.bounds;
        popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
    }
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)removePersonFromCeaseless {
    self.person.removedDate = [NSDate date];
    [self save];
    
    //if the card is in a pageController then its in the card deck, if its not then it was called by the contacts list
	if ([self.parentViewController isKindOfClass: [UIPageViewController class]]) {
		UIPageViewController *pageViewController =(UIPageViewController*)self.parentViewController;
		ModelController *mc = pageViewController.dataSource;
		[mc removeControllerAtIndex:self.index];
		DataViewController *startingViewController; // card to transition to.
		// if there is a card after us, transition there.
		if([mc modelCount] > self.index) {
			// self.index is now pointing to the next card
			startingViewController = [mc viewControllerAtIndex:self.index storyboard:self.storyboard];
			startingViewController.index = self.index;
			[pageViewController setViewControllers:@[startingViewController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];

		} else if(self.index > 0) {
			// otherwise, if there is a card before us, transition there.
			--self.index;
			startingViewController.index = self.index;
			startingViewController = [mc viewControllerAtIndex:self.index storyboard:self.storyboard];
			[pageViewController setViewControllers:@[startingViewController] direction:UIPageViewControllerNavigationDirectionReverse animated:YES completion:nil];

		} else {
			// by default go to the first card in the array
			startingViewController.index = 0;
			startingViewController = [mc viewControllerAtIndex:0 storyboard:self.storyboard];
			[pageViewController setViewControllers:@[startingViewController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];

		}
	} else {
		[self performSegueWithIdentifier:@"UnwindToContactsListsSegue" sender: self];
	}

}

// TODO enable for ceaseless as well when you reach this view not from the pageviewcontroller

- (void)addNote {
    NoteViewController *noteViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"NoteViewController"];
    noteViewController.delegate = self;
    noteViewController.personForNewNote = self.personNotesViewController.person;
    [self presentViewController:noteViewController animated:YES completion:nil];
}

- (void)addPersonToFavorites {
    self.person.favoritedDate = [NSDate date];
    [self save];
    // TODO animate?
}

- (void)removePersonFromFavorites {
    self.person.favoritedDate = nil;
    [self save];
    // TODO animate?
}

- (void) showABPerson {
    ABPersonViewController *view = [[ABPersonViewController alloc] init];
    
    view.personViewDelegate = self;
    CeaselessLocalContacts *ceaselessContacts = [CeaselessLocalContacts sharedCeaselessLocalContacts];
    
    view.displayedPerson = [ceaselessContacts getRepresentativeABPersonForCeaselessContact:self.person];
    [self.navigationController pushViewController:view animated:YES];
}

- (BOOL) personViewController:(ABPersonViewController*) controller shouldPerformDefaultActionForPerson: (ABRecordRef) person property: (ABPropertyID) property identifier: (ABMultiValueIdentifier) identifier {
    return YES;
}

#pragma mark - Direct contact methods
- (void)showSMS:(NSString*)file {
    
    if(![MFMessageComposeViewController canSendText]) {
        UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Error", nil)
                                                               message:NSLocalizedString(@"Your device doesn't support SMS!", nil)
                                                              delegate:nil
                                                     cancelButtonTitle:@"OK"
                                                     otherButtonTitles:nil];
        
        [warningAlert show];
        return;
    }
    NSArray *recipents = [NSArray arrayWithObjects:self.person.representativeInfo.primaryPhoneNumber.number, nil];
    NSString *message = [NSString stringWithFormat: @"%@", file];
    
    MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
    messageController.messageComposeDelegate = self;
    [messageController setRecipients:recipents];
    [messageController setBody:message];
    
    // Present message view controller on screen
    [self presentViewController:messageController animated:YES completion:nil];
}

- (void)showEmailForm {
    NSArray *recipents = [NSArray arrayWithObjects:self.person.representativeInfo.primaryEmail.address, nil];
    MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
    mailController.mailComposeDelegate = self;
    [mailController setToRecipients: recipents];
    
    // Present mail view controller on screen
    [self presentViewController:mailController animated:YES completion:nil];
}


#pragma mark - MessageUI delegate methods

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult) result
{
    switch (result) {
        case MessageComposeResultCancelled:
            break;
            
        case MessageComposeResultFailed:
        {
            UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Failed to send SMS!", nil)
                                                                  delegate:nil
                                                         cancelButtonTitle:@"OK"
                                                         otherButtonTitles:nil];
            
            [warningAlert show];
            break;
        }
            
        case MessageComposeResultSent:
            break;
            
        default:
            break;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}



- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult) result error: (NSError*) error
{
    UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Did not send message.", nil) delegate:nil
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
                break;
                
            default:
                break;
        }
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Notification handling

- (void) registerForNotifications {
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    //needed to dismiss action sheet
    [notificationCenter addObserver: self
                           selector: @selector (didEnterBackground:)
                               name: UIApplicationDidEnterBackgroundNotification
                             object: nil];
}

- (void)didEnterBackground:(NSNotification *)notification {
    //dismiss the action sheet
    [self.presentedViewController dismissViewControllerAnimated:NO completion:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
}
@end
