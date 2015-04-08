	//
	//  ScripturePicker.m
	//  Ceaseless
	//
	//  Created by Lori Hill on 3/5/15.
	//  Copyright (c) 2015 Lori Hill. All rights reserved.
	//

#import "ScripturePicker.h"
#import "AppDelegate.h"

@interface ScripturePicker ()

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end

@implementation ScripturePicker
NSString *const kDefaultScripture = @"\"And whatever you ask in prayer, you will receive, if you have faith.\"";
NSString *const kDefaultCitation = @"(Matthew 21:22,ESV)";
NSString *const kDefaultShareLink = @"http://www.bible.is/ENGESV/Matt/21#22";
NSString *const kVerseOfTheDayURL = @"http://api.ceaselessprayer.com/v1/votd";
NSString *const kGetScriptureURL = @"http://api.ceaselessprayer.com/v1/getScripture";
int const kDefaultQueueMaxSize = 5;
int const kDefaultQueueMinSize = 1;
	// verseOfTheDay
	//		if its still the same day return the verse we cached
	//		else pop a scripture off the queue
	//
	// pop a scripture off the queue
	//		get the first scripture on the queue
	//		delete it from the queue
	//		return the scripture
	//

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

- (void)requestDailyVerseReference
{
	NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
	NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];

	NSURL *url = [NSURL URLWithString: kVerseOfTheDayURL];

	NSURLSessionDataTask *urlSessionDataTask = [urlSession dataTaskWithURL:url
														 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
		{
		NSLog(@"Response:%@ %@\n", response, error);
		if (error == nil)
			{
			NSDictionary *dailyVerseData = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
			[self requestScriptureText: dailyVerseData];
			}

		}];

	[urlSessionDataTask resume];
}

-(void) requestScriptureText: (NSDictionary *) dailyVerseData
{

	NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
	NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];

	NSURL *url = [NSURL URLWithString: kGetScriptureURL];

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
	NSDictionary *jsonData = dailyVerseData;
	NSError *error;
	NSData *postData = [NSJSONSerialization dataWithJSONObject:jsonData options:0 error:&error];

	[request setHTTPBody:postData];

	NSURLSessionDataTask * dataTask =[urlSession dataTaskWithRequest:request
												   completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
	  {
	  NSLog(@"Response:%@ %@\n", response, error);

	  if (error == nil)
		  {
		  NSDictionary *verseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
		  if (verseDictionary)
			  {
			  dispatch_async(dispatch_get_main_queue(), ^{
				  NSError * error = nil;

				  NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:@"ScriptureQueue" inManagedObjectContext:self.managedObjectContext];
				  [newManagedObject setValue: [verseDictionary objectForKey:@"text"]forKey: @"verse"];
				  [newManagedObject setValue: [verseDictionary objectForKey:@"citation"] forKey: @"citation"];
                  
                  // TODO configure the right bible for the local language
                  NSString *shareLink = [NSString stringWithFormat:@"%@/%@/%@#%@", @"http://www.bible.is/ENGESV", jsonData[@"book"], jsonData[@"chapter"], jsonData[@"verse_start"]];
                  
                  [newManagedObject setValue: shareLink forKey: @"shareLink"];
				  if (![self.managedObjectContext save: &error]) {
					  NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
				  }

			  });
		  }
		  }
	  }];
	[dataTask resume];
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
    	[newManagedObject setValue: kDefaultShareLink forKey: @"shareLink"];
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
