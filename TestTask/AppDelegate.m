//
//  AppDelegate.m
//  TestTask
//
//  Created by Alexander on 05/11/14.
//  Copyright (c) 2014 Alexander. All rights reserved.
//

#import "AppDelegate.h"
#import "Item.h"
#import <CFNetwork/CFNetworkErrors.h>

@interface AppDelegate ()

@end


@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:SQLITE_FILE_NAME];
	self.firstLaunch = ![[NSFileManager defaultManager] fileExistsAtPath:storeURL.path];
	self.activeFetchRequestCount = 0;
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	// Saves changes in the application's managed object context before the application terminates.
	[self saveContext];
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize firstLaunch;
@synthesize activeFetchRequestCount;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "company.TestTask" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"TestTask" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:SQLITE_FILE_NAME];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
	_managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			[managedObjectContext reset];
        }
    }
}

#pragma mark - Custom methods

static AppDelegate *appDelegate = nil;

+ (AppDelegate *)instance {
	if (appDelegate == nil) {
		appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	}
	return appDelegate;
}

- (NSArray *)fetchFromCache {
	NSManagedObjectModel *model = self.managedObjectModel;
	NSManagedObjectContext *context = self.managedObjectContext;
	NSFetchRequest *allItemsFetchRequest = [model fetchRequestTemplateForName:FETCH_ALL_ITEMS_REQ];
	NSError *MOCError;
	NSArray *fetchResult = [context executeFetchRequest:allItemsFetchRequest error:&MOCError];
	if (MOCError) {
		NSLog(@"%@", MOCError.localizedDescription);
		return nil;
	} else {
		return fetchResult;
	}
}

- (void)fetchContentsFromURL:(NSString *)urlString {
	NSLog(@"Loading %@", urlString);
	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
	[NSURLConnection sendAsynchronousRequest:urlRequest queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
		NSArray *contentsArray = nil;
		if (error) {
			NSLog(@"Error:%i %@", error.code, error.localizedDescription);
		} else if ([data length] > 0) {
			BOOL isResponseOK = YES;
			NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
			if ([HTTPResponse isKindOfClass:[NSHTTPURLResponse class]]) {
				if (HTTPResponse.statusCode != HTTP_RESPONSE_OK) {
					NSLog(@"response code:%i", HTTPResponse.statusCode);
					isResponseOK = NO;
				}
			}
			if (isResponseOK) {
				NSError *JSONError = nil;
				contentsArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&JSONError];
				if (JSONError) {
					NSLog(@"Parsing error: %@", JSONError.localizedDescription);
				} else if (![contentsArray isKindOfClass:[NSArray class]]) {
					NSLog(@"JSON response is not an array");
				} else {
					NSLog(@"%@", contentsArray);
					
					NSManagedObjectContext *context = self.managedObjectContext;
					@synchronized (self) {
						for (id contentObject in contentsArray) {
							if ([contentObject isKindOfClass:[NSDictionary class]]) {
								Item *itemEntity = [NSEntityDescription insertNewObjectForEntityForName:ENTITY_ITEM inManagedObjectContext:context];
								itemEntity.id = contentObject[@"id"];
								itemEntity.name = contentObject[@"name"];
								itemEntity.desc = contentObject[@"desc"];
								itemEntity.url = contentObject[@"url"];
								itemEntity.imageURL = contentObject[@"image"];
								if (itemEntity.imageURL) {
									// set activeFetchRequestCount to the number of items with 'image' field in order to let UI know when image fetching has finished
									self.activeFetchRequestCount++;
								}
							}
						}
						[self saveContext];
					}
				}
			}
		} else {
			NSLog(@"Empty response");
		}
		NSArray *fetchResult = [self fetchFromCache];
		[[NSNotificationCenter defaultCenter] postNotificationName:FETCH_CONT_NOTIF object:fetchResult];
		if (self.activeFetchRequestCount == 0) {
			[[NSNotificationCenter defaultCenter] postNotificationName:FETCH_FINISHED_NOTIF object:nil];
		} else {
			// start fetching images here, IU has been populated with items as a result of posting FETCH_CONT_NOTIF
			for (Item *itemEntity in fetchResult) {
				if (itemEntity.imageURL) {
					[self fetchImageForItem:itemEntity];
				}
			}
		}
	}];
}

- (void)fetchImageForItem:(Item *)item {
	NSLog(@"Loading %@", item.imageURL);
	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:item.imageURL]];
	[NSURLConnection sendAsynchronousRequest:urlRequest queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
		if (error) {
			NSLog(@"Error:%i %@", error.code, error.localizedDescription);
		} else if ([data length] > 0) {
			BOOL isResponseOK = YES;
			NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
			if ([HTTPResponse isKindOfClass:[NSHTTPURLResponse class]]) {
				if (HTTPResponse.statusCode != HTTP_RESPONSE_OK) {
					NSLog(@"response code for '%@':%i", item.name, HTTPResponse.statusCode);
					isResponseOK = NO;
				}
			}
			if (isResponseOK) {
				NSLog(@"loaded image for:'%@' size:%i", item.name, data.length);
				@synchronized (self) {
					item.imageData = data;
					//[self saveContext];
					[[NSNotificationCenter defaultCenter] postNotificationName:FETCH_IMG_NOTIF object:item];
				}
			}
		} else {
			NSLog(@"Empty response");
		}
		self.activeFetchRequestCount--;
		if (self.activeFetchRequestCount == 0) {
			@synchronized (self) {
				[self saveContext];
			}
			[[NSNotificationCenter defaultCenter] postNotificationName:FETCH_FINISHED_NOTIF object:nil];
		}
	}];
}

@end
