//
//  MNAudioClipLibraryManagerViewController.m
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNAudioClipLibraryManagerViewController.h"
#import "MNData.h"

@interface MNAudioClipLibraryManagerViewController ()

- (void)textDidBeginEditing:(NSNotification *)aNotification;
- (void)textDidEndEditing:(NSNotification *)aNotification;
- (NSMutableDictionary *)audioClip;
- (void)loadOpenPanel;

@end

@implementation MNAudioClipLibraryManagerViewController

@synthesize audioClipIndex;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Text Editing Notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidBeginEditing:) name:@"NSControlTextDidBeginEditingNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidEndEditing:) name:@"NSControlTextDidEndEditingNotification" object:nil];
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:@"NSTextDidChangeNotification" object:scriptTextView];
    }
    
    return self;
}

- (NSMutableDictionary *)audioClip
{
    if(audioClipIndex > -1)
        return [data audioClipFromFilePath:[data audioClipFilePathAtIndex:audioClipIndex]];
    
    return nil;
}

- (void)loadOpenPanel
{
    // Load the open panel if neccessary
    if(openPanel == nil)
    {
        openPanel = [NSOpenPanel openPanel];
        [openPanel setCanChooseDirectories:NO];
        [openPanel setCanChooseFiles:YES];
        [openPanel setResolvesAliases:YES];
        [openPanel setAllowsMultipleSelection:NO];
        [openPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"aac", @"aif", @"aiff", @"alac", @"mp3", @"m4a", @"wav", nil]];
    }
}

#pragma mark - Public Methods

- (void)updateContent
{
    if(audioClipIndex > -1)
    {
        [descriptionTextField setEnabled:YES];
        [startTimeTextField setEditable:YES];
        [endTimeTextField setEnabled:YES];
        [seekTimeTextField setEnabled:YES];
        [chooseAudioFileButton setEnabled:YES];
        [chooseAudioFileFromLibraryButton setEnabled:YES];
        
        [descriptionTextField setStringValue:[data descriptionForEffect:[self audioClip]]];
        [startTimeTextField setStringValue:[NSString stringWithFormat:@"%.3f", [data startTimeForAudioClip:[self audioClip]]]];
        [endTimeTextField setStringValue:[NSString stringWithFormat:@"%.3f", [data endTimeForAudioClip:[self audioClip]]]];
        [seekTimeTextField setStringValue:[NSString stringWithFormat:@"%.3f", [data seekTimeForAudioClip:[self audioClip]]]];
        
        if([[data filePathToAudioFileForAudioClip:[self audioClip]] length] > 0)
        {
            [filePathLabel setStringValue:[[data filePathToAudioFileForAudioClip:[self audioClip]] lastPathComponent]];
        }
        else
        {
            [filePathLabel setStringValue:@""];
        }
    }
    else
    {
        [descriptionTextField setEnabled:NO];
        [startTimeTextField setEditable:NO];
        [endTimeTextField setEnabled:NO];
        [seekTimeTextField setEnabled:NO];
        [chooseAudioFileButton setEnabled:NO];
        [chooseAudioFileFromLibraryButton setEnabled:NO];
        
        [descriptionTextField setStringValue:@""];
        [startTimeTextField setStringValue:@""];
        [endTimeTextField setStringValue:@""];
        [seekTimeTextField setStringValue:@""];
        [filePathLabel setStringValue:@""];
    }
}

- (IBAction)chooseAudioFileButtonPress:(id)sender
{
    [self loadOpenPanel];
    
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
             //NSLog(@"filePath:%@", filePath);
             NSString *libraryFolder = [data applicationSupportDirectory];
             NSString *soundLibraryDirectory = [NSString stringWithFormat:@"%@/soundLibrary", libraryFolder];
             NSRange textRange = [[filePath lowercaseString] rangeOfString:[soundLibraryDirectory lowercaseString]];
             
             // Library Sound
             if(textRange.location != NSNotFound)
             {
                 // Set the filePath
                 [data setFilePathToAudioFile:[NSString stringWithFormat:@"soundLibrary/%@", [filePath lastPathComponent]] forAudioClip:[self audioClip]];
                 
                 [filePathLabel setStringValue:[filePath lastPathComponent]];
             }
             // External Sound
             else
             {
                 // Make a copy of the sound file and store it in the library
                 NSString *newFilePath = [NSString stringWithFormat:@"%@/soundLibrary/%@", [data libraryFolder], [filePath lastPathComponent]];
                 NSFileManager *fileManager = [NSFileManager defaultManager];
                 [fileManager copyItemAtPath:filePath toPath:newFilePath error:NULL];
                 
                 // Set the filePath
                 [data setFilePathToAudioFile:[NSString stringWithFormat:@"soundLibrary/%@", [filePath lastPathComponent]] forAudioClip:[self audioClip]];
                 [filePathLabel setStringValue:[filePath lastPathComponent]];
             }
             
             [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
         }
     }
     ];
}

- (IBAction)chooseAudioFileFromLibraryButtonPress:(id)sender
{
    [self loadOpenPanel];
    
    NSString *soundLibraryDirectory = [NSString stringWithFormat:@"%@/soundLibrary", [data libraryFolder]];
    [openPanel setDirectoryURL:[NSURL URLWithString:soundLibraryDirectory]];
    
    [openPanel beginWithCompletionHandler:^(NSInteger result)
     {
         if(result == NSFileHandlingPanelOKButton)
         {
             NSString *filePath = [[openPanel URL] path];
             //NSLog(@"filePath:%@", filePath);
             NSString *libraryFolder = [data applicationSupportDirectory];
             NSString *soundLibraryDirectory = [NSString stringWithFormat:@"%@/soundLibrary", libraryFolder];
             NSRange textRange = [[filePath lowercaseString] rangeOfString:[soundLibraryDirectory lowercaseString]];
             
             // Library Sound
             if(textRange.location != NSNotFound)
             {
                 // Set the filePath
                 [data setFilePathToAudioFile:[NSString stringWithFormat:@"soundLibrary/%@", [filePath lastPathComponent]] forAudioClip:[self audioClip]];
                 
                 [filePathLabel setStringValue:[filePath lastPathComponent]];
             }
             // External Sound
             else
             {
                 // Make a copy of the sound file and store it in the library
                 NSString *newFilePath = [NSString stringWithFormat:@"%@/soundLibrary/%@", [data libraryFolder], [filePath lastPathComponent]];
                 NSFileManager *fileManager = [NSFileManager defaultManager];
                 [fileManager copyItemAtPath:filePath toPath:newFilePath error:NULL];
                 
                 // Set the filePath
                 [data setFilePathToAudioFile:[NSString stringWithFormat:@"soundLibrary/%@", [filePath lastPathComponent]] forAudioClip:[self audioClip]];
                 [filePathLabel setStringValue:[filePath lastPathComponent]];
             }
             
             [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
         }
     }
     ];
}

#pragma mark - TextEditinig Notifications

- (void)textDidBeginEditing:(NSNotification *)aNotification
{
    
}

- (void)textDidEndEditing:(NSNotification *)aNotification
{
    if([aNotification object] == descriptionTextField)
    {
        [data setDescription:[descriptionTextField stringValue] forAudioClip:[self audioClip]];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLibrariesViewController" object:nil];
    }
    else if([aNotification object] == startTimeTextField)
    {
        [data setStartTime:[startTimeTextField floatValue] forAudioClip:[self audioClip]];
    }
    else if([aNotification object] == endTimeTextField)
    {
        [data setEndTime:[endTimeTextField floatValue] forAudioClip:[self audioClip]];
    }
    else if([aNotification object] == seekTimeTextField)
    {
        [data setSeekTime:[seekTimeTextField floatValue] forAudioClip:[self audioClip]];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

@end
