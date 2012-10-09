//
//  MNSequenceLibraryManagerViewController.m
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNSequenceLibraryManagerViewController.h"
#import "MNData.h"


@interface MNSequenceLibraryManagerViewController ()

@end

@implementation MNSequenceLibraryManagerViewController

@synthesize sequence;

@synthesize
descriptionTextField,
startTimeTextField,
endTimeTextField;

@synthesize
controlBoxesTableView,
deleteControlBoxFromSequenceButton,
addControlBoxToSequenceButton;

@synthesize
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
        
        [descriptionTextField setStringValue:[data descriptionForSequence:sequence]];
        [startTimeTextField setFloatValue:[data startTimeForSequence:sequence]];
        [endTimeTextField setFloatValue:[data endTimeForSequence:sequence]];
    }
    else
    {
        [descriptionTextField setEnabled:NO];
        [startTimeTextField setEnabled:NO];
        [endTimeTextField setEnabled:NO];
    }
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
    
}

- (IBAction)deleteChannelGroupFromSequenceButtonPress:(id)sender
{
    [data removeChannelGroupFilePath:[data channelGroupFilePathAtIndex:(int)[channelGroupsTableView selectedRow]] forSequence:sequence];
    [channelGroupsTableView reloadData];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (IBAction)addChannelGroupToSequenceButtonPress:(id)sender
{
    
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

@end
