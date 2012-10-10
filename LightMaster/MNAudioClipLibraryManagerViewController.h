//
//  MNAudioClipLibraryManagerViewController.h
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MNData;

@interface MNAudioClipLibraryManagerViewController : NSViewController
{
    int audioClipIndex;
    __block IBOutlet MNData *data;
    
    IBOutlet NSTextField *descriptionTextField;
    IBOutlet NSTextField *startTimeTextField;
    IBOutlet NSTextField *endTimeTextField;
    IBOutlet NSTextField *seekTimeTextField;
    IBOutlet NSTextField *filePathLabel;
    IBOutlet NSButton *chooseAudioFileButton;
    IBOutlet NSButton *chooseAudioFileFromLibraryButton;
    NSOpenPanel *openPanel;
    NSString *previousOpenPanelDirectory;
}

@property() int audioClipIndex;

- (void)updateContent;

- (IBAction)chooseAudioFileButtonPress:(id)sender;
- (IBAction)chooseAudioFileFromLibraryButtonPress:(id)sender;

@end
