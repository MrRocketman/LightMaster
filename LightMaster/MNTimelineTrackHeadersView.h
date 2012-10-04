//
//  MNTimelineTrackHeadersView.h
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNSynchronizedScrollView.h"
#import "MNData.h"

#define TRACK_HEIGHT 80.0
#define TRACK_WIDTH 200.0
#define TOP_BAR_HEIGHT 20.0

enum
{
    MNControlBoxStyle,
    MNAudioClipStyle,
    MNChannelGroupStyle
};

@interface MNTimelineTrackHeadersView : MNSynchronizedScrollView
{
    MNData *__weak data;
    
    NSImage *topBarImage;
    NSImage *controlBoxImage;
    NSImage *channelGroupImage;
    NSImage *audioClipImage;
    NSImage *recordImage;
    NSImage *blankRecordImage;
}

@property(readwrite) MNData *__weak data;

@end

