//
//  PersonViewController.m
//  Ceaseless
//
//  Created by Christopher Lim on 3/6/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "PersonViewController.h"
#import "Person.h"
#import <MessageUI/MessageUI.h>
//#import <QuartzCore/QuartzCore.h>

@interface PersonViewController () <MFMessageComposeViewControllerDelegate>

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
    [self registerForNotifications];

	[self formatCardView: self.personView.cardView withShadowView: self.personView.shadowView];

    // fallback if user disables transparency/blur effect
    if(UIAccessibilityIsReduceTransparencyEnabled()) {
        ((UIView *) self.personView.blurEffect.subviews[0]).backgroundColor = [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.5f];
    }

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    Person *person = self.dataObject;
    self.personView.nameLabel.text = [NSString stringWithFormat: @"%@ %@", person.firstName, person.lastName];
	if (person.profileImage) {
		self.personView.personImageView.image = person.profileImage;
		self.personView.personImageView.hidden = NO;
		self.personView.placeholderText.hidden = YES;

		self.personView.personImageView.layer.cornerRadius = 6.0f;
		[self.personView.personImageView setClipsToBounds:YES];
	} else {
		NSString *firstInitial = [person.firstName substringToIndex: 1];
		NSString *lastInitial = [person.lastName substringToIndex: 1];
		self.personView.personImageView.hidden = YES;
		self.personView.placeholderText.hidden = NO;
		self.personView.placeholderText.text = [NSString stringWithFormat: @"%@%@", firstInitial, lastInitial];
	}

        
    [self.personView.moreButton addTarget:self
                                   action:@selector(presentActionSheet:)forControlEvents:UIControlEventTouchUpInside];

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
@end
