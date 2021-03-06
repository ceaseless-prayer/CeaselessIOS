	//
	//  ScripturePicker.m
	//  Ceaseless
	//
	//  Created by Lori Hill on 3/5/15.
	//  Copyright (c) 2015 Lori Hill. All rights reserved.
	//

#import "ScripturePicker.h"
#import "AppDelegate.h"
#import "CeaselessService.h"

@interface ScripturePicker ()

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end

@implementation ScripturePicker
NSString *const kDefaultScripture = @"\"And whatever you ask in prayer, you will receive, if you have faith.\"";
NSString *const kDefaultCitation = @"(Matthew 21:22,ESV)";
int const kDefaultQueueMaxSize = 5;
int const kDefaultQueueMinSize = 1;


- (id)init {
	self = [super init];
	if (self) {
		AppDelegate *appDelegate = (id) [[UIApplication sharedApplication] delegate];
		self.managedObjectContext = appDelegate.managedObjectContext;
	}
	return self;
}

- (instancetype) initWith: (NSManagedObjectContext*) managedObjectContext {
    self = [super init];
    if (self) {
        self.managedObjectContext = managedObjectContext;
    }
    return self;
}

// This method refreshes the Scripture queue.
- (void) manageScriptureQueue {

	NSInteger totalCount = [self countObjectsInCoreData];
	NSArray *presentedScripture = [self getScriptureWithPredicate: @"lastPresentedDate != nil"];
	NSInteger presentedCount = [presentedScripture count];
	NSInteger unusedCount = totalCount - presentedCount;

	while (unusedCount < kDefaultQueueMaxSize) {
		[self requestDailyVerseReference];
		unusedCount++;
	}

	while (totalCount > 1 && presentedCount > 0) {
		NSError * error = nil;
		[self.managedObjectContext deleteObject: presentedScripture [presentedCount - 1]];

		if (![self.managedObjectContext save:&error]) {
			NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
		}
		totalCount--;
		presentedCount--;
	}
}

// gets the most recently presented scripture from the queue
- (ScriptureQueue *) peekScriptureQueue {
    NSSortDescriptor *scripturePresentedDateSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"lastPresentedDate" ascending:NO];
    NSArray *scriptureArray = [[self getScriptureWithPredicate:@"TRUEPREDICATE"]sortedArrayUsingDescriptors:[NSArray arrayWithObject:scripturePresentedDateSortDescriptor]];
    if([scriptureArray count] > 0) {
        return [scriptureArray objectAtIndex:0];
    } else {
        // TODO should this do the initialization logic too?
        return nil;
    }
}

// returns the last scripture from the queue and marks it as presented.
- (ScriptureQueue *)popScriptureQueue {
	NSArray *scriptureArray = [self getScriptureWithPredicate: @"lastPresentedDate == nil"];
	if ([scriptureArray count] < 1) {
			//get a previously used scripture
		scriptureArray = [self getScriptureWithPredicate: @"lastPresentedDate != nil"];
		if ([scriptureArray count] < 1) {
				//there aren't any previously used or unused scripture, so seed with a default scripture
				[self seedDefaultScripture];
				// now get the seeded scripture
				scriptureArray = [self getScriptureWithPredicate: @"lastPresentedDate == nil"];
		}
	}

	if ([scriptureArray count] > 0) {
		// set the last Presented Date on the scripture we will use
		NSError * error = nil;
		[[scriptureArray objectAtIndex:0] setValue: [NSDate date] forKey: @"lastPresentedDate"];

		if (![self.managedObjectContext save: &error]) {
			NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
		}
        //return the selected scripture object
		return [scriptureArray objectAtIndex:0];

	} else {
		return nil;
	}
};

- (void)requestDailyVerseReference {
	NSURL *url = [NSURL URLWithString: [[CeaselessService sharedCeaselessService]getUrlForKey:kFetchVerseOfTheDayURL]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:60.0];
    [NSURLConnection sendAsynchronousRequest:request queue: [NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSLog(@"Response:%@ %@\n", response, connectionError);
        if (connectionError == nil && data != nil) {
            NSDictionary *dailyVerseData = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&connectionError];
            [self requestScriptureText: dailyVerseData];
        }
    }];
}

-(void) requestScriptureText: (NSDictionary *) dailyVerseData {
	NSURL *url = [NSURL URLWithString: [[CeaselessService sharedCeaselessService]getUrlForKey:kFetchScriptureURL]];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
														   cachePolicy:NSURLRequestUseProtocolCachePolicy
													   timeoutInterval:60.0];

	[request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[request addValue:@"application/json" forHTTPHeaderField:@"Accept"];

	[request setHTTPMethod:@"POST"];

	if (!dailyVerseData) {
        //default scripture if there was not a reference
		dailyVerseData = [[NSDictionary alloc] initWithObjectsAndKeys:
						  @"22", @"verse_start",
						  @"21", @"chapter",
						  @"Matt", @"book",
						  @"22", @"verse_end",
						  nil];
    }
    NSMutableDictionary *withLanguage = [dailyVerseData mutableCopy];
    [withLanguage setObject: NSLocalizedString(@"scriptureLanguageCode", nil) forKey: @"language"];
    NSDictionary *jsonData = [NSDictionary dictionaryWithDictionary:withLanguage];
	NSError *error;
	NSData *postData = [NSJSONSerialization dataWithJSONObject:jsonData options:0 error:&error];

	[request setHTTPBody:postData];
    [NSURLConnection sendAsynchronousRequest:request queue: [NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSLog(@"Response:%@ %@\n", response, connectionError);
        
        if (error == nil && data != nil) {
            NSDictionary *verseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&connectionError];
            if (verseDictionary) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSError * error = nil;
                    
                    NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:@"ScriptureQueue" inManagedObjectContext:self.managedObjectContext];
                    [newManagedObject setValue: [verseDictionary objectForKey:@"text"]forKey: @"verse"];
                    [newManagedObject setValue: [verseDictionary objectForKey:@"citation"] forKey: @"citation"];

                    NSString *shareLink = [NSString stringWithFormat:@"%@/%@/%@/%@#%@", @"http://www.bible.is", [verseDictionary objectForKey:@"bible"], jsonData[@"book"], jsonData[@"chapter"], jsonData[@"verse_start"]];
                    
                    [newManagedObject setValue: shareLink forKey: @"shareLink"];
                    if (![self.managedObjectContext save: &error]) {
                        NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
                    }
                    
                });
            }
        }
    }];
}

- (NSArray *) getScriptureWithPredicate: (NSString *) predicateArgument {

	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"ScriptureQueue"
											  inManagedObjectContext:self.managedObjectContext];
	[fetchRequest setEntity:entity];
	NSError * error = nil;

	NSPredicate *pred = [NSPredicate predicateWithFormat:predicateArgument];

	[fetchRequest setPredicate:pred];

	NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];

	return fetchedObjects;
}
- (void) seedDefaultScripture {

	NSError *error = nil;
	NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:@"ScriptureQueue" inManagedObjectContext:self.managedObjectContext];
	[newManagedObject setValue: kDefaultScripture forKey: @"verse"];
	[newManagedObject setValue: kDefaultCitation forKey: @"citation"];
    [newManagedObject setValue: [[CeaselessService sharedCeaselessService] getUrlForKey:kDefaultScriptureShareURL] forKey: @"shareLink"];
	if (![self.managedObjectContext save: &error]) {
		NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
	}
}
- (NSInteger) countObjectsInCoreData {
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ScriptureQueue"];
	fetchRequest.resultType = NSCountResultType;
	NSError *fetchError = nil;
	NSUInteger itemsCount = [self.managedObjectContext countForFetchRequest:fetchRequest error:&fetchError];
	if (itemsCount == NSNotFound) {
		NSLog(@"Fetch error: %@", fetchError);
	}
	return itemsCount;

}
@end
