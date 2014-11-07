//
//  TableViewController.m
//  TestTask
//
//  Created by Alexander on 05/11/14.
//  Copyright (c) 2014 Alexander. All rights reserved.
//

#import "TableViewController.h"
#import "AppDelegate.h"
#import <CoreData/CoreData.h>
#import "Item.h"

@interface TableViewController ()

@end

@implementation TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchContentsNotification:) name:FETCH_CONT_NOTIF object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchImageNotification:) name:FETCH_IMG_NOTIF object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchFinishedNotification:) name:FETCH_FINISHED_NOTIF object:nil];

	if ([AppDelegate instance].firstLaunch) {
		self.navigationItem.rightBarButtonItem.enabled = NO;
		// it's first time the app is launched, fetch from URL
		[[AppDelegate instance] fetchContentsFromURL:CONTENTS_URL];
	} else {
		// check cached data
		allItemsArray = [[AppDelegate instance] fetchFromCache];
	}
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return allItemsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellId = @"itemCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];
	Item *itemEntity = allItemsArray[indexPath.row];
	cell.textLabel.text = itemEntity.name;
	cell.detailTextLabel.text = itemEntity.desc;
	if (itemEntity.imageData) {
		cell.imageView.image = [UIImage imageWithData:itemEntity.imageData];
	} else {
		cell.imageView.image = nil;
	}
    return cell;
}

#pragma mark - Custom methods

- (IBAction)refreshTapped:(id)sender {
	// disable Refresh button untill fetch has finished
	self.navigationItem.rightBarButtonItem.enabled = NO;
	// clean data
	if (allItemsArray.count > 0) {
		NSManagedObjectContext *context = [[AppDelegate instance] managedObjectContext];
		@synchronized ([AppDelegate instance]) {
			for (NSManagedObject *fetchedObj in allItemsArray) {
				[context deleteObject:fetchedObj];
			}
			[[AppDelegate instance] saveContext];
		}
		allItemsArray = nil;
		[self.tableView reloadData];
	}
	// fetch new data
	[[AppDelegate instance] fetchContentsFromURL:CONTENTS_URL];
}

- (void)fetchContentsNotification:(NSNotification*)notification {
	dispatch_sync(dispatch_get_main_queue(), ^{
		if ([notification.object isKindOfClass:[NSArray class]]) {
			allItemsArray = notification.object;
			[self.tableView reloadData];
		}
	});
}

- (void)fetchImageNotification:(NSNotification*)notification {
	Item *itemEntity = notification.object;
	if ([itemEntity isKindOfClass:[Item class]]) {
		NSInteger itemIndex = [allItemsArray indexOfObject:itemEntity];
		if (itemIndex != NSNotFound) {
			NSArray *indexPaths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:itemIndex inSection:0]];
			dispatch_sync(dispatch_get_main_queue(), ^{
				[self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
			});
		} else {
			NSLog(@"item not found");
		}
	}
}

- (void)fetchFinishedNotification:(NSNotification*)notification {
	dispatch_sync(dispatch_get_main_queue(), ^{
		self.navigationItem.rightBarButtonItem.enabled = YES;
	});
}

@end
