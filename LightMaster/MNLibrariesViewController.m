//
//  MNLibrariesViewController.m
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNLibrariesViewController.h"
#import "MNSequenceLibraryManagerViewController.h"
#import "MNControlBoxLibraryManagerViewController.h"
#import "MNChannelGroupLibraryManagerViewController.h"
#import "MNCommandClusterLibraryManagerViewController.h"
#import "MNEffectClusterLibraryManagerViewController.h"
#import "MNAudioClipLibraryManagerViewController.h"
#import "MNData.h"

@interface MNLibrariesViewController ()

// External Notifications
- (void)selectCommandCluster:(NSNotification *)aNotification;
- (void)selectCommand:(NSNotification *)aNotification;
- (void)selectAudioClip:(NSNotification *)aNotification;

// Menu Items
- (void)newSequence:(NSNotification *)aNotification;
- (void)newControlBox:(NSNotification *)aNotification;
- (void)newChannelGroup:(NSNotification *)aNotification;
- (void)newAudioClip:(NSNotification *)aNotification;
- (void)newEffectCluster:(NSNotification *)aNotification;
- (void)newCommandCluster:(NSNotification *)aNotification;

- (void)removeLibraryContentView:(int)library;
- (void)addLibraryContentView:(int)library;
- (void)selectLibraryInTabList:(int)library;
- (IBAction)libraryButtonPress:(id)sender;
- (NSButton *)buttonForLibraryIndex:(int)library;
- (NSViewController *)libraryForIndex:(int)library;

@end

@implementation MNLibrariesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // External Notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectCommandCluster:) name:@"SelectCommandCluster" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectCommand:) name:@"SelectCommand" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectAudioClip:) name:@"SelectSound" object:nil];
        
        // Menu Items
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newSequence:) name:@"NewSequence" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newControlBox:) name:@"NewControlBox" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newChannelGroup:) name:@"NewGroup" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newAudioClip:) name:@"NewSound" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newEffectCluster:) name:@"NewEffect" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newCommandCluster:) name:@"NewCommandCluster" object:nil];
    }
    
    return self;
}

- (void)awakeFromNib
{
    // Select the sequences tab in the library
    selectedLibrary = -1;
    [self displayLibrary:kSequenceLibrary];
}

#pragma mark - Library Managment Methods

- (NSButton *)buttonForLibraryIndex:(int)library
{
    if(library == kSequenceLibrary)
        return sequenceLibraryButton;
    else if(library == kControlBoxLibrary)
        return controlBoxLibraryButton;
    else if(library == kChannelGroupLibrary)
        return channelGroupLibraryButton;
    else if(library == kCommandClusterLibrary)
        return commandClusterLibraryButton;
    else if(library == kEffectClusterLibrary)
        return effectClusterLibraryButton;
    else if(library == kAudioClipLibrary)
        return audioClipLibraryButton;
    
    return nil;
}

- (void)selectLibraryInTabList:(int)library
{
    selectedLibrary = library;
    
    // Toggle the buttons on and off
    for(int i = 0; i < NUMBER_OF_LIBRARIES; i ++)
    {
        // Deselect all other libraries
        if(i != library)
        {
            [[self buttonForLibraryIndex:i] setState:NSOffState];
        }
        // Select the library
        else
        {
            [[self buttonForLibraryIndex:i] setState:NSOnState];
        }
    }
    
    [libraryDataSelectionTableView deselectAll:nil];
}

- (IBAction)libraryButtonPress:(id)sender
{
    [self displayLibrary:(int)[sender tag]];
}

- (void)removeLibraryContentView:(int)library
{
    previouslySelectedRowsInLibraryDataSelectionTableView[selectedLibrary] = (int)[libraryDataSelectionTableView selectedRow];
    [[self libraryForIndex:library].view removeFromSuperview];
}

- (void)addLibraryContentView:(int)library
{
    NSViewController *theLibrary = [self libraryForIndex:library];
    
    [libraryContentScrollView.documentView setFrame:theLibrary.view.frame];
    [libraryContentScrollView.documentView addSubview:theLibrary.view];
    [theLibrary.view scrollPoint:NSMakePoint(0, theLibrary.view.frame.size.height)];
    [libraryDataSelectionTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:previouslySelectedRowsInLibraryDataSelectionTableView[library]] byExtendingSelection:NO];
    [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:libraryDataSelectionTableView]];
}

- (NSViewController *)libraryForIndex:(int)library
{
    if(library == kSequenceLibrary)
        return sequenceLibraryManagerViewController;
    else if(library == kControlBoxLibrary)
        return controlBoxLibraryManagerViewController;
    else if(library == kChannelGroupLibrary)
        return channelGroupLibraryManagerViewController;
    else if(library == kCommandClusterLibrary)
        return commandClusterLibraryManagerViewController;
    else if(library == kEffectClusterLibrary)
        return effectClusterLibraryManagerViewController;
    else if(library == kAudioClipLibrary)
        return audioClipLibraryManagerViewController;
    
    return nil;
}

- (void)displayLibrary:(int)library
{
    if(library != selectedLibrary && library != -1)
    {
        // Remove the old content if there is old content
        if(selectedLibrary != -1)
        {
            [self removeLibraryContentView:selectedLibrary];
        }
        
        // Select the new tab
        [self selectLibraryInTabList:library];
        
        // Display the new content
        [self addLibraryContentView:selectedLibrary];
        
        // Reload the library selection table view
        [libraryDataSelectionTableView reloadData];
    }
}

- (IBAction)addLibraryDataButtonPress:(id)sender
{
    
}

- (IBAction)deleteLibraryDataButtonPress:(id)sender
{
    
}

#pragma mark - Notifications

// External Notifications
- (void)selectCommandCluster:(NSNotification *)aNotification
{
    
}

- (void)selectCommand:(NSNotification *)aNotification
{
    
}

- (void)selectAudioClip:(NSNotification *)aNotification
{
    
}

// Menu Items
- (void)newSequence:(NSNotification *)aNotification
{
    
}

- (void)newControlBox:(NSNotification *)aNotification
{
    
}

- (void)newChannelGroup:(NSNotification *)aNotification
{
    
}

- (void)newAudioClip:(NSNotification *)aNotification
{
    
}

- (void)newEffectCluster:(NSNotification *)aNotification
{
    
}

- (void)newCommandCluster:(NSNotification *)aNotification
{
    
}

#pragma mark - NSTableViewDataSource Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    switch (selectedLibrary)
    {
        case kSequenceLibrary:
            return [data sequenceFilePathsCount];
            break;
        case kControlBoxLibrary:
            return [data controlBoxFilePathsCount];
            break;
        case kChannelGroupLibrary:
            return [data channelGroupFilePathsCount];
            break;
        case kCommandClusterLibrary:
            return [data commandClusterFilePathsCount];
            break;
        case kEffectClusterLibrary:
            return [data effectClusterFilePathsCount];
            break;
        case kAudioClipLibrary:
            return [data audioClipFilePathsCount];
            break;
        default:
            break;
    }
    
    return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    switch (selectedLibrary)
    {
        case kSequenceLibrary:
            return [data descriptionForSequence:[data sequenceFromFilePath:[data sequenceFilePathAtIndex:(int)rowIndex]]];
            break;
        case kChannelGroupLibrary:
            return [data descriptionForChannelGroup:[data channelGroupFromFilePath:[data channelGroupFilePathAtIndex:(int)rowIndex]]];
            break;
        case kControlBoxLibrary:
            return [data descriptionForControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathAtIndex:(int)rowIndex]]];
            break;
        case kCommandClusterLibrary:
            return [data descriptionForCommandCluster:[data commandClusterFromFilePath:[data commandClusterFilePathAtIndex:(int)rowIndex]]];
            break;
        case kEffectClusterLibrary:
            return [data descriptionForEffectCluster:[data effectClusterFromFilePath:[data effectClusterFilePathAtIndex:(int)rowIndex]]];
            break;
        case kAudioClipLibrary:
            return [data descriptionForAudioClip:[data audioClipFromFilePath:[data audioClipFilePathAtIndex:(int)rowIndex]]];
            break;
        default:
            break;
    }
    
    return @"nil";
}

#pragma mark - NSTableViewDelegate Methods

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    //NSLog(@"tableView selected:%d", (int)[tableView selectedRow]);
    
    switch(selectedLibrary)
    {
        case kSequenceLibrary:
            [sequenceLibraryManagerViewController setSequence:[data sequenceFromFilePath:[data sequenceFilePathAtIndex:(int)[libraryDataSelectionTableView selectedRow]]]];
            break;
        case kControlBoxLibrary:
            [controlBoxLibraryManagerViewController setControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathAtIndex:(int)[libraryDataSelectionTableView selectedRow]]]];
            break;
        case kChannelGroupLibrary:
            [channelGroupLibraryManagerViewController setChannelGroup:[data channelGroupFromFilePath:[data channelGroupFilePathAtIndex:(int)[libraryDataSelectionTableView selectedRow]]]];
            break;
        case kCommandClusterLibrary:
            [commandClusterLibraryManagerViewController setCommandCluster:[data commandClusterFromFilePath:[data commandClusterFilePathAtIndex:(int)[libraryDataSelectionTableView selectedRow]]]];
            break;
        case kEffectClusterLibrary:
            [effectClusterLibraryManagerViewController setEffectCluster:[data effectClusterFromFilePath:[data effectClusterFilePathAtIndex:(int)[libraryDataSelectionTableView selectedRow]]]];
            break;
        case kAudioClipLibrary:
            [audioClipLibraryManagerViewController setAudioClip:[data audioClipFromFilePath:[data audioClipFilePathAtIndex:(int)[libraryDataSelectionTableView selectedRow]]]];
            break;
        default:
            break;
    }
}

@end
