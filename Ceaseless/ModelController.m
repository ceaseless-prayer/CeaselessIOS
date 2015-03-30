//
//  ModelController.m
//  Ceaseless
//
//  Created by Christopher Lim on 3/2/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "ModelController.h"
#import "DataViewController.h"
#import "PersonPicker.h"
#import "PeopleQueue.h"
#import "NonMOPerson.h"
#import "AppDelegate.h"
#import "ScripturePicker.h"
#import "ScriptureQueue.h"
#import "ScriptureViewController.h"
#import "PersonViewController.h"
#import "WebCardViewController.h"
#import "CeaselessLocalContacts.h"
#import "AppConstants.h"

/*
 A controller object that manages a simple model -- a collection of month names.
 
 The controller serves as the data source for the page view controller; it therefore implements pageViewController:viewControllerBeforeViewController: and pageViewController:viewControllerAfterViewController:.
 It also implements a custom method, viewControllerAtIndex: which is useful in the implementation of the data source methods, and in the initial configuration of the application.
 
 There is no need to actually create view controllers for each page in advance -- indeed doing so incurs unnecessary overhead. Given the data model, these methods create, configure, and return a new view controller on demand.
 */


@interface ModelController ()

@property (readonly, strong, nonatomic) NSArray *people;
@property (readonly, strong, nonatomic) ScriptureQueue *scripture;
@property (strong, nonatomic) NSMutableArray *cardArray;
@property (nonatomic) NSInteger index;

@end

@implementation ModelController
NSString *const kModelRefreshNotification = @"ceaselessModelRefreshed";
NSString *const kLocalLastRefreshDate = @"localLastRefreshDate";
NSString *const kAnnouncementsUrl = @"http://www.ceaselessprayer.com/announcements/feed";
NSString *const kLastAnnouncementDate = @"localLastAnnouncementDate";

// this method sets up the card array for display
// everything here should be read only
// changing the contents of the array happens through other processes.
- (void) prepareCardArray {
    // set local members to point to app delegate
    ScripturePicker *scripturePicker = [[ScripturePicker alloc] init];
    PersonPicker *personPicker = [[PersonPicker alloc] init];
    CeaselessLocalContacts *ceaselessContacts = [CeaselessLocalContacts sharedCeaselessLocalContacts];
    _index = 0;
    _scripture = [scripturePicker peekScriptureQueue];
    _people = [personPicker queuedPeople];
    
    // convert selected people into form the view can use
    NSMutableArray *nonMOPeople = [[NSMutableArray alloc]init];
    for(PeopleQueue *pq in _people) {
        [nonMOPeople addObject: [ceaselessContacts getNonMOPersonForCeaselessContact:(Person*)pq.person]];
    }
    
    _cardArray = [[NSMutableArray alloc] initWithArray: nonMOPeople];
    
    if (_scripture) {
        [_cardArray insertObject: _scripture atIndex: 0];
    }
    
    // TODO check the server if new content needs to be shown.
    NSString *announcement = [self getAnnouncements];
    if (announcement) {
        [_cardArray addObject: announcement];
    }
}

#pragma mark - Ceaseless daily digest process
// when the app becomes active, this method is run to update the model
- (void) runIfNewDay {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *lastRefreshDate = [defaults objectForKey:kLocalLastRefreshDate];
    NSDate *now = [NSDate date];
    CeaselessLocalContacts *ceaselessContacts = [CeaselessLocalContacts sharedCeaselessLocalContacts];
    if (lastRefreshDate == nil) {
        [ceaselessContacts initializeFirstContacts:5];
    }
    
    BOOL developerMode = [defaults boolForKey:kDeveloperMode];
    
    // we consider it a new day if:
    // developer mode is enabled (that way the application refreshes each time it is newly opened)
    // there is no refresh date
    // there is at least 1 midnight since the last date
    if(developerMode || lastRefreshDate == nil || [self daysWithinEraFromDate: lastRefreshDate toDate: now] > 0) {
        if(developerMode) {
            NSLog(@"Debug Mode enabled: refreshing application every time it is newly opened.");
        }
        
        // Update the last refresh date
        [defaults setObject:now forKey:kLocalLastRefreshDate];
        [defaults synchronize];
        NSLog(@"It's a new day!");
        
        ScripturePicker *scripturePicker = [[ScripturePicker alloc] init];
        [scripturePicker manageScriptureQueue];
        [scripturePicker popScriptureQueue];
        
        PersonPicker *personPicker = [[PersonPicker alloc] init];
        [personPicker emptyQueue];
        [personPicker pickPeople];
        
        [self prepareCardArray];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kModelRefreshNotification object:nil];
        
        
        [ceaselessContacts ensureCeaselessContactsSynced];
        
        NSLog(@"Ceaseless has been refreshed");
    }

}

// https://developer.apple.com/library/prerelease/ios//documentation/Cocoa/Conceptual/DatesAndTimes/Articles/dtCalendricalCalculations.html#//apple_ref/doc/uid/TP40007836-SW1
// Listing 13. Days between two dates, as the number of midnights between
- (NSInteger) daysWithinEraFromDate:(NSDate *) startDate toDate:(NSDate *) endDate {
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSInteger startDay = [gregorian ordinalityOfUnit:NSCalendarUnitDay
                                              inUnit: NSCalendarUnitEra forDate:startDate];
    NSInteger endDay = [gregorian ordinalityOfUnit:NSCalendarUnitDay
                                            inUnit: NSCalendarUnitEra forDate:endDate];
    return endDay-startDay;
}

- (NSString*) getAnnouncements {
    NSURL *url = [NSURL URLWithString: kAnnouncementsUrl];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *lastAnnouncementDate = [defaults objectForKey:kLastAnnouncementDate];
    NSString *result = nil;
    
    NSURLResponse *response;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:5.0];
    
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPMethod:@"GET"];
    NSError *error;
    // TODO make this async for a better user experience?
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
    NSArray *announcements = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    
    // get last announcement refresh date
    // compare to the date of the announcement in the array
    // TODO define the announcement format more strictly.
    NSDate *latestAnnouncementDate = [NSDate dateWithTimeIntervalSince1970:
                                      [[announcements[0] objectForKey:@"date"] doubleValue]];
    
    BOOL developerMode = [defaults boolForKey:kDeveloperMode];
    if(developerMode || latestAnnouncementDate > lastAnnouncementDate) {
        NSLog(@"Latest %@ Last %@", latestAnnouncementDate, lastAnnouncementDate);
        result = announcements[0][@"content"];
        [defaults setObject:latestAnnouncementDate forKey:kLastAnnouncementDate];
        [defaults synchronize];
        NSLog(@"Latest announcement shown!");
    }

    return result;
}

#pragma mark - RootViewController/PageViewController methods
- (DataViewController *)viewControllerAtIndex:(NSUInteger)index storyboard:(UIStoryboard *)storyboard {
    // Return the data view controller for the given index.
    if (([self.cardArray count] == 0) || (index >= [self.cardArray count])) {
        return nil;
    }

    // Create a new view controller and pass suitable data.
    DataViewController *contentViewController;
    if ([self.cardArray[index] isMemberOfClass:[ScriptureQueue class]]) {
        contentViewController = [[ScriptureViewController alloc] init];
		self.mainStoryboard = storyboard;
    } else if ([self.cardArray[index] isKindOfClass:[NSString class]]) {
        contentViewController = [[WebCardViewController alloc] init];
        contentViewController.mainStoryboard = self.mainStoryboard;
    } else {
        contentViewController = [[PersonViewController alloc] init];
		contentViewController.mainStoryboard = self.mainStoryboard;
    }

    contentViewController.dataObject = self.cardArray[index];
	contentViewController.index = index;
    _index = index;
    
    return contentViewController;
}

- (NSUInteger)indexOfViewController:(DataViewController *)viewController {
    // Return the index of the given data view controller.
    // For simplicity, this implementation uses a static array of model objects and the view controller stores the model object; you can therefore use the model object to identify the index.
    return [self.cardArray indexOfObject:viewController.dataObject];
}

- (void)removeControllerAtIndex:(NSUInteger)index {
    [self.cardArray removeObjectAtIndex:index];
    // TODO, update the index?
    // The way it is happening right now
    // breaks encapsulation--the caller is setting the right index by its logic
    // this is for the page indicator at the bottom
}

- (NSInteger) modelCount {
    return [self.cardArray count];
}

#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = [self indexOfViewController:(DataViewController *)viewController];
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    _index = index;
    return [self viewControllerAtIndex:index storyboard:viewController.storyboard];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = [self indexOfViewController:(DataViewController *)viewController];
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    _index = index;
    if (index == [self.cardArray count]) {
        return nil;
    }
    return [self viewControllerAtIndex:index storyboard:viewController.storyboard];
}

#pragma mark -
#pragma mark Page Indicator

- (NSInteger) presentationCountForPageViewController: (UIPageViewController *) pageViewController
{
    return [self.cardArray count];
}

- (NSInteger) presentationIndexForPageViewController: (UIPageViewController *) pageViewController
{
    return _index;
}

@end
