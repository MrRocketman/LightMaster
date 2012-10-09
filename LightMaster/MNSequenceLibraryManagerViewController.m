//
//  MNSequenceLibraryManagerViewController.m
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNSequenceLibraryManagerViewController.h"
#import "MNData.h"
#import "MNSequenceControlBoxSelectorViewController.h"
#import "MNSequenceChannelGroupSelectorViewController.h"
#import "MNSequenceCommandClusterSelectorViewController.h"
#import "MNSequenceEffectClusterSelectorViewController.h"
#import "MNSequenceAudioClipViewController.h"


@interface MNSequenceLibraryManagerViewController ()

- (void)addControlBoxFilePathToSequence:(NSNotification *)aNotification;
- (void)addChannelGroupFilePathToSequence:(NSNotification *)aNotification;

@end


@implementation MNSequenceLibraryManagerViewController

@synthesize sequence;

@synthesize
descriptionTextField,
startTimeTextField,
endTimeTextField;

@synthesize
sequenceControlBoxSelectorViewController,
sequenceControlBoxSelectorPopover,
controlBoxesTableView,
deleteControlBoxFromSequenceButton,
addControlBoxToSequenceButton;

@synthesize
sequenceChannelGroupSelectorViewController,
sequenceChannelGroupSelectorPopover,
channelGroupsTableView,
deleteChannleGroupFromSequenceButton,
addChannelGroupToSequenceButton;

@synthesize
commandClustersTableView,
deleteCommandClusterFromSequenceButton,
addCommandClusterToSequenceButton;

@synthesize
effectClustersTableView,
deleteEffectClusterFromSequenceButton,
addEffectClusterToSequenceButton;

@synthesize 
audioClipsTableView,
deleteAudioClipFromSequenceButton,
addAudioClipToSequenceButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Initialization code here.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addControlBoxFilePathToSequence:) name:@"AddControlBoxFilePathToSequence" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addChannelGroupFilePathToSequence:) name:@"AddChannelGroupFilePathToSequence" object:nil];
    }
    
    return self;
}

- (void)updateContent
{
    if(sequence != nil)
    {
        [descriptionTextField setEnabled:YES];
        [startTimeTextField setEnabled:YES];
        [endTimeTextField setEnabled:YES];
        
        [addControlBoxToSequenceButton setEnabled:YES];
        [addChannelGroupToSequenceButton setEnabled:YES];
        [addCommandClusterToSequenceButton setEnabled:YES];
        [addEffectClusterToSequenceButton setEnabled:YES];
        [addAudioClipToSequenceButton setEnabled:YES];
        
        [descriptionTextField setStringValue:[data descriptionForSequence:sequence]];
        [startTimeTextField setFloatValue:[data startTimeForSequence:sequence]];
        [endTimeTextField setFloatValue:[data endTimeForSequence:sequence]];
    }
    else
    {
        [descriptionTextField setEnabled:NO];
        [startTimeTextField setEnabled:NO];
        [endTimeTextField setEnabled:NO];
        
        [addControlBoxToSequenceButton setEnabled:NO];
        [addChannelGroupToSequenceButton setEnabled:NO];
        [addCommandClusterToSequenceButton setEnabled:NO];
        [addEffectClusterToSequenceButton setEnabled:NO];
        [addAudioClipToSequenceButton setEnabled:NO];
    }
}

#pragma mark - Notifications

- (void)addControlBoxFilePathToSequence:(NSNotification *)aNotification
{
    [sequenceControlBoxSelectorPopover performClose:nil];
    [data addControlBoxFilePath:[aNotification object] forSequence:sequence];
    [controlBoxesTableView reloadData];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (void)addChannelGroupFilePathToSequence:(NSNotification *)aNotification
{
    [sequenceChannelGroupSelectorPopover performClose:nil];
    [data addChannelGroupFilePath:[aNotification object] forSequence:sequence];
    [channelGroupsTableView reloadData];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

#pragma mark - Button Actions

- (IBAction)deleteControlBoxFromSequenceButtonPress:(id)sender
{
    [data removeControlBoxFilePath:[data controlBoxFilePathAtIndex:(int)[controlBoxesTableView selectedRow]] forSequence:sequence];
    [controlBoxesTableView reloadData];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (IBAction)addControlBoxToSequenceButtonPress:(id)sender
{
    [sequenceControlBoxSelectorPopover showRelativeToRect:[controlBoxesTableView rectOfRow:[controlBoxesTableView selectedRow]] ofView:controlBoxesTableView preferredEdge:NSMaxYEdge];
    if([controlBoxesTableView selectedRow] > -1)
    {
        [sequenceControlBoxSelectorViewController setSelectedControlBoxFilePath:[data controlBoxFilePathAtIndex:(int)[controlBoxesTableView selectedRow] forSequence:sequence]];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (IBAction)deleteChannelGroupFromSequenceButtonPress:(id)sender
{
    [data removeChannelGroupFilePath:[data channelGroupFilePathAtIndex:(int)[channelGroupsTableView selectedRow]] forSequence:sequence];
    [channelGroupsTableView reloadData];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (IBAction)addChannelGroupToSequenceButtonPress:(id)sender
{
    [sequenceChannelGroupSelectorPopover showRelativeToRect:[channelGroupsTableView rectOfRow:[channelGroupsTableView selectedRow]] ofView:channelGroupsTableView preferredEdge:NSMaxYEdge];
    if([channelGroupsTableView selectedRow] > -1)
    {
        [sequenceChannelGroupSelectorViewController setSelectedChannelGroupFilePath:[data channelGroupFilePathAtIndex:(int)[channelGroupsTableView selectedRow] forSequence:sequence]];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (IBAction)deleteCommandClusterFromSequenceButtonPress:(id)sender
{
    [data removeCommandClusterFilePath:[data commandClusterFilePathAtIndex:(int)[commandClustersTableView selectedRow]] forSequence:sequence];
    [commandClustersTableView reloadData];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (IBAction)addCommandClusterToSequenceButtonPress:(id)sender
{
    
}

- (IBAction)deleteEffectClusterFromSequenceButtonPress:(id)sender
{
    [data removeEffectClusterFilePath:[data effectClusterFilePathAtIndex:(int)[effectClustersTableView selectedRow]] forSequence:sequence];
    [effectClustersTableView reloadData];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (IBAction)addEffectClusterToSequenceButtonPress:(id)sender
{
    
}

- (IBAction)deleteAudioClipFromSequenceButtonPress:(id)sender
{
    [data removeAudioClipFilePath:[data audioClipFilePathAtIndex:(int)[audioClipsTableView selectedRow]] forSequence:sequence];
    [audioClipsTableView reloadData];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (IBAction)addAudioClipToSequenceButtonPress:(id)sender
{
    
}

#pragma mark - NSTableViewDataSource Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if(aTableView == controlBoxesTableView)
    {
        return [data controlBoxFilePathsCountForSequence:sequence];
    }
    else if(aTableView == channelGroupsTableView)
    {
        return [data channelGroupFilePathsCountForSequence:sequence];
    }
    else if(aTableView == commandClustersTableView)
    {
        return [data commandClusterFilePathsCountForSequence:sequence];
    }
    else if(aTableView == effectClustersTableView)
    {
        return [data effectClusterFilePathsCountForSequence:sequence];
    }
    else if(aTableView == audioClipsTableView)
    {
        return [data audioClipFilePathsCountForSequence:sequence];
    }
    
    return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if(aTableView == controlBoxesTableView)
    {
        return [data descriptionForControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathAtIndex:(int)rowIndex forSequence:sequence]]];
    }
    else if(aTableView == channelGroupsTableView)
    {
        return [data descriptionForChannelGroup:[data channelGroupFromFilePath:[data channelGroupFilePathAtIndex:(int)rowIndex forSequence:sequence]]];
    }
    else if(aTableView == commandClustersTableView)
    {
        return [data descriptionForCommandCluster:[data commandClusterFromFilePath:[data commandClusterFilePathAtIndex:(int)rowIndex forSequence:sequence]]];
    }
    else if(aTableView == effectClustersTableView)
    {
        return [data descriptionForEffectCluster:[data effectClusterFromFilePath:[data effectClusterFilePathAtIndex:(int)rowIndex forSequence:sequence]]];
    }
    else if(aTableView == audioClipsTableView)
    {
        return [data descriptionForAudioClip:[data audioClipFromFilePath:[data audioClipFilePathAtIndex:(int)rowIndex forSequence:sequence]]];
    }
    
    return @"nil";
}

#pragma mark - NSTableViewDelegate Methods

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if([controlBoxesTableView selectedRow] > -1)
    {
        [deleteControlBoxFromSequenceButton setEnabled:YES];
    }
    else
    {
        [deleteControlBoxFromSequenceButton setEnabled:NO];
    }
    
    if([channelGroupsTableView selectedRow] > -1)
    {
        [deleteChannleGroupFromSequenceButton setEnabled:YES];
    }
    else
    {
        [deleteChannleGroupFromSequenceButton setEnabled:NO];
    }
    
    if([commandClustersTableView selectedRow] > -1)
    {
        [deleteCommandClusterFromSequenceButton setEnabled:YES];
    }
    else
    {
        [deleteCommandClusterFromSequenceButton setEnabled:NO];
    }
    
    if([effectClustersTableView selectedRow] > -1)
    {
        [deleteEffectClusterFromSequenceButton setEnabled:YES];
    }
    else
    {
        [deleteEffectClusterFromSequenceButton setEnabled:NO];
    }
    
    if([audioClipsTableView selectedRow] > -1)
    {
        [deleteAudioClipFromSequenceButton setEnabled:YES];
    }
    else
    {
        [deleteAudioClipFromSequenceButton setEnabled:NO];
    }
}

@end
