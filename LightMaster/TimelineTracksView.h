//
//  TimelineTracksView.h
//  LightMaster
//
//  Created by James Adams on 12/14/11.
//  Copyright (c) 2011 Pencil Busters, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Data.h"

#define TRACK_HEIGHT 80.0
#define TRACK_WIDTH 205.0
#define TOP_BAR_HEIGHT 20.0

enum
{
    MNControlBoxStyle,
    MNSoundStyle,
    MNGroupStyle
};

@interface TimelineTracksView : NSView
{
    Data *__weak data;
    
    NSImage *topBarImage;
    NSImage *controlBoxImage;
    NSImage *groupImage;
    NSImage *soundImage;
    NSImage *recordImage;
    NSImage *blankRecordImage;
}

@property(readwrite) Data *__weak data;

@end
