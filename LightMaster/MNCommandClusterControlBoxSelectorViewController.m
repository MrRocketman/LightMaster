//
//  MNCommandClusterControlBoxSelectorViewController.m
//  LightMaster
//
//  Created by James Adams on 10/10/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNCommandClusterControlBoxSelectorViewController.h"
#import "MNData.h"

@interface MNCommandClusterControlBoxSelectorViewController ()

- (NSMutableDictionary *)selectedControlBox;

@end

@implementation MNCommandClusterControlBoxSelectorViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (NSMutableDictionary *)selectedControlBox
{
    if((int)[controlBoxTableView selectedRow] > -1)
    {
        return [data controlBoxFromFilePath:[data controlBoxFilePathAtIndex:(int)[controlBoxTableView selectedRow]]];
    }
    
    return nil;
}

- (void)setControlBoxIndex:(int)index
{
    [controlBoxTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    [self reload];
}

- (IBAction)chooseButtonPress:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectControlBoxForCommandCluster" object:[data controlBoxFilePathAtIndex:(int)[controlBoxTableView selectedRow]] userInfo:nil];
}

- (void)reload
{
    [controlBoxTableView reloadData];
    [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:controlBoxTableView]];
}

#pragma mark - NSTableViewDataSource Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [data controlBoxFilePathsCount];
    
    return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return [data descriptionForControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathAtIndex:(int)rowIndex]]];
}

#pragma mark - NSTableViewDelegate Methods

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    //NSLog(@"tableView selected:%d", (int)[tableView selectedRow]);
    if([controlBoxTableView selectedRow] > -1)
    {
        [chooseButton setEnabled:YES];
    }
    else
    {
        [chooseButton setEnabled:NO];
    }
}

@end
