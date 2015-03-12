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
NSString *const kVerseOfTheDayURL = @"http://test.ceaselessprayer.com/api/votd";
NSString *const kGetScriptureURL = @"http://test.ceaselessprayer.com/api/getScripture";
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
- (void) verseOfTheDay {


	// if it is a new day, remove the top of the queue



}
- (void) manageScriptureQueue {

	AppDelegate *appDelegate = (id) [[UIApplication sharedApplication] delegate];
	self.managedObjectContext = appDelegate.managedObjectContext;

	NSInteger totalCount = [self countObjectsInCoreData];
	NSInteger presentedCount = [self.fetchedObjects count];
	NSInteger unusedCount = totalCount - presentedCount;
		//this method returns the self.fetchedObjects array
	[self getScriptureWithPredicate: @"lastPresentedDate != nil"];

	while (unusedCount < kDefaultQueueMaxSize) {
		[self requestDailyVerseReference];
		unusedCount++;
	}

	while (totalCount > 1 && presentedCount > 0) {
		NSError * error = nil;
		[self.managedObjectContext deleteObject: self.fetchedObjects [presentedCount - 1]];

		if (![self.managedObjectContext save:&error]) {
			NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
		}
		totalCount--;
		presentedCount--;
	}
}

- (ScriptureQueue *)popScriptureQueue
{
	AppDelegate *appDelegate = (id) [[UIApplication sharedApplication] delegate];
	self.managedObjectContext = appDelegate.managedObjectContext;

		//containsScriptureWithPredicate returns self.fetchedObjects
		//get usused scripture
	[self getScriptureWithPredicate: @"lastPresentedDate == nil"];
	if ([self.fetchedObjects count] < 1) {
			//get a previously used scripture
		[self getScriptureWithPredicate: @"lastPresentedDate != nil"];
		if ([self.fetchedObjects count] < 1) {
				//there aren't any previously used or unused scripture, so seed with a default scripture
				// Initialize with a default scripture
				[self seedDefaultScripture];
				// now get the seeded scripture in self.fetchedObjects
				[self getScriptureWithPredicate: @"lastPresentedDate == nil"];
		}
	}
//	for (ScriptureQueue *sq in self.fetchedObjects) {
//		NSLog(@"verse: %@", sq.verse);
//		NSLog(@"citation: %@", sq.citation);
//	}

	if ([self.fetchedObjects count] > 0) {
		// set the last Presented Date on the scripture we will use
		NSError * error = nil;
		[[self.fetchedObjects objectAtIndex:0] setValue: [NSDate date] forKey: @"lastPresentedDate"];

		if (![self.managedObjectContext save: &error]) {
			NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
		}
	} else {
		NSLog (@"What happened to the seeded default");
	}

		//return the selected scripture object
	return [self.fetchedObjects objectAtIndex:0];

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

	if (!dailyVerseData)
		{
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
				  if (![self.managedObjectContext save: &error]) {
					  NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
				  }

			  });
		  }
		  }
	  }];
	[dataTask resume];
}

- (void) getScriptureWithPredicate: (NSString *) predicateArgument {

	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"ScriptureQueue"
											  inManagedObjectContext:self.managedObjectContext];
	[fetchRequest setEntity:entity];
	NSError * error = nil;

	NSPredicate *pred = [NSPredicate predicateWithFormat:predicateArgument];

	[fetchRequest setPredicate:pred];

	self.fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
}
- (void) seedDefaultScripture {

	NSError *error = nil;
	NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:@"ScriptureQueue" inManagedObjectContext:self.managedObjectContext];
	[newManagedObject setValue: kDefaultScripture forKey: @"verse"];
	[newManagedObject setValue: kDefaultCitation forKey: @"citation"];
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
