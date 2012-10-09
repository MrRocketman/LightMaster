//
//  MNSequenceCommandClusterSelectorViewController.m
//  LightMaster
//
//  Created by James Adams on 10/8/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNSequenceCommandClusterSelectorViewController.h"

@interface MNSequenceCommandClusterSelectorViewController ()

@end

@implementation MNSequenceCommandClusterSelectorViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (IBAction)addButtonPress:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AddCommandClusterFilePathToSequence" object:[data commandClusterFilePathAtIndex:(int)[tableView selectedRow]] userInfo:nil];
}

- (IBAction)addCopyButtonPress:(id)sender
{
    NSString *newCommandClusterFilePath = [data createCopyOfCommandClusterAndReturnFilePath:[data commandClusterFromFilePath:[data commandClusterFilePathAtIndex:(int)[tableView selectedRow]]]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AddCommandClusterFilePathToSequence" object:newCommandClusterFilePath userInfo:nil];
}

- (void)reload
{
    [tableView reloadData];
    [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:tableView]];
}

- (void)setSelectedCommandClusterFilePath:(NSString *)selectedCommandClusterFilePath
{
    int index = (int)[[data commandClusterFilePaths] indexOfObject:selectedCommandClusterFilePath];
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    [self reload];
}

#pragma mark - NSTableViewDataSource Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [data commandClusterFilePathsCount];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return [data descriptionForCommandCluster:[data commandClusterFromFilePath:[data commandClusterFilePathAtIndex:(int)rowIndex]]];
}

#pragma mark - NSTableViewDelegate Methods

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    //NSLog(@"tableView selected:%d", (int)[tableView selectedRow]);
    
    if([tableView selectedRow] > -1)
    {
        int beingUsedCount = [data commandClusterBeingUsedInSequenceFilePathsCount:[data commandClusterFromFilePath:[data commandClusterFilePathAtIndex:(int)[tableView selectedRow]]]];
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