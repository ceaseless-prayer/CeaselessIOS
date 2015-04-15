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
        [_defaultUrls setValue:@"http://www.bible.is/ENGESV/Matt/21#22" forKey:kDefaultScriptureShareURL];
        [_defaultUrls setValue:@"http://api.ceaselessprayer.com/v1/votd" forKey:kFetchVerseOfTheDayURL];
        [_defaultUrls setValue:@"http://api.ceaselessprayer.com/v1/getScripture" forKey:kFetchScriptureURL];
        [_defaultUrls setValue:@"http://www.ceaselessprayer.com/announcements/feed" forKey:kFetchAnnouncementsURL];
        [_defaultUrls setValue:@"http://api.ceaselessprayer.com/v1/getAScriptureImage" forKey:kFetchNewScriptureImageURL];
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
@end
