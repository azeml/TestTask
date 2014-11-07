//
//  TableViewController.h
//  TestTask
//
//  Created by Alexander on 05/11/14.
//  Copyright (c) 2014 Alexander. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TableViewController : UITableViewController {
	NSArray *allItemsArray;
}

- (IBAction)refreshTapped:(id)sender;

@end
