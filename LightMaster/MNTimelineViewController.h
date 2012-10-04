//
//  MNTimelineViewController.h
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MNData.h"
#import "MNTimelineTrackHeadersView.h"
#import "MNTimelineTracksView.h"
#import "MNSynchronizedScrollView.h"

@interface MNTimelineViewController : NSViewController
{
    IBOutlet MNData *data;
    IBOutlet MNSynchronizedScrollView *timelineTrackHeadersScrollView;
    IBOutlet MNSynchronizedScrollView *timelineTracksScrollView;
    IBOutlet MNTimelineTrackHeadersView *timelineTrackHeadersView;
    IBOutlet MNTimelineTracksView *timelineTracksView;
    
    float zoomLevel;
}

@property(readwrite, assign) float zoomLevel;
- (IBAction)zoomLevelChange:(id)sender;

@end