//
//  MNControlBoxChannelSelectorViewController.m
//  LightMaster
//
//  Created by James Adams on 10/9/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNControlBoxChannelSelectorViewController.h"

@interface MNControlBoxChannelSelectorViewController ()

- (NSMutableDictionary *)selectedControlBox;

@end

@implementation MNControlBoxChannelSelectorViewController

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

- (void)setSelectedControlBoxIndex:(int)controlBox andChannelIndex:(int)channel
{
    [controlBoxTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:controlBox] byExtendingSelection:NO];
    [channelTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:channel] byExtendingSelection:NO];
    [self reload];
}

- (IBAction)chooseButtonPress:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AddItemDataToSelectedChannelGroup" object:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithInt:(int)[channelTableView selectedRow]], [NSNumber numberWithInt:(int)[controlBoxTableView selectedRow]], nil] forKeys:[NSArray arrayWithObjects:@"ChannelIndex", @"ControlBoxIndex", nil]] userInfo:nil];
}

- (void)reload
{
    [controlBoxTableView reloadData];
    [channelTableView reloadData];
    [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:controlBoxTableView]];
}

#pragma mark - NSTableViewDataSource Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if(aTableView == controlBoxTableView)
    {
        return [data controlBoxFilePathsCount];
    }
    else if(aTableView == channelTableView)
    {
        if((int)[controlBoxTableView selectedRow] > -1)
        {
            return [data channelsCountForControlBox:[self selectedControlBox]];
        }
    }
    
    return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if(aTableView == channelTableView)
    {
        if([[aTableColumn identifier] isEqualToString:@"Number"])
        {
            NSNumber *numberForChannel = [data numberForChannel:[data channelAtIndex:(int)rowIndex forControlBox:[self selectedControlBox]]];
            return [NSNumber numberWithInt:[numberForChannel intValue]];
        }
        else if([[aTableColumn identifier] isEqualToString:@"Color"])
        {
            return [data colorForChannel:[data channelAtIndex:(int)rowIndex forControlBox:[self selectedControlBox]]];
        }
        else if([[aTableColumn identifier] isEqualToString:@"Description"])
        {
            return [data descriptionForChannel:[data channelAtIndex:(int)rowIndex forControlBox:[self selectedControlBox]]];
        }
    }
    else if(aTableView == controlBoxTableView)
    {
        return [data descriptionForControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathAtIndex:(int)rowIndex]]];
    }
    
    return @"nil";
}

#pragma mark - NSTableViewDelegate Methods

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    //NSLog(@"tableView selected:%d", (int)[tableView selectedRow]);
    if([notification object] == controlBoxTableView)
    {
        [channelTableView reloadData];
    }
    else if([notification object] == channelTableView)
    {
        if([channelTableView selectedRow] > -1)
        {
            [chooseButton setEnabled:YES];
        }
        else
        {
            [chooseButton setEnabled:NO];
        }
    }
}

@end
