//
//  AppConstants.h
//  Ceaseless
//
//  Created by Christopher Lim on 3/30/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppConstants : NSObject
    FOUNDATION_EXPORT NSString *const kLocalInstallationId;
    FOUNDATION_EXPORT NSString *const kLocalInstallationDate;
    FOUNDATION_EXPORT NSString *const kCeaselessAppstoreAppId;
    FOUNDATION_EXPORT NSString *const kDeveloperMode;
    FOUNDATION_EXPORT NSString *const kDailyPersonCount;
	FOUNDATION_EXPORT NSString *const kPersonForNextDay;
	FOUNDATION_EXPORT NSString *const kPersonNameForNextDay;
    FOUNDATION_EXPORT NSString *const kDynamicBackgroundImage;
    FOUNDATION_EXPORT NSString *const kNextDynamicBackgroundImage;
    FOUNDATION_EXPORT NSString *const kNotificationDate;
    FOUNDATION_EXPORT NSString *const kLocalLastAddressBookSyncedDate;
    FOUNDATION_EXPORT NSString *const kPrayerCycleStartDate;
    FOUNDATION_EXPORT NSString *const kContactsSyncedNotification;
    FOUNDATION_EXPORT NSString *const kForceShowNewContent;
	FOUNDATION_EXPORT NSString *const kHideLoadingNotification;
    FOUNDATION_EXPORT NSString *const kDoesSetupContactNeedToAskLater;
    FOUNDATION_EXPORT NSString *const kDoesSetupNotificationNeedToAskLater;
    FOUNDATION_EXPORT NSString *const kOnboardingLastOpenedDate;
@end
