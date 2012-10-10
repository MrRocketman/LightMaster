//
//  MNCommandClusterChannelGroupSelectorViewController.m
//  LightMaster
//
//  Created by James Adams on 10/10/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNCommandClusterChannelGroupSelectorViewController.h"
#import "MNData.h"

@interface MNCommandClusterChannelGroupSelectorViewController ()

- (NSMutableDictionary *)selectedChannelGroup;

@end

@implementation MNCommandClusterChannelGroupSelectorViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (NSMutableDictionary *)selectedChannelGroup
{
    if((int)[channelGroupTableView selectedRow] > -1)
    {
        return [data channelGroupFromFilePath:[data channelGroupFilePathAtIndex:(int)[channelGroupTableView selectedRow]]];
    }
    
    return nil;
}

- (void)setChannelGroupIndex:(int)index
{
    [channelGroupTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    [self reload];
}

- (IBAction)chooseButtonPress:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectChannelGroupForCommandCluster" object:[data channelGroupFilePathAtIndex:(int)[channelGroupTableView selectedRow]] userInfo:nil];
}

- (void)reload
{
    [channelGroupTableView reloadData];
    [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:channelGroupTableView]];
}

#pragma mark - NSTableViewDataSource Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [data channelGroupFilePathsCount];
    
    return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return [data descriptionForChannelGroup:[data channelGroupFromFilePath:[data channelGroupFilePathAtIndex:(int)rowIndex]]];
}

#pragma mark - NSTableViewDelegate Methods

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    //NSLog(@"tableView selected:%d", (int)[tableView selectedRow]);
    if([channelGroupTableView selectedRow] > -1)
    {
        [chooseButton setEnabled:YES];
    }
    else
    {
        [chooseButton setEnabled:NO];
    }
}

@end
