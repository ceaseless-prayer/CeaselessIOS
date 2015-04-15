//
//  CeaselessService.h
//  Ceaseless
//
//  Created by Christopher Lim on 4/15/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//
// For now this class will be just serving up URLs
// eventually it may encapsulate access to the underlying service itself

#import <Foundation/Foundation.h>

@interface CeaselessService : NSObject
FOUNDATION_EXPORT NSString *const kFetchNewScriptureImageURL;
FOUNDATION_EXPORT NSString *const kFetchVerseOfTheDayURL;
FOUNDATION_EXPORT NSString *const kFetchScriptureURL;
FOUNDATION_EXPORT NSString *const kFetchAnnouncementsURL;
FOUNDATION_EXPORT NSString *const kDefaultScriptureShareURL;

@property (strong, nonatomic) NSUserDefaults *defaults;
@property (strong, nonatomic) NSMutableDictionary *defaultUrls;

+ (id) sharedCeaselessService;
- (instancetype) init;
- (NSString *) getUrlForKey: (NSString*) key;
- (void) setUrlString: (NSString*) url forKey: (NSString*) key;
@end
