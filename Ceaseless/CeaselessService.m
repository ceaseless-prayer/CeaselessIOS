//
//  CeaselessService.m
//  Ceaseless
//
//  Created by Christopher Lim on 4/15/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "CeaselessService.h"

@implementation CeaselessService
NSString *const kFetchNewScriptureImageURL = @"fetchScriptureImagesURL";
NSString *const kFetchVerseOfTheDayURL = @"fetchVerseOfTheDayURL";
NSString *const kFetchScriptureURL = @"fetchScriptureURL";
NSString *const kFetchAnnouncementsURL = @"fetchAnnouncementsURL";
NSString *const kDefaultScriptureShareURL = @"defaultScriptureShareURL";
NSString *const kHelpURL = @"iosHelpURL";
NSString *const kSubscribeToMailingListURL = @"subscribeToMailingListURL";
NSString *const kCeaselessAboutURL = @"aboutCeaselessAppURL";

+ (id) sharedCeaselessService {
    static CeaselessService *sharedCeaselessService = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCeaselessService = [[self alloc] init];
    });
    return sharedCeaselessService;
}

- (instancetype) init {
    self = [super init];
    if (self) {
        _defaults = [NSUserDefaults standardUserDefaults];
        _defaultUrls = [[NSMutableDictionary alloc] init];
        // TODO move DBP related methods into their own service class.
        [_defaultUrls setValue:@"http://www.bible.is/ENGESV/Matt/21#22" forKey:kDefaultScriptureShareURL];
        [_defaultUrls setValue:@"https://api.ceaselessprayer.com/v1/votd" forKey:kFetchVerseOfTheDayURL];
        [_defaultUrls setValue:@"https://api.ceaselessprayer.com/v1/getScripture" forKey:kFetchScriptureURL];
        [_defaultUrls setValue:@"https://www.ceaselessprayer.com/announcements/feed" forKey:kFetchAnnouncementsURL];
        [_defaultUrls setValue:@"https://api.ceaselessprayer.com/v1/getAScriptureImage" forKey:kFetchNewScriptureImageURL];
        [_defaultUrls setValue:@"https://www.ceaselessprayer.com/ios_help.html" forKey:kHelpURL];
        [_defaultUrls setValue:@"https://www.ceaselessprayer.com/ios_mailing_list.html" forKey:kSubscribeToMailingListURL];
        [_defaultUrls setValue:@"https://www.ceaselessprayer.com/ios_about.html" forKey:kCeaselessAboutURL];
    }
    return self;
}

- (NSString *) getUrlForKey: (NSString*) key {
    NSString *overridenValue = [_defaults objectForKey:key];
    if(!overridenValue) {
        return [_defaultUrls objectForKey: key];
    } else {
        return overridenValue;
    }
}

- (void) setUrlString: (NSString*) url forKey: (NSString*) key {
    // only set it if it is one of the keys managed by this class
    if([[_defaultUrls allKeys] containsObject:key]) {
        [_defaults setObject:url forKey: key];
    }
}

@end
