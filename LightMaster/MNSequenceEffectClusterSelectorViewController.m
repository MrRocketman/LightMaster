//
//  MNSequenceEffectClusterSelectorViewController.m
//  LightMaster
//
//  Created by James Adams on 10/8/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNSequenceEffectClusterSelectorViewController.h"

@interface MNSequenceEffectClusterSelectorViewController ()

@end

@implementation MNSequenceEffectClusterSelectorViewController

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
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AddEffectClusterFilePathToSequence" object:[data effectClusterFilePathAtIndex:(int)[tableView selectedRow]] userInfo:nil];
}

- (IBAction)addCopyButtonPress:(id)sender
{
    NSString *newEffectClusterFilePath = [data createCopyOfEffectClusterAndReturnFilePath:[data effectClusterFromFilePath:[data effectClusterFilePathAtIndex:(int)[tableView selectedRow]]]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AddEffectClusterFilePathToSequence" object:newEffectClusterFilePath userInfo:nil];
}

- (void)reload
{
    [tableView reloadData];
    [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:tableView]];
}

- (void)setSelectedEffectClusterFilePath:(NSString *)selectedEffectClusterFilePath
{
    int index = (int)[[data effectClusterFilePaths] indexOfObject:selectedEffectClusterFilePath];
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    [self reload];
}

#pragma mark - NSTableViewDataSource Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [data effectClusterFilePathsCount];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return [data descriptionForEffectCluster:[data effectClusterFromFilePath:[data effectClusterFilePathAtIndex:(int)rowIndex]]];
}

#pragma mark - NSTableViewDelegate Methods

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    //NSLog(@"tableView selected:%d", (int)[tableView selectedRow]);
    
    if([tableView selectedRow] > -1)
    {
        int beingUsedCount = [data effectClusterBeingUsedInSequenceFilePathsCount:[data effectClusterFromFilePath:[data effectClusterFilePathAtIndex:(int)[tableView selectedRow]]]];
        if(beingUsedCount == 0)
        {
            [addButton setEnabled:YES];
            [beingUsedLabel setStringValue:@"Not Being Used"];
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
