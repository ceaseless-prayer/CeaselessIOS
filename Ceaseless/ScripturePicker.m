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

NSString *const kVerseOfTheDayURL = @"http://test.ceaselessprayer.com/api/votd";
NSString *const kGetScriptureURL = @"http://test.ceaselessprayer.com/api/getScripture";
int const kDefaultQueueSize = 5;
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


		// need to get the top of the queue, then delete it.
//	NSError * error = nil;
//	[self.managedObjectContext deleteObject: sq];
//
//	if (![self.managedObjectContext save:&error]) {
//		NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
//	}
}
- (void) fillScriptureQueue {

	AppDelegate *appDelegate = (id) [[UIApplication sharedApplication] delegate];
	self.managedObjectContext = appDelegate.managedObjectContext;

	NSInteger count = [self countObjectsInCoreData];

	while (count < kDefaultQueueSize) {
		[self requestDailyVerseReference];
		count++;
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

- (ScriptureQueue *)popScriptureQueue
{
	ScriptureQueue *sq;
	NSArray *scriptures =[self listQueuedScriptures];
	for (id managedObject in scriptures) {
		sq = managedObject;
		NSLog(@"verse: %@", sq.verse);
		NSLog(@"citation: %@", sq.citation);
	}

	if ([scriptures count] > 0) {
		// return the top of the queue
		sq = [scriptures objectAtIndex:0];
	} else {
		NSLog (@"What happened to the seeded default");
//		sq = [ScriptureQueue alloc]; // TODO test this. this does not work I tested it
//		sq.verse = kDefaultScripture;
//		sq.citation = kDefaultCitation;
	}

	return sq;
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
- (NSArray *) listQueuedScriptures {
	NSError * error = nil;

	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"ScriptureQueue"
											  inManagedObjectContext:self.managedObjectContext];
	[fetchRequest setEntity:entity];

	NSArray *fetchedObjects2 = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
	return fetchedObjects2;
}

@end
