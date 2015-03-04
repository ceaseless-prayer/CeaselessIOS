//
//  DataViewController.m
//  Ceaseless
//
//  Created by Christopher Lim on 3/2/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "DataViewController.h"
#import "Person.h"
#import "PersonView.h"
#import <MessageUI/MessageUI.h>


@interface DataViewController () <MFMessageComposeViewControllerDelegate>

@end

@implementation DataViewController

static NSString *kInviteMessage;
static NSString *kSMSMessage;

+(void)initialize
{
	kInviteMessage =  NSLocalizedString(@"I prayed for you using the Ceaseless app today. You would like it. Search for Ceaseless Prayer in the App Store.", nil);
	kSMSMessage = NSLocalizedString(@"I prayed for you today when you came up in my Ceaseless app.", nil);
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
	[self registerForNotifications];
	self.personView = [PersonView alloc];
	self.personView = [[[NSBundle mainBundle] loadNibNamed:@"PersonView" owner:self options:nil] lastObject];
	NSLog (@"count %lu", (unsigned long)[self.personView.subviews count]);
	[self.cardView addSubview: self.personView];

    [self setDynamicViewConstraints];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	Person *person = self.dataObject;
	self.personView.nameLabel.text = [NSString stringWithFormat: @"%@ %@", person.firstName, person.lastName];
	self.personView.personImageView.image = person.profileImage;

	[self.personView.moreButton addTarget:self
								   action:@selector(presentActionSheet:)forControlEvents:UIControlEventTouchUpInside];


//	let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
//  let blurView = UIVisualEffectView(effect: blurEffect)
//  blurView.frame = myFrame
//  self.view.addSubview(blurView)
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
										[self showSMS: kSMSMessage];
										NSLog(@"Send Message");
										}];

//	UIAlertAction *createNoteAction = [UIAlertAction
//									actionWithTitle:NSLocalizedString(@"Create Note", @"Create Note")
//									   style:UIAlertActionStyleDefault
//									   handler:^(UIAlertAction *action)
//									   {
//									   NSLog(@"Create Note");
//									   }];

	[alertController addAction:cancelAction];
	[alertController addAction:inviteAction];
	[alertController addAction:sendMessageAction];
//	[alertController addAction:createNoteAction];

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
	Person *person = self.dataObject;
	NSArray *recipents = [NSArray arrayWithObjects: person.phoneNumber, nil];
	NSString *message = [NSString stringWithFormat: @"%@", file];

	MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
	messageController.messageComposeDelegate = self;
	[messageController setRecipients:recipents];
	[messageController setBody:message];

		// Present message view controller on screen
	[self presentViewController:messageController animated:YES completion:nil];
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

- (void)setDynamicViewConstraints {
    [self.personView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.cardView addConstraint:[NSLayoutConstraint constraintWithItem:self.personView
                                                              attribute:NSLayoutAttributeTop
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.cardView
                                                              attribute:NSLayoutAttributeTop
                                                             multiplier:1.0
                                                               constant:0.0]];
    
    [self.cardView addConstraint:[NSLayoutConstraint constraintWithItem:self.personView
                                                              attribute:NSLayoutAttributeLeading
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.cardView
                                                              attribute:NSLayoutAttributeLeading
                                                             multiplier:1.0
                                                               constant:0.0]];
    
    [self.cardView addConstraint:[NSLayoutConstraint constraintWithItem:self.personView
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.cardView
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0
                                                               constant:0.0]];
    
    [self.cardView addConstraint:[NSLayoutConstraint constraintWithItem:self.personView
                                                              attribute:NSLayoutAttributeTrailing
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.cardView
                                                              attribute:NSLayoutAttributeTrailing
                                                             multiplier:1.0
                                                               constant:0.0]];
}

@end
