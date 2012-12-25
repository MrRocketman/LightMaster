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
#import "MNSequenceAudioClipSelectorViewController.h"


@interface MNSequenceLibraryManagerViewController ()

- (void)addControlBoxFilePathToSequence:(NSNotification *)aNotification;
- (void)addChannelGroupFilePathToSequence:(NSNotification *)aNotification;
- (void)addCommandClusterFilePathToSequence:(NSNotification *)aNotification;
- (void)addAudioClipFilePathToSequence:(NSNotification *)aNotification;

- (void)setSequenceNotification:(NSNotification *)aNotification;

- (void)textDidEndEditing:(NSNotification *)aNotification;

@end


@implementation MNSequenceLibraryManagerViewController

@synthesize sequence;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Add data items Notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addControlBoxFilePathToSequence:) name:@"AddControlBoxFilePathToSequence" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addChannelGroupFilePathToSequence:) name:@"AddChannelGroupFilePathToSequence" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addCommandClusterFilePathToSequence:) name:@"AddCommandClusterFilePathToSequence" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addAudioClipFilePathToSequence:) name:@"AddAudioClipFilePathToSequence" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setSequenceNotification:) name:@"SetSequence" object:nil];
        
        // Text Editing Notifications
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidBeginEditing:) name:@"NSControlTextDidBeginEditingNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidEndEditing:) name:@"NSControlTextDidEndEditingNotification" object:nil];
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:@"NSControlTextDidChangeNotification" object:nil];
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
        [addAudioClipToSequenceButton setEnabled:YES];
        [autogenSequenceButton setEnabled:YES];
        [autogenIntensitySlider setEnabled:YES];
        [autogenv2SequenceButton setEnabled:YES];
        [autogenv2IntensitySlider setEnabled:YES];
        
        [descriptionTextField setStringValue:[data descriptionForSequence:sequence]];
        [startTimeTextField setStringValue:[NSString stringWithFormat:@"%.3f", [data startTimeForSequence:sequence]]];
        [endTimeTextField setStringValue:[NSString stringWithFormat:@"%.3f", [data endTimeForSequence:sequence]]];
    }
    else
    {
        [descriptionTextField setEnabled:NO];
        [startTimeTextField setEnabled:NO];
        [endTimeTextField setEnabled:NO];
        
        [addControlBoxToSequenceButton setEnabled:NO];
        [deleteControlBoxFromSequenceButton setEnabled:NO];
        [addChannelGroupToSequenceButton setEnabled:NO];
        [deleteChannleGroupFromSequenceButton setEnabled:NO];
        [addCommandClusterToSequenceButton setEnabled:NO];
        [deleteCommandClusterFromSequenceButton setEnabled:NO];
        [addAudioClipToSequenceButton setEnabled:NO];
        [deleteAudioClipFromSequenceButton setEnabled:NO];
        [autogenSequenceButton setEnabled:NO];
        [autogenIntensitySlider setEnabled:NO];
        [autogenv2SequenceButton setEnabled:NO];
        [autogenv2IntensitySlider setEnabled:NO];
        
        [descriptionTextField setStringValue:@""];
        [startTimeTextField setStringValue:@""];
        [endTimeTextField setStringValue:@""];
    }
    
    [controlBoxesTableView reloadData];
    [channelGroupsTableView reloadData];
    [commandClustersTableView reloadData];
    [audioClipsTableView reloadData];
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

- (void)addCommandClusterFilePathToSequence:(NSNotification *)aNotification
{
    [sequenceCommandClusterSelectorPopover performClose:nil];
    [data addCommandClusterFilePath:[aNotification object] forSequence:sequence];
    [commandClustersTableView reloadData];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (void)addAudioClipFilePathToSequence:(NSNotification *)aNotification
{
    [sequenceAudioClipSelectorPopover performClose:nil];
    [data addAudioClipFilePath:[aNotification object] forSequence:sequence];
    [audioClipsTableView reloadData];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (void)setSequenceNotification:(NSNotification *)aNotification
{
    [self setSequence:[aNotification object]];
}

#pragma mark - Button Actions

- (IBAction)deleteControlBoxFromSequenceButtonPress:(id)sender
{
    [data removeControlBoxFilePath:[data controlBoxFilePathAtIndex:(int)[controlBoxesTableView selectedRow] forSequence:sequence] forSequence:sequence];
    [controlBoxesTableView reloadData];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (IBAction)addControlBoxToSequenceButtonPress:(id)sender
{
    [sequenceControlBoxSelectorPopover showRelativeToRect:[controlBoxesTableView rectOfRow:[controlBoxesTableView selectedRow]] ofView:controlBoxesTableView preferredEdge:NSMaxYEdge];
    [sequenceControlBoxSelectorViewController reload];
    if([controlBoxesTableView selectedRow] > -1)
    {
        [sequenceControlBoxSelectorViewController setSelectedControlBoxFilePath:[data controlBoxFilePathAtIndex:(int)[controlBoxesTableView selectedRow] forSequence:sequence]];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (IBAction)deleteChannelGroupFromSequenceButtonPress:(id)sender
{
    [data removeChannelGroupFilePath:[data channelGroupFilePathAtIndex:(int)[channelGroupsTableView selectedRow] forSequence:sequence] forSequence:sequence];
    [channelGroupsTableView reloadData];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (IBAction)addChannelGroupToSequenceButtonPress:(id)sender
{
    [sequenceChannelGroupSelectorPopover showRelativeToRect:[channelGroupsTableView rectOfRow:[channelGroupsTableView selectedRow]] ofView:channelGroupsTableView preferredEdge:NSMaxYEdge];
    [sequenceChannelGroupSelectorViewController reload];
    if([channelGroupsTableView selectedRow] > -1)
    {
        [sequenceChannelGroupSelectorViewController setSelectedChannelGroupFilePath:[data channelGroupFilePathAtIndex:(int)[channelGroupsTableView selectedRow] forSequence:sequence]];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (IBAction)deleteCommandClusterFromSequenceButtonPress:(id)sender
{
    [data removeCommandClusterFilePath:[data commandClusterFilePathAtIndex:(int)[commandClustersTableView selectedRow] forSequence:sequence] forSequence:sequence];
    [commandClustersTableView reloadData];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (IBAction)addCommandClusterToSequenceButtonPress:(id)sender
{
    [sequenceCommandClusterSelectorPopover showRelativeToRect:[commandClustersTableView rectOfRow:[commandClustersTableView selectedRow]] ofView:commandClustersTableView preferredEdge:NSMaxYEdge];
    [sequenceCommandClusterSelectorViewController reload];
    if([commandClustersTableView selectedRow] > -1)
    {
        [sequenceCommandClusterSelectorViewController setSelectedCommandClusterFilePath:[data commandClusterFilePathAtIndex:(int)[commandClustersTableView selectedRow] forSequence:sequence]];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (IBAction)deleteAudioClipFromSequenceButtonPress:(id)sender
{
    [data removeAudioClipFilePath:[data audioClipFilePathAtIndex:(int)[audioClipsTableView selectedRow] forSequence:sequence] forSequence:sequence];
    [audioClipsTableView reloadData];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (IBAction)addAudioClipToSequenceButtonPress:(id)sender
{
    [sequenceAudioClipSelectorPopover showRelativeToRect:[audioClipsTableView rectOfRow:[audioClipsTableView selectedRow]] ofView:audioClipsTableView preferredEdge:NSMaxYEdge];
    [sequenceAudioClipSelectorViewController reload];
    if([audioClipsTableView selectedRow] > -1)
    {
        [sequenceAudioClipSelectorViewController setSelectedAudioClipFilePath:[data audioClipFilePathAtIndex:(int)[audioClipsTableView selectedRow] forSequence:sequence]];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (IBAction)autogenSequenceButtonPress:(id)sender
{
    [data autogenCurrentSequence];
}

- (IBAction)autogenIntensitySliderChange:(id)sender
{
    [data setAutogenIntensity:[autogenIntensitySlider floatValue]];
}

- (IBAction)autogenv2SequenceButtonPress:(id)sender
{
    [data autogenv2ForCurrentSequence];
}

- (IBAction)autogenv2IntensitySliderChange:(id)sender
{
    [data setAutogenv2Intensity:[autogenv2IntensitySlider floatValue]];
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
    
    if([audioClipsTableView selectedRow] > -1)
    {
        [deleteAudioClipFromSequenceButton setEnabled:YES];
    }
    else
    {
        [deleteAudioClipFromSequenceButton setEnabled:NO];
    }
}

#pragma mark - TextEditinig Notifications

/*- (void)textDidBeginEditing:(NSNotification *)aNotification
{
    
}

- (void)textDidChange:(NSNotification *)aNotification
{
    
}*/

- (void)textDidEndEditing:(NSNotification *)aNotification
{
    if([aNotification object] == descriptionTextField)
    {
        [data setDescription:[descriptionTextField stringValue] forSequence:sequence];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLibrariesViewController" object:nil];
    }
    else if([aNotification object] == startTimeTextField)
    {
        [data setStartTime:[startTimeTextField floatValue] forSequence:sequence];
    }
    else if([aNotification object] == endTimeTextField)
    {
        [data setEndTime:[endTimeTextField floatValue] forSequence:sequence];
    }
    
    [self updateContent];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

@end
