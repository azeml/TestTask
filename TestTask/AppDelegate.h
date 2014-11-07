//
//  AppDelegate.h
//  TestTask
//
//  Created by Alexander on 05/11/14.
//  Copyright (c) 2014 Alexander. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "Item.h"

#define SQLITE_FILE_NAME		@"TestTask.sqlite"
#define CONTENTS_URL			@"http://sample-json-api.dhampik.ru/items.json"
#define ENTITY_ITEM				@"Item"
#define FETCH_ALL_ITEMS_REQ		@"fetchAllItems"
#define FETCH_CONT_NOTIF		@"FETCH_CONTENTS_NOTIFICATION"
#define FETCH_IMG_NOTIF			@"FETCH_IMAGE_NOTIFICATION"
#define FETCH_FINISHED_NOTIF	@"FETCH_FINISHED_NOTIFICATION"

#define HTTP_RESPONSE_OK	200

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic) BOOL firstLaunch;
@property (atomic) int activeFetchRequestCount;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

+ (AppDelegate *)instance;
- (NSArray *)fetchFromCache;
- (void)fetchContentsFromURL:(NSString *)urlString;
- (void)fetchImageForItem:(Item *)item;

@end

