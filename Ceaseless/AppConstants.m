//
//  AppConstants.m
//  Ceaseless
//
//  Created by Christopher Lim on 3/30/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "AppConstants.h"

@implementation AppConstants

    // id in the app store
    NSString *const kCeaselessAppstoreAppId = @"973610764";

    // user default key for storing the installation id
    NSString *const kLocalInstallationId = @"localInstallationId";

    // this is the user default key for whether or not
    // the app is in developer mode
    NSString *const kDeveloperMode = @"developerMode";

    // this is the user default key for the number of people
    // to pray for each day
    NSString *const kDailyPersonCount = @"DailyPersonCount";

	// this is the user default key for the first person
	// to pray for on the next day
	NSString *const kPersonForNextDay = @"PersonForNextDay";

    // this is the name of the file that will be the background image
    NSString *const kDynamicBackgroundImage = @"dynamicBackgroundImage";

    // this is the name of the file that will be the next background image
    NSString *const kNextDynamicBackgroundImage = @"nextDynamicBackgroundImage";

    // this is the date when Ceaseless app notifications fire
    NSString *const kNotificationDate = @"NotificationDate";

    // this is the most recent date when the address book for the device was synced to Ceaseless
    NSString *const kLocalLastAddressBookSyncedDate = @"localLastAddressBookSyncedDate";

    // cycle through praying for contacts
    // this is the date when the cycle began
    // once all contacts have been prayed for
    // this date is reset.
    NSString *const kPrayerCycleStartDate = @"prayerCycleStartDate";

    // this is the name of the notification that contacts have been synced
    NSString *const kContactsSyncedNotification = @"contactsSyncedNotification";

    // this is the name of the notification that the user wants to
    // show new content
    NSString *const kForceShowNewContent = @"forceShowNewContent";

	// this is the name of the notification that the the Loading... label should be hidden
	NSString *const kHideLoadingNotification = @"hideLoadingNotification";

@end
