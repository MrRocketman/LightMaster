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
#import "MNEffectLibraryManagerViewController.h"
#import "MNAudioClipLibraryManagerViewController.h"
#import "MNData.h"

@interface MNLibrariesViewController ()

// External Notifications
- (void)selectControlBox:(NSNotification *)aNotification;
- (void)selectChannelGroup:(NSNotification *)aNotification;
- (void)selectCommandCluster:(NSNotification *)aNotification;
- (void)selectCommand:(NSNotification *)aNotification;
- (void)selectAudioClip:(NSNotification *)aNotification;
- (void)updateTableView:(NSNotification *)aNotification;
- (void)updateLibraryContent:(NSNotification *)aNotification;

// Menu Items
- (void)newSequence:(NSNotification *)aNotification;
- (void)newControlBox:(NSNotification *)aNotification;
- (void)newChannelGroup:(NSNotification *)aNotification;
- (void)newCommandCluster:(NSNotification *)aNotification;
- (void)newEffect:(NSNotification *)aNotification;
- (void)newAudioClip:(NSNotification *)aNotification;

- (void)removeLibraryContentView:(int)library;
- (void)addLibraryContentView:(int)library;
- (void)selectLibraryInTabList:(int)library;
- (IBAction)libraryButtonPress:(id)sender;

- (void)exportDataToFilePath:(NSString *)filePath;
- (void)importDataFromFilePath:(NSString *)filePath;

@end

@implementation MNLibrariesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // External Notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectControlBox:) name:@"SelectControlBox" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectChannelGroup:) name:@"SelectChannelGroup" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectCommandCluster:) name:@"SelectCommandCluster" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectCommand:) name:@"SelectCommand" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectAudioClip:) name:@"SelectAudioClip" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTableView:) name:@"UpdateLibrariesViewController" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLibraryContent:) name:@"UpdateLibraryContent" object:nil];
        
        // Menu Items
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newSequence:) name:@"NewSequence" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newControlBox:) name:@"NewControlBox" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newChannelGroup:) name:@"NewChannelGroup" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newCommandCluster:) name:@"NewCommandCluster" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newEffect:) name:@"NewEffect" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newAudioClip:) name:@"NewAudioClip" object:nil];
        
        for(int i = 0; i < NUMBER_OF_LIBRARIES; i ++)
        {
            previouslySelectedRowsInLibraryDataSelectionTableView[i] = -1;
        }
    }
    
    return self;
}

- (void)awakeFromNib
{
    tabBarButtons = [NSArray arrayWithObjects:sequenceLibraryButton, controlBoxLibraryButton, channelGroupLibraryButton, commandClusterLibraryButton, effectLibraryButton, audioClipLibraryButton, nil];
    libraries = [NSArray arrayWithObjects:sequenceLibraryManagerViewController, controlBoxLibraryManagerViewController, channelGroupLibraryManagerViewController, commandClusterLibraryManagerViewController, effectLibraryManagerViewController, audioClipLibraryManagerViewController, nil];
    
    // Select the sequences tab in the library
    selectedLibrary = -1;
    [self displayLibrary:kSequenceLibrary];
}

#pragma mark - Library Managment Methods

- (void)selectLibraryInTabList:(int)library
{
    selectedLibrary = library;
    
    // Toggle the buttons on and off
    for(int i = 0; i < NUMBER_OF_LIBRARIES; i ++)
    {
        // Deselect all other libraries
        if(i != library)
        {
            [[tabBarButtons objectAtIndex:i] setState:NSOffState];
        }
        // Select the library
        else
        {
            [[tabBarButtons objectAtIndex:i] setState:NSOnState];
        }
    }
    
    if(library == kSequenceLibrary)
    {
        [playPlaylistButton setHidden:NO];
    }
    else
    {
        [playPlaylistButton setHidden:YES];
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
    [[(NSViewController *)[libraries objectAtIndex:library] view] removeFromSuperview];
}

- (void)addLibraryContentView:(int)library
{
    NSViewController *theLibrary = (NSViewController *)[libraries objectAtIndex:library];
    
    [libraryContentScrollView.documentView setFrame:theLibrary.view.frame];
    [libraryContentScrollView.documentView addSubview:theLibrary.view];
    [theLibrary.view scrollPoint:NSMakePoint(0, theLibrary.view.frame.size.height)];
    [libraryDataSelectionTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:previouslySelectedRowsInLibraryDataSelectionTableView[library]] byExtendingSelection:NO];
    [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:libraryDataSelectionTableView]];
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
        
        // Reload the library selection table view
        [libraryDataSelectionTableView reloadData];
        
        // Display the new content
        [self addLibraryContentView:selectedLibrary];
        
        // Tell the panel to update
        [self updateLibraryContent:nil];
    }
}

- (IBAction)addLibraryDataButtonPress:(id)sender
{
    switch (selectedLibrary)
    {
        case kSequenceLibrary:
            [data createSequenceAndReturnFilePath];
            [libraryDataSelectionTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[data sequenceFilePathsCount] - 1] byExtendingSelection:NO];
            break;
        case kControlBoxLibrary:
            [data createControlBoxAndReturnFilePath];
            [libraryDataSelectionTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[data controlBoxFilePathsCount] - 1] byExtendingSelection:NO];
            break;
        case kChannelGroupLibrary:
            [data createChannelGroupAndReturnFilePath];
            [libraryDataSelectionTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[data channelGroupFilePathsCount] - 1] byExtendingSelection:NO];
            break;
        case kCommandClusterLibrary:
            [data createCommandClusterAndReturnFilePath];
            [libraryDataSelectionTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[data commandClusterFilePathsCount] - 1] byExtendingSelection:NO];
            break;
        case kEffectLibrary:
            [data createEffectAndReturnFilePath];
            [libraryDataSelectionTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[data effectFilePathsCount] - 1] byExtendingSelection:NO];
            break;
        case kAudioClipLibrary:
            [data createAudioClipAndReturnFilePath];
            [libraryDataSelectionTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[data audioClipFilePathsCount] - 1] byExtendingSelection:NO];
            break;
        default:
            break;
    }
    
    [libraryDataSelectionTableView reloadData];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (IBAction)deleteLibraryDataButtonPress:(id)sender
{
    switch(selectedLibrary)
    {
        case kSequenceLibrary:
            [data removeSequenceFromLibrary:[data sequenceFromFilePath:[data sequenceFilePathAtIndex:(int)[libraryDataSelectionTableView selectedRow]]]];
            break;
        case kControlBoxLibrary:
            [data removeControlBoxFromLibrary:[data controlBoxFromFilePath:[data controlBoxFilePathAtIndex:(int)[libraryDataSelectionTableView selectedRow]]]];
            break;
        case kChannelGroupLibrary:
            [data removeChannelGroupFromLibrary:[data channelGroupFromFilePath:[data channelGroupFilePathAtIndex:(int)[libraryDataSelectionTableView selectedRow]]]];
            break;
        case kCommandClusterLibrary:
            [data removeCommandClusterFromLibrary:[data commandClusterFromFilePath:[data commandClusterFilePathAtIndex:(int)[libraryDataSelectionTableView selectedRow]]]];
            break;
        case kEffectLibrary:
            [data removeEffectFromLibrary:[data effectFromFilePath:[data effectFilePathAtIndex:(int)[libraryDataSelectionTableView selectedRow]]]];
            break;
        case kAudioClipLibrary:
            [data removeAudioClipFromLibrary:[data audioClipFromFilePath:[data audioClipFilePathAtIndex:(int)[libraryDataSelectionTableView selectedRow]]]];
            break;
        default:
            break;
    }
    
    [libraryDataSelectionTableView reloadData];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (IBAction)playPlaylistButtonPress:(id)sender
{
    if(playingPlaylist == NO)
    {
        playingPlaylist = YES;
        
        NSUInteger selectedRows[999];
        NSRange range;
        range.length = 999;
        range.location = 0;
        int count = (int)[[libraryDataSelectionTableView selectedRowIndexes] getIndexes:selectedRows maxCount:999 inIndexRange:&range];
        [data playPlaylistOfSequenceIndexes:selectedRows indexCount:count];
        
        [playPlaylistButton setTitle:@"Stop Playlist"];
    }
    else
    {
        playingPlaylist = NO;
        
        [data stopPlaylist];
        
        [playPlaylistButton setTitle:@"Play Playlist"];
    }
}

- (IBAction)importButtonPress:(id)sender
{
    // Load the open panel if neccessary
    if(openPanel == nil)
    {
        openPanel = [NSOpenPanel openPanel];
        [openPanel setCanChooseDirectories:NO];
        [openPanel setCanChooseFiles:YES];
        [openPanel setResolvesAliases:YES];
        [openPanel setAllowsMultipleSelection:NO];
    }
    
    if(previousOpenPanelDirectory == nil)
    {
        [openPanel setDirectoryURL:[NSURL URLWithString:@"~"]];
    }
    else
    {
        [openPanel setDirectoryURL:[NSURL URLWithString:previousOpenPanelDirectory]];
    }
    
    [openPanel beginWithCompletionHandler:^(NSInteger result)
     {
         if(result == NSFileHandlingPanelOKButton)
         {
             NSString *filePath = [[openPanel URL] path];
             [self importDataFromFilePath:filePath];
         }
     }
     ];
}

- (IBAction)exportButtonPress:(id)sender
{
    // Load the open panel if neccessary
    if(openPanel == nil)
    {
        openPanel = [NSOpenPanel openPanel];
        [openPanel setCanChooseDirectories:YES];
        [openPanel setCanChooseFiles:NO];
        [openPanel setResolvesAliases:YES];
        [openPanel setAllowsMultipleSelection:NO];
    }
    
    if(previousOpenPanelDirectory == nil)
    {
        [openPanel setDirectoryURL:[NSURL URLWithString:@"~"]];
    }
    else
    {
        [openPanel setDirectoryURL:[NSURL URLWithString:previousOpenPanelDirectory]];
    }
    
    [openPanel beginWithCompletionHandler:^(NSInteger result)
     {
         if(result == NSFileHandlingPanelOKButton)
         {
             NSString *filePath = [[openPanel URL] path];
             [self exportDataToFilePath:filePath];
         }
     }
     ];
}

- (void)importDataFromFilePath:(NSString *)filePath
{
    if([[filePath pathExtension] isEqualToString:@"lmsd"])
    {
        // Move to the library folder
        NSString *audioClipFileName = [data nextAvailableAudioClipFileName];
        NSString *audioClipFilePath = [NSString stringWithFormat:@"audioClipLibrary/%@.lmsd", audioClipFileName];
        [[NSFileManager defaultManager] moveItemAtPath:filePath toPath:[NSString stringWithFormat:@"%@/%@", [data libraryFolder], audioClipFilePath] error:NULL];
        // Add it to the library
        [data addAudioClipFilePathToAudioClipLibrary:audioClipFilePath];
        // Change it's stored filePath to it's new filePath
        [data setFilePath:audioClipFilePath forDictionary:[data audioClipFromFilePath:audioClipFilePath]];
        
        // Move the audio file
        NSString *audioFileFilePath = [data filePathToAudioFileForAudioClip:[data audioClipFromFilePath:audioClipFilePath]];
        [[NSFileManager defaultManager] moveItemAtPath:[NSString stringWithFormat:@"%@/%@", [filePath stringByDeletingLastPathComponent], [audioFileFilePath lastPathComponent]] toPath:[NSString stringWithFormat:@"%@/%@", [data libraryFolder], audioFileFilePath] error:NULL];
    }
    else if([[filePath pathExtension] isEqualToString:@"lmgp"])
    {
        // Move to the libary folder
        NSString *channelGroupFileName = [data nextAvailableChannelGroupFileName];
        NSString *channelGroupFilePath = [NSString stringWithFormat:@"channelGroupLibrary/%@.lmgp", channelGroupFileName];
        [[NSFileManager defaultManager] moveItemAtPath:filePath toPath:[NSString stringWithFormat:@"%@/%@", [data libraryFolder], channelGroupFilePath] error:NULL];
        // Add it to the library
        [data addChannelGroupFilePathToChannelGroupLibrary:channelGroupFilePath];
        // Change it's stored filePath to it's new filePath
        [data setFilePath:channelGroupFilePath forDictionary:[data channelGroupFromFilePath:channelGroupFilePath]];
    }
    else if([[filePath pathExtension] isEqualToString:@"lmcc"])
    {
        // Move to the libary folder
        NSString *commandClusterFileName = [data nextAvailableCommandClusterFileName];
        NSString *commandClusterFilePath = [NSString stringWithFormat:@"commandClusterLibrary/%@.lmgp", commandClusterFileName];
        [[NSFileManager defaultManager] moveItemAtPath:filePath toPath:[NSString stringWithFormat:@"%@/%@", [data libraryFolder], commandClusterFilePath] error:NULL];
        // Add it to the library
        [data addCommandClusterFilePathToCommandClusterLibrary:commandClusterFilePath];
        // Change it's stored filePath to it's new filePath
        [data setFilePath:commandClusterFilePath forDictionary:[data commandClusterFromFilePath:commandClusterFilePath]];
        
        // Erase any associations with controlBoxes or channelGroups since we have no information about them anymore really
        [data setControlBoxFilePath:@"" forCommandCluster:[data commandClusterFromFilePath:commandClusterFilePath]];
        [data setChannelGroupFilePath:@"" forCommandCluster:[data commandClusterFromFilePath:commandClusterFilePath]];
    }
    else if([[filePath pathExtension] isEqualToString:@"lmcb"])
    {
        // Move to the libary folder
        NSString *controlBoxFileName = [data nextAvailableControlBoxFileName];
        NSString *controlBoxFilePath = [NSString stringWithFormat:@"controlBoxLibrary/%@.lmgp", controlBoxFileName];
        [[NSFileManager defaultManager] moveItemAtPath:filePath toPath:[NSString stringWithFormat:@"%@/%@", [data libraryFolder], controlBoxFilePath] error:NULL];
        // Add it to the library
        [data addControlBoxFilePathToControlBoxLibrary:controlBoxFilePath];
        // Change it's stored filePath to it's new filePath
        [data setFilePath:controlBoxFilePath forDictionary:[data controlBoxFromFilePath:controlBoxFilePath]];
    }
    else if([[filePath pathExtension] isEqualToString:@"lmef"])
    {
        // Move to the libary folder
        NSString *effectFileName = [data nextAvailableEffectFileName];
        NSString *effectFilePath = [NSString stringWithFormat:@"effectLibrary/%@.lmgp", effectFileName];
        [[NSFileManager defaultManager] moveItemAtPath:filePath toPath:[NSString stringWithFormat:@"%@/%@", [data libraryFolder], effectFilePath] error:NULL];
        // Add it to the library
        [data addEffectFilePathToEffectLibrary:effectFilePath];
        // Change it's stored filePath to it's new filePath
        [data setFilePath:effectFilePath forDictionary:[data effectFromFilePath:effectFilePath]];
    }
}

- (void)exportDataToFilePath:(NSString *)filePath
{
    // Get the selected rows from the tableView
    NSUInteger selectedRows[999];
    memset(selectedRows, -1, 999);
    NSRange range;
    range.length = 999;
    range.location = 0;
    int count = (int)[[libraryDataSelectionTableView selectedRowIndexes] getIndexes:selectedRows maxCount:999 inIndexRange:&range];
    
    // Copy individual data items
    if(selectedLibrary != kSequenceLibrary)
    {
        // Loop through each selected item
        for(int i = 0; i < count; i ++)
        {
            // Copy the file to the export folder
            switch(selectedLibrary)
            {
                case kCommandClusterLibrary:
                    [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@/%@", [data libraryFolder], [data commandClusterFilePathAtIndex:(int)selectedRows[i]]] toPath:[NSString stringWithFormat:@"%@/%@", filePath, [[data commandClusterFilePathAtIndex:(int)selectedRows[i]] lastPathComponent]] error:NULL];
                    break;
                case kControlBoxLibrary:
                    [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@/%@", [data libraryFolder], [data controlBoxFilePathAtIndex:(int)selectedRows[i]]] toPath:[NSString stringWithFormat:@"%@/%@", filePath, [[data controlBoxFilePathAtIndex:(int)selectedRows[i]] lastPathComponent]] error:NULL];
                    break;
                case kChannelGroupLibrary:
                    [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@/%@", [data libraryFolder], [data channelGroupFilePathAtIndex:(int)selectedRows[i]]] toPath:[NSString stringWithFormat:@"%@/%@", filePath, [[data channelGroupFilePathAtIndex:(int)selectedRows[i]] lastPathComponent]] error:NULL];
                    break;
                case kEffectLibrary:
                    [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@/%@", [data libraryFolder], [data effectFilePathAtIndex:(int)selectedRows[i]]] toPath:[NSString stringWithFormat:@"%@/%@", filePath, [[data effectFilePathAtIndex:(int)selectedRows[i]] lastPathComponent]] error:NULL];
                    break;
                case kAudioClipLibrary:
                    [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@/%@", [data libraryFolder], [data audioClipFilePathAtIndex:(int)selectedRows[i]]] toPath:[NSString stringWithFormat:@"%@/%@", filePath, [[data audioClipFilePathAtIndex:(int)selectedRows[i]] lastPathComponent]] error:NULL];
                    
                    [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@/%@", [data libraryFolder], [data filePathToAudioFileForAudioClip:[data audioClipFromFilePath:[data audioClipFilePathAtIndex:(int)selectedRows[i]]]]] toPath:[NSString stringWithFormat:@"%@/%@", filePath, [[data filePathToAudioFileForAudioClip:[data audioClipFromFilePath:[data audioClipFilePathAtIndex:(int)selectedRows[i]]]] lastPathComponent]] error:NULL];
                    break;
                default:
                    break;
            }
        }
    }
    // Copy entire sequences
    else
    {
        // Create the folders
        BOOL isDirectory = NO;
        NSString *exportFolderFilePath = [NSString stringWithFormat:@"%@/LMData", filePath];
        if(![[NSFileManager defaultManager] fileExistsAtPath:exportFolderFilePath isDirectory:&isDirectory])
        {
            NSError *error = nil;
            if(![[NSFileManager defaultManager] createDirectoryAtPath:exportFolderFilePath withIntermediateDirectories:YES attributes:nil error:&error])
            {
                [NSException raise:@"Failed creating directory" format:@"[%@], %@", exportFolderFilePath, error];
            }
        }
        NSString *libraryFolderFilePath = [NSString stringWithFormat:@"%@/audioClipLibrary", exportFolderFilePath];
        if(![[NSFileManager defaultManager] fileExistsAtPath:libraryFolderFilePath isDirectory:&isDirectory])
        {
            NSError *error = nil;
            if(![[NSFileManager defaultManager] createDirectoryAtPath:libraryFolderFilePath withIntermediateDirectories:YES attributes:nil error:&error])
            {
                [NSException raise:@"Failed creating directory" format:@"[%@], %@", libraryFolderFilePath, error];
            }
        }
        libraryFolderFilePath = [NSString stringWithFormat:@"%@/channelGroupLibrary", exportFolderFilePath];
        if(![[NSFileManager defaultManager] fileExistsAtPath:libraryFolderFilePath isDirectory:&isDirectory])
        {
            NSError *error = nil;
            if(![[NSFileManager defaultManager] createDirectoryAtPath:libraryFolderFilePath withIntermediateDirectories:YES attributes:nil error:&error])
            {
                [NSException raise:@"Failed creating directory" format:@"[%@], %@", libraryFolderFilePath, error];
            }
        }
        libraryFolderFilePath = [NSString stringWithFormat:@"%@/commandClusterLibrary", exportFolderFilePath];
        if(![[NSFileManager defaultManager] fileExistsAtPath:libraryFolderFilePath isDirectory:&isDirectory])
        {
            NSError *error = nil;
            if(![[NSFileManager defaultManager] createDirectoryAtPath:libraryFolderFilePath withIntermediateDirectories:YES attributes:nil error:&error])
            {
                [NSException raise:@"Failed creating directory" format:@"[%@], %@", libraryFolderFilePath, error];
            }
        }
        libraryFolderFilePath = [NSString stringWithFormat:@"%@/controlBoxLibrary", exportFolderFilePath];
        if(![[NSFileManager defaultManager] fileExistsAtPath:libraryFolderFilePath isDirectory:&isDirectory])
        {
            NSError *error = nil;
            if(![[NSFileManager defaultManager] createDirectoryAtPath:libraryFolderFilePath withIntermediateDirectories:YES attributes:nil error:&error])
            {
                [NSException raise:@"Failed creating directory" format:@"[%@], %@", libraryFolderFilePath, error];
            }
        }
        libraryFolderFilePath = [NSString stringWithFormat:@"%@/effectLibrary", exportFolderFilePath];
        if(![[NSFileManager defaultManager] fileExistsAtPath:libraryFolderFilePath isDirectory:&isDirectory])
        {
            NSError *error = nil;
            if(![[NSFileManager defaultManager] createDirectoryAtPath:libraryFolderFilePath withIntermediateDirectories:YES attributes:nil error:&error])
            {
                [NSException raise:@"Failed creating directory" format:@"[%@], %@", libraryFolderFilePath, error];
            }
        }
        libraryFolderFilePath = [NSString stringWithFormat:@"%@/sequenceLibrary", exportFolderFilePath];
        if(![[NSFileManager defaultManager] fileExistsAtPath:libraryFolderFilePath isDirectory:&isDirectory])
        {
            NSError *error = nil;
            if(![[NSFileManager defaultManager] createDirectoryAtPath:libraryFolderFilePath withIntermediateDirectories:YES attributes:nil error:&error])
            {
                [NSException raise:@"Failed creating directory" format:@"[%@], %@", libraryFolderFilePath, error];
            }
        }
        
        // Loop through each selected sequence
        for(int i = 0; i < count; i ++)
        {
            NSMutableDictionary *sequence = [data sequenceFromFilePath:[data sequenceFilePathAtIndex:(int)selectedRows[i]]];
            
            // Copy the sequence file to the export folder
            [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@/%@", [data libraryFolder], [data sequenceFilePathAtIndex:(int)selectedRows[i]]] toPath:[NSString stringWithFormat:@"%@/%@", exportFolderFilePath, [data sequenceFilePathAtIndex:(int)selectedRows[i]]] error:NULL];
            
            // Copy the commandClusters for this sequence
            for(int i2 = 0; i2 < [data commandClusterFilePathsCountForSequence:sequence]; i2 ++)
            {
                [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@/%@", [data libraryFolder], [data commandClusterFilePathAtIndex:i2 forSequence:sequence]] toPath:[NSString stringWithFormat:@"%@/%@", exportFolderFilePath, [data commandClusterFilePathAtIndex:i2 forSequence:sequence]] error:NULL];
            }
            
            // Copy the controlBoxes for this sequence
            for(int i2 = 0; i2 < [data controlBoxFilePathsCountForSequence:sequence]; i2 ++)
            {
                [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@/%@", [data libraryFolder], [data controlBoxFilePathAtIndex:i2 forSequence:sequence]] toPath:[NSString stringWithFormat:@"%@/%@", exportFolderFilePath, [data controlBoxFilePathAtIndex:i2 forSequence:sequence]] error:NULL];
            }
            
            // Copy the channelGroups for this sequence
            for(int i2 = 0; i2 < [data channelGroupFilePathsCountForSequence:sequence]; i2 ++)
            {
                [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@/%@", [data libraryFolder], [data channelGroupFilePathAtIndex:i2 forSequence:sequence]] toPath:[NSString stringWithFormat:@"%@/%@", exportFolderFilePath, [data channelGroupFilePathAtIndex:i2 forSequence:sequence]] error:NULL];
            }
            
            // Copy the audioClips for this sequence
            for(int i2 = 0; i2 < [data audioClipFilePathsCountForSequence:sequence]; i2 ++)
            {
                [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@/%@", [data libraryFolder], [data audioClipFilePathAtIndex:i2 forSequence:sequence]] toPath:[NSString stringWithFormat:@"%@/%@", exportFolderFilePath, [data audioClipFilePathAtIndex:i2 forSequence:sequence]] error:NULL];
                
                [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@/%@", [data libraryFolder], [data filePathToAudioFileForAudioClip:[data audioClipFromFilePath:[data audioClipFilePathAtIndex:i2 forSequence:sequence]]]] toPath:[NSString stringWithFormat:@"%@/%@", exportFolderFilePath, [data filePathToAudioFileForAudioClip:[data audioClipFromFilePath:[data audioClipFilePathAtIndex:i2 forSequence:sequence]]]] error:NULL];
            }
        }
        
        //zip it all up
        NSURL *destURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@.lmd", exportFolderFilePath]];
        NSTask *task = [[NSTask alloc] init];
        [task setCurrentDirectoryPath:exportFolderFilePath];
        [task setLaunchPath:@"/usr/bin/zip"];
        NSArray *argsArray = [NSArray arrayWithObjects:@"-r", @"-q", [destURL path], @".", @"-i", @"*", nil];
        [task setArguments:argsArray];
        [task launch];
        [task waitUntilExit];
    }
}

#pragma mark - External Notifications

- (void)selectControlBox:(NSNotification *)aNotification
{
    [self displayLibrary:kControlBoxLibrary];
    
    // Select the control box
    int controlBoxIndex = (int)[[data controlBoxFilePaths] indexOfObject:[data filePathForControlBox:[aNotification object]]];
    [libraryDataSelectionTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:controlBoxIndex] byExtendingSelection:NO];
}

- (void)selectChannelGroup:(NSNotification *)aNotification
{
    [self displayLibrary:kChannelGroupLibrary];
    
    // Select the channel group
    int channelGroupIndex = (int)[[data channelGroupFilePaths] indexOfObject:[data filePathForChannelGroup:[aNotification object]]];
    [libraryDataSelectionTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:channelGroupIndex] byExtendingSelection:NO];
}

- (void)selectCommandCluster:(NSNotification *)aNotification
{
    [self displayLibrary:kCommandClusterLibrary];
    
    // Select the commmand cluster
    int commandClusterIndex = (int)[[data commandClusterFilePaths] indexOfObject:[data filePathForCommandCluster:[aNotification object]]];
    [libraryDataSelectionTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:commandClusterIndex] byExtendingSelection:NO];
    
    NSViewController *theLibrary = (NSViewController *)[libraries objectAtIndex:selectedLibrary];
    [theLibrary.view scrollPoint:NSMakePoint(0, theLibrary.view.frame.size.height)];
}

- (void)selectCommand:(NSNotification *)aNotification
{
    [self displayLibrary:kCommandClusterLibrary];
    
    int commandIndex = [[[aNotification object] objectAtIndex:0] intValue];
    NSString *commandClusterFilePath = [[aNotification object] objectAtIndex:1];
    int commandClusterIndex = (int)[[data commandClusterFilePaths] indexOfObject:commandClusterFilePath];
    
    // Select the command cluster
    [libraryDataSelectionTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:commandClusterIndex] byExtendingSelection:NO];
    NSViewController *theLibrary = (NSViewController *)[libraries objectAtIndex:selectedLibrary];
    [theLibrary.view scrollPoint:NSMakePoint(0, 25)];
    
    // Select the command
    [commandClusterLibraryManagerViewController selectCommandAtIndex:commandIndex];
}

- (void)selectAudioClip:(NSNotification *)aNotification
{
    [self displayLibrary:kAudioClipLibrary];
    
    // Select the audio clip
    int audioClipIndex = (int)[[data audioClipFilePaths] indexOfObject:[data filePathForAudioClip:[aNotification object]]];
    [libraryDataSelectionTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:audioClipIndex] byExtendingSelection:NO];
}

- (void)updateTableView:(NSNotification *)aNotification
{
    [libraryDataSelectionTableView reloadData];
}

- (void)updateLibraryContent:(NSNotification *)aNotification
{
    [[libraries objectAtIndex:selectedLibrary] updateContent];
}

#pragma mark - MenuItem Notifications

// Menu Items
- (void)newSequence:(NSNotification *)aNotification
{
    [self displayLibrary:kSequenceLibrary];
    
    [self addLibraryDataButtonPress:nil];
}

- (void)newControlBox:(NSNotification *)aNotification
{
    [self displayLibrary:kControlBoxLibrary];
    
    [self addLibraryDataButtonPress:nil];
}

- (void)newChannelGroup:(NSNotification *)aNotification
{
    [self displayLibrary:kChannelGroupLibrary];
    
    [self addLibraryDataButtonPress:nil];
}

- (void)newCommandCluster:(NSNotification *)aNotification
{
    [self displayLibrary:kCommandClusterLibrary];
    
    [self addLibraryDataButtonPress:nil];
}

- (void)newEffect:(NSNotification *)aNotification
{
    [self displayLibrary:kEffectLibrary];
    
    [self addLibraryDataButtonPress:nil];
}

- (void)newAudioClip:(NSNotification *)aNotification
{
    [self displayLibrary:kAudioClipLibrary];
    
    [self addLibraryDataButtonPress:nil];
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
        case kEffectLibrary:
            return [data effectFilePathsCount];
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
        case kEffectLibrary:
            return [data descriptionForEffect:[data effectFromFilePath:[data effectFilePathAtIndex:(int)rowIndex]]];
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
    
    if([libraryDataSelectionTableView selectedRow] > -1)
    {
        switch(selectedLibrary)
        {
            case kSequenceLibrary:
                [data setCurrentSequence:[data sequenceFromFilePath:[data sequenceFilePathAtIndex:(int)[libraryDataSelectionTableView selectedRow]]]];
                [sequenceLibraryManagerViewController setSequence:[data currentSequence]];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ResetScrollPoint" object:nil];
                break;
            case kControlBoxLibrary:
                [controlBoxLibraryManagerViewController setControlBoxIndex:(int)[libraryDataSelectionTableView selectedRow]];
                break;
            case kChannelGroupLibrary:
                [channelGroupLibraryManagerViewController setChannelGroupIndex:(int)[libraryDataSelectionTableView selectedRow]];
                break;
            case kCommandClusterLibrary:
                [commandClusterLibraryManagerViewController setCommandClusterIndex:(int)[libraryDataSelectionTableView selectedRow]];
                break;
            case kEffectLibrary:
                [effectLibraryManagerViewController setEffectIndex:(int)[libraryDataSelectionTableView selectedRow]];
                break;
            case kAudioClipLibrary:
                [audioClipLibraryManagerViewController setAudioClipIndex:(int)[libraryDataSelectionTableView selectedRow]];
                break;
            default:
                break;
        }
        
        [deleteLibraryDataButton setEnabled:YES];
        [exportButton setEnabled:YES];
    }
    else
    {
        switch(selectedLibrary)
        {
            case kSequenceLibrary:
                [sequenceLibraryManagerViewController setSequence:nil];
                [data setCurrentSequence:nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
                break;
            case kControlBoxLibrary:
                [controlBoxLibraryManagerViewController setControlBoxIndex:-1];
                break;
            case kChannelGroupLibrary:
                [channelGroupLibraryManagerViewController setChannelGroupIndex:-1];
                break;
            case kCommandClusterLibrary:
                [commandClusterLibraryManagerViewController setCommandClusterIndex:-1];
                break;
            case kEffectLibrary:
                [effectLibraryManagerViewController setEffectIndex:-1];
                break;
            case kAudioClipLibrary:
                [audioClipLibraryManagerViewController setAudioClipIndex:-1];
                break;
            default:
                break;
        }
        
        [deleteLibraryDataButton setEnabled:NO];
        [exportButton setEnabled:NO];
    }
    
    [self updateLibraryContent:nil];
}

@end
