//
//  SequenceGroupSelectorViewController.m
//  LightMaster
//
//  Created by James Adams on 12/23/11.
//  Copyright (c) 2011 Pencil Busters, Inc. All rights reserved.
//

#import "SequenceGroupSelectorViewController.h"

@implementation SequenceGroupSelectorViewController

@synthesize data;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
    {
        // Custom initialization code here
    }
    
    return self;
}

- (IBAction)addButtonPress:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AddGroupFilePathToSequence" object:[data groupFilePathAtIndex:(int)[tableView selectedRow]] userInfo:nil];
}

- (IBAction)addCopyButtonPress:(id)sender
{
    NSString *newGroupFilePath = [data createCopyOfGroupAndReturnFilePath:[data groupFromFilePath:[data groupFilePathAtIndex:(int)[tableView selectedRow]]]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AddGroupFilePathToSequence" object:newGroupFilePath userInfo:nil];
}

- (void)reload
{
    [tableView reloadData];
    [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:tableView]];
}

- (void)setSelectedGroupFilePath:(NSString *)selectedGroupFilePath
{
    int index = (int)[[data groupFilePaths] indexOfObject:selectedGroupFilePath];
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    [self reload];
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
        int beingUsedCount = [data groupBeingUsedInSequenceFilePathsCount:[data groupFromFilePath:[data groupFilePathAtIndex:(int)[tableView selectedRow]]]];
        if(beingUsedCount == 0)
        {
            [addButton setEnabled:YES];
            [beingUsedLabel setStringValue:@""];
        }
        else if(beingUsedCount == 1)
        {
            [beingUsedLabel setStringValue:[NSString stringWithFormat:@"Being Used in %d Sequence", beingUsedCount]];
            [addButton setEnabled:NO];
        }
        else if(beingUsedCount > 1)
        {
            [beingUsedLabel setStringValue:[NSString stringWithFormat:@"Being Used in %d Sequences", beingUsedCount]];
            [addButton setEnabled:NO];
        }
        
        [addCopyButton setEnabled:YES];
    }
    else
    {
        [beingUsedLabel setStringValue:@""];
        [addButton setEnabled:NO];
        [addCopyButton setEnabled:NO];
    }
}

@end
