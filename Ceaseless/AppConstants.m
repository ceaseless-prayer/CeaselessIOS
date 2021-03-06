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

    // this is the date the app was installed.
    NSString *const kLocalInstallationDate = @"localInstallationDate";

    // This is used to count the number of days the app has been opened
    // for display in the progress card
    // it is a different take on the "streak" gamification idea
    NSString *const kDaysAppOpened = @"daysAppOpened";

    // when the app was last refreshed, used by modelController and rootViewController
    // primarily to determine if it is a new day.
    NSString *const kLocalLastRefreshDate = @"localLastRefreshDate";

    // this is the user default key for whether or not
    // the app is in developer mode
    NSString *const kDeveloperMode = @"developerMode";

    // this is the user default key for the number of people
    // to pray for each day
    NSString *const kDailyPersonCount = @"DailyPersonCount";

	// this is the user default key for the first person
	// to pray for on the next day
	NSString *const kPersonForNextDay = @"PersonForNextDay";
	NSString *const kPersonNameForNextDay = @"PersonNameForNextDay";

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

    // this is determining whether contact permission needs to ask later or not
    NSString *const kDoesSetupContactNeedToAskLater = @"doesSetupContactNeedToAskLater";

    // this is determining whether notification permission needs to ask later or not
    NSString *const kDoesSetupNotificationNeedToAskLater = @"doesSetupNotificationNeedToAskLater";

    // this is the date of onboarding last opened date
    NSString *const kOnboardingLastOpenedDate = @"onboardingLastOpenedDate";

@end
