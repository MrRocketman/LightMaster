//
//  MNAudioClipLibraryManagerViewController.h
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MNAudioClipLibraryManagerViewController : NSViewController
{
    NSMutableDictionary __weak *audioClip;
}

@property(readwrite, weak) NSMutableDictionary *audioClip;

@end
