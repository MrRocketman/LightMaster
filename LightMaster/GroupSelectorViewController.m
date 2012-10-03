//
//  GroupSelectorViewController.m
//  LightMaster
//
//  Created by James Adams on 12/21/11.
//  Copyright (c) 2011 Pencil Busters, Inc. All rights reserved.
//

#import "GroupSelectorViewController.h"

@implementation GroupSelectorViewController

@synthesize data;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
    {
        // Custom initialization code here
    }
    
    return self;
}

- (IBAction)selectButtonPress:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectGroupFilePath" object:[data groupFilePathAtIndex:(int)[tableView selectedRow]] userInfo:nil];
}

- (void)reload
{
    [tableView reloadData];
    [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:tableView]];
}

#pragma mark - NSTableViewDataSource Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [data groupFilePathsCount];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return [data descriptionForGroup:[data groupFromFilePath:[data groupFilePathAtIndex:(int)rowIndex]]];
}

#pragma mark - NSTableViewDelegate Methods

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    //NSLog(@"tableView selected:%d", (int)[tableView selectedRow]);
    
    if([tableView selectedRow] > -1)
    {
        [selectButton setEnabled:YES];
    }
    else
    {
        [selectButton setEnabled:NO];
    }
}

@end
