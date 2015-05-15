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
#import "UIFont+FontAwesome.h"
#import "NSString+FontAwesome.h"
#import "PhoneNumber.h"
#import "Email.h"

@interface PersonViewController () <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, ABPersonViewControllerDelegate>

@property (strong, nonatomic) UINavigationController *navController;
@end

@implementation PersonViewController

static NSString *kInviteMessage;
static NSString *kSMSMessage;
static NSString *kMessageError;
static NSString *kInvitationError;


+(void)initialize
{
    kInviteMessage =  NSLocalizedString(@"I prayed for you using the Ceaseless app today. You would like it. https://appsto.re/us/m8bc6.i", nil);
    kSMSMessage = NSLocalizedString(@"I prayed for you today when you came up in my Ceaseless app. https://appsto.re/us/m8bc6.i", nil);
	kMessageError = NSLocalizedString(@"Could not send a message because this person is missing contact information.", nil);
	kInvitationError = NSLocalizedString(@"Could not send an invitation because this person is missing contact information.", nil);


}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.screenName = @"PersonViewScreen";
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
		self.personView.personImageView.contentMode = UIViewContentModeScaleAspectFill;
		self.personView.personImageView.hidden = NO;
		self.personView.placeholderText.hidden = YES;
		self.personView.personImageView.layer.cornerRadius = 6.0f;
		[self.personView.personImageView setClipsToBounds:YES];
	} else {
		self.personView.personImageView.hidden = YES;
		self.personView.placeholderText.hidden = NO;
		self.personView.placeholderText.text = [ceaselessContacts initialsForPerson:self.person];
	}
    
    // setup quick actions on card
    NSString *favoriteIcon = [NSString fontAwesomeIconStringForEnum:FAHeartO];
    if (self.person.favoritedDate != nil) {
        favoriteIcon = [NSString fontAwesomeIconStringForEnum:FAHeart];
    }
    
    [self.personView.favoriteButton setTitle:favoriteIcon forState:UIControlStateNormal];
    [self.personView.addNoteButton setTitle:[NSString fontAwesomeIconStringForEnum:FAPencil] forState:UIControlStateNormal];
    [self.personView.contactButton setTitle: [NSString fontAwesomeIconStringForEnum:FApaperPlaneO] forState:UIControlStateNormal];
    
    UIImage *backgroundImage = [AppUtils getDynamicBackgroundImage];
    if(backgroundImage != nil) {
        self.personView.personCardBackground.image = backgroundImage;
    }

	[self.personView.moreButton addTarget:self
								   action:@selector(presentActionSheet:)forControlEvents:UIControlEventTouchUpInside];

	[self.personView.personButton addTarget:self
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
}
- (UIViewController *)backViewController
{
	NSInteger numberOfViewControllers = self.navigationController.viewControllers.count;

	if (numberOfViewControllers < 2)
		return nil;
	else
		return [self.navigationController.viewControllers objectAtIndex:numberOfViewControllers - 2];
}

- (void) viewWillDisappear:(BOOL)animated {
	[self.personNotesViewController.tableView deselectRowAtIndexPath:[self.personNotesViewController.tableView indexPathForSelectedRow] animated:animated];
	[super viewWillDisappear:animated];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NoteViewController *noteViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"NoteViewController"];
	noteViewController.delegate = self;

	if (self.personNotesViewController.notesAvailable == YES) {
		noteViewController.currentNote = [self.personNotesViewController.fetchedResultsController objectAtIndexPath:indexPath];
	} else {
		noteViewController.personForNewNote = self.personNotesViewController.person;
	}

	[self performAnimationAndPushController:noteViewController];
}

- (void) performAnimationAndPushController: (NoteViewController *) noteViewController {

	CATransition* transition = [CATransition animation];
	transition.duration = 0.3f;
	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
	transition.type = kCATransitionMoveIn; //kCATransitionMoveIn; //, kCATransitionPush, kCATransitionReveal, kCATransitionFade
	transition.subtype = kCATransitionFromTop; //kCATransitionFromLeft, kCATransitionFromRight, kCATransitionFromTop, kCATransitionFromBottom

	[self.navigationController.view.layer addAnimation:transition forKey:kCATransition];
	[self.navigationController pushViewController:noteViewController animated:NO];
}

#pragma mark - NoteViewControllerDelegate protocol conformance

- (void)noteViewControllerDidFinish:(NoteViewController *)noteViewController
{
	[self performDismissAnimationForController:noteViewController];

}

- (void)noteViewControllerDidCancel:(NoteViewController *)noteViewController
{
	[self performDismissAnimationForController:noteViewController];

}

- (void) performDismissAnimationForController: (NoteViewController *)noteViewController {
	CATransition* transition = [CATransition animation];
	transition.duration = 0.3f;
	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
	transition.type = kCATransitionReveal; //kCATransitionMoveIn; //, kCATransitionPush, kCATransitionReveal, kCATransitionFade
	transition.subtype = kCATransitionFromBottom; //kCATransitionFromLeft, kCATransitionFromRight, kCATransitionFromTop, kCATransitionFromBottom

	[self.navigationController.view.layer addAnimation:transition forKey:kCATransition];
	[self.navigationController popViewControllerAnimated:NO];

}
#pragma mark - Action Sheet

-(void) presentActionSheet: (UIButton *) sender {
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:NSLocalizedString(@"More actions", @"More actions")
                                          message:nil
                                          preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel action")
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
                                       NSLog(@"Cancel action");
                                   }];

    NSString *invitationActionTitle = @"Invite to Ceaseless";
    if(self.person.lastInvitedDate != nil) {
        NSString *formattedDate = [NSDateFormatter localizedStringFromDate:self.person.lastInvitedDate
                                                                 dateStyle:NSDateFormatterShortStyle
                                                                 timeStyle:NSDateFormatterNoStyle];
        invitationActionTitle = [NSString stringWithFormat: @"Invited %@", formattedDate];
    }
    
    UIAlertAction *inviteAction = [UIAlertAction
                                   actionWithTitle:invitationActionTitle
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
								   [self presentMessageActionSheetWithMessage: kInviteMessage];
								   [AppUtils postAnalyticsEventWithCategory:@"person_card_actions" andAction:@"tapped_invite" andLabel:@""];

                                       NSLog(@"Invite to Ceaseless");
                                       
                                   }];
    
    UIAlertAction *removeFromCeaselessAction = [UIAlertAction
                                        actionWithTitle:NSLocalizedString(@"Remove from Ceaseless", @"Remove from Ceaseless")
                                        style:UIAlertActionStyleDestructive
                                        handler:^(UIAlertAction *action)
                                        {
                                            [self removePersonFromCeaseless];
                                            NSLog(@"Remove from Ceaseless");
                                        }];
    
    UIAlertAction *addToCeaselessAction = [UIAlertAction
                                                actionWithTitle:NSLocalizedString(@"Add to Ceaseless", @"Add to Ceaseless")
                                                style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action)
                                                {
                                                    [self addPersonToCeaseless];
                                                    NSLog(@"Add to Ceaseless");
                                                }];
    
    UIAlertAction *viewContact = [UIAlertAction
                              actionWithTitle:NSLocalizedString(@"View in Contacts", @"View in Contacts")
                              style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction *action)
                              {
                                  [AppUtils postAnalyticsEventWithCategory:@"person_card_actions" andAction:@"tapped_view_contact" andLabel:@""];
                                  [self showABPerson];
                                  NSLog(@"Showing contact");
                              }];

	NSString *favoriteTitleString;
	if (self.person.favoritedDate) {
		favoriteTitleString = @"Unfavorite Contact";
	} else {
		favoriteTitleString = @"Favorite Contact";

	}
	UIAlertAction *favoriteContact = [UIAlertAction
								  actionWithTitle:NSLocalizedString(favoriteTitleString, favoriteTitleString)
								  style:UIAlertActionStyleDefault
								  handler:^(UIAlertAction *action)
								  {
								  [AppUtils postAnalyticsEventWithCategory:@"person_card_actions" andAction:@"tapped_view_contact" andLabel:@""];
								  [self toggleFavorite: self];
								  NSLog(@"Favorite/Unfavorite from menu");
								  }];

	UIAlertAction *sendMessage = [UIAlertAction
									  actionWithTitle:NSLocalizedString(@"Send Message to Contact", @"Send Message To Contact")
									  style:UIAlertActionStyleDefault
									  handler:^(UIAlertAction *action)
									  {
									  [AppUtils postAnalyticsEventWithCategory:@"person_card_actions" andAction:@"tapped_send_message" andLabel:@""];
									  [self presentMessageActionSheetWithMessage: kSMSMessage];
									  NSLog(@"Send message from menu");
									  }];

	UIAlertAction *addNote = [UIAlertAction
								  actionWithTitle:NSLocalizedString(@"Add a New Note", @"Add a New Note")
								  style:UIAlertActionStyleDefault
								  handler:^(UIAlertAction *action)
								  {
								  [AppUtils postAnalyticsEventWithCategory:@"person_card_actions" andAction:@"tapped_add_note" andLabel:@""];
								  [self addNote: self];
								  NSLog(@"Add note from menu");
								  }];

    [alertController addAction:cancelAction];
	[alertController addAction:favoriteContact];
	[alertController addAction:sendMessage];
	[alertController addAction:addNote];

    if(self.person.removedDate == nil) {
        [alertController addAction:removeFromCeaselessAction];
    } else {
        [alertController addAction:addToCeaselessAction];
    }

    [alertController addAction:inviteAction];
    [alertController addAction:viewContact];
    
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

- (void)addPersonToCeaseless {
    self.person.removedDate = nil;
    [self save];
}

- (void)removePersonFromCeaseless {
    self.person.removedDate = [NSDate date];
    if(self.person.queued) {
        [self.managedObjectContext deleteObject: (NSManagedObject*)self.person.queued];
    }
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

- (IBAction) toggleFavorite: (id) sender {
    if (self.person.favoritedDate) {
        [self.personView.favoriteButton setTitle: [NSString fontAwesomeIconStringForEnum:FAHeartO] forState:UIControlStateNormal];
        [self removePersonFromFavorites];
    } else {
        [self.personView.favoriteButton setTitle: [NSString fontAwesomeIconStringForEnum:FAHeart] forState:UIControlStateNormal];
        [self addPersonToFavorites];
    }

}
- (IBAction) addNote: (id) sender {
    [AppUtils postAnalyticsEventWithCategory:@"person_card_actions" andAction:@"tapped_add_note" andLabel:@""];
	NoteViewController *noteViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"NoteViewController"];
	noteViewController.delegate = self;
	noteViewController.personForNewNote = self.personNotesViewController.person;

	[self performAnimationAndPushController: noteViewController];
}
- (IBAction) sendMessage: (id) sender {
	[self presentMessageActionSheetWithMessage: kSMSMessage];
}
// TODO enable for ceaseless as well when you reach this view not from the pageviewcontroller??


-(void) presentMessageActionSheetWithMessage: (NSString*) message {
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

	[alertController addAction:cancelAction];

	PersonInfo *info = self.person.representativeInfo;
	for (PhoneNumber *phoneNumber in self.person.phoneNumbers) {
		[AppUtils postAnalyticsEventWithCategory:@"person_card_actions" andAction:@"tapped_send_message" andLabel:@"sms"];
		UIAlertAction *phoneNumberAction = [UIAlertAction
					actionWithTitle:NSLocalizedString(phoneNumber.number, phoneNumber.number)
					style:UIAlertActionStyleDefault
					handler:^(UIAlertAction *action)
					{
					[self showSMSFormForPhoneNumber: phoneNumber withMessage: message];
					}];
		[alertController addAction:phoneNumberAction];

	}


	for (Email *email in self.person.emails) {
		[AppUtils postAnalyticsEventWithCategory:@"person_card_actions" andAction:@"tapped_send_message" andLabel:@"email"];
		UIAlertAction *emailAction = [UIAlertAction
					actionWithTitle:NSLocalizedString(email.address, email.address)
					style:UIAlertActionStyleDefault
					handler:^(UIAlertAction *action)
					{
					[self showFormForEmail: email withMessage: message];
					}];
		[alertController addAction:emailAction];


	}

	if (info.primaryPhoneNumber || info.primaryEmail) { //there is at least one valid way to contact

			//this prevents crash on iPad in iOS 8 - known Apple bug
		UIPopoverPresentationController *popover = alertController.popoverPresentationController;
		if (popover)
			{
			popover.sourceView = self.view;
			popover.sourceRect = self.view.frame;
			popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
			}

		[self presentViewController:alertController animated:YES completion:nil];

	} else {
		NSString *errorMessage;
		if (message == kSMSMessage) {
			errorMessage = kMessageError;
		} else {
			errorMessage = kInvitationError;
		}

		UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Error", nil)
															   message: errorMessage
															  delegate:nil
													 cancelButtonTitle:@"OK"
													 otherButtonTitles:nil];

		[warningAlert show];

	}

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
- (void)showSMSFormForPhoneNumber: (PhoneNumber*) phoneNumber withMessage: (NSString *) message {
    
    if(![MFMessageComposeViewController canSendText]) {
        UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Error", nil)
                                                               message:NSLocalizedString(@"Your device doesn't support SMS!", nil)
                                                              delegate:nil
                                                     cancelButtonTitle:@"OK"
                                                     otherButtonTitles:nil];
        
        [warningAlert show];
        return;
    }
    NSArray *recipents = [NSArray arrayWithObjects:phoneNumber.number, nil];

    MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
    messageController.messageComposeDelegate = self;
    [messageController setRecipients:recipents];
    [messageController setBody:message];

		//if this is an invitation, save the invite date
	if (message == kInviteMessage) {
		self.person.lastInvitedDate = [NSDate date];
		[self save];
	}

    // Present message view controller on screen
    [self presentViewController:messageController animated:YES completion:nil];
}

- (void) showFormForEmail: (Email*) email withMessage: (NSString *) message {
    NSArray *recipents = [NSArray arrayWithObjects:email.address, nil];
    MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
    mailController.mailComposeDelegate = self;
    [mailController setToRecipients: recipents];
	[mailController setSubject: @"Ceaseless Prayer"];
	NSString *emailBody = [NSString stringWithFormat: @"%@,\n\n%@",self.person.representativeInfo.primaryFirstName.name, message];
	[mailController setMessageBody: emailBody  isHTML: NO];

		//if this is an invitation, save the invite date
	if (message == kInviteMessage) {
		self.person.lastInvitedDate = [NSDate date];
		[self save];
	}
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
