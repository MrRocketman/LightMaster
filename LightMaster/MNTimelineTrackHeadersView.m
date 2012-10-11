//
//  MNTimelineTrackHeadersView.m
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNTimelineTrackHeadersView.h"

@interface MNTimelineTrackHeadersView()

- (void)drawTrackWithStyle:(int)style text:(NSString *)text trackIndex:(int)trackIndex andDataIndex:(int)dataIndex;

@end


@implementation MNTimelineTrackHeadersView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
    {
        // Custom initialization code here
        topBarImage = [NSImage imageNamed:@"Toolbar.tiff"];
        controlBoxImage = [NSImage imageNamed:@"MNControlBoxStyle.tiff"];
        channelGroupImage = [NSImage imageNamed:@"MNChannelGroupStyle.tiff"];
        audioClipImage = [NSImage imageNamed:@"MNAudioClipStyle.tiff"];
        recordImage = [NSImage imageNamed:@"TrackRecord.tiff"];
        blankRecordImage = [NSImage imageNamed:@"TrackRecordBlank.tiff"];
        
        [self setNeedsDisplay:YES];
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Draw the background
    [[NSColor colorWithPatternImage:[NSImage imageNamed:@"TimelineTrackBackgroundImage.png"]] set];
    NSRectFill(self.bounds);
    
    // Draw the Top Bar
    NSRect trackFrame = NSMakeRect(0, self.frame.size.height - TOP_BAR_HEIGHT, TRACK_WIDTH, TOP_BAR_HEIGHT);
    NSSize imageSize = [topBarImage size];
    [topBarImage drawInRect:trackFrame fromRect:NSMakeRect(0.0, 0.0, imageSize.width, imageSize.height) operation:NSCompositeSourceOver fraction:1.0];
    
    NSMutableDictionary *currentSequence = [data currentSequence];
    int tracksCount = [data audioClipFilePathsCountForSequence:currentSequence] + [data controlBoxFilePathsCountForSequence:currentSequence] + [data channelGroupFilePathsCountForSequence:currentSequence];
    // Set the Frame
    if(tracksCount * TRACK_HEIGHT + TOP_BAR_HEIGHT > [[self superview] frame].size.height)
    {
        [self setFrame:NSMakeRect(0.0, 0.0, self.bounds.size.width, tracksCount * TRACK_HEIGHT + TOP_BAR_HEIGHT)];
    }
    else
    {
        [self setFrame:NSMakeRect(0.0, 0.0, self.bounds.size.width, [[self superview] frame].size.height)];
    }
    
    tracksCount = 0;
    // Draw the audio track
    if([data audioClipFilePathsCountForSequence:currentSequence] > 0)
    {
        [self drawTrackWithStyle:MNAudioClipStyle text:@"Audio" trackIndex:tracksCount andDataIndex:-1];
        tracksCount ++;
    }
    // Draw the controlBox tracks
    for(int i = 0; i < [data controlBoxFilePathsCountForSequence:currentSequence]; i ++)
    {
        [self drawTrackWithStyle:MNControlBoxStyle text:[data descriptionForControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathAtIndex:i forSequence:currentSequence]]] trackIndex:tracksCount andDataIndex:i];
        
        tracksCount ++;
    }
    // Draw the channelGroup tracks
    for(int i = 0; i < [data channelGroupFilePathsCountForSequence:currentSequence]; i ++)
    {
        [self drawTrackWithStyle:MNChannelGroupStyle text:[data descriptionForChannelGroup:[data channelGroupFromFilePath:[data channelGroupFilePathAtIndex:i forSequence:currentSequence]]] trackIndex:tracksCount andDataIndex:i];
        tracksCount ++;
    }
}

- (void)drawTrackWithStyle:(int)style text:(NSString *)text trackIndex:(int)trackIndex andDataIndex:(int)dataIndex
{
    NSRect trackFrame = NSMakeRect(0, self.frame.size.height - (trackIndex + 1) * TRACK_HEIGHT - TOP_BAR_HEIGHT, TRACK_WIDTH, TRACK_HEIGHT);
    if(style == MNControlBoxStyle)
    {
        NSSize imageSize = [controlBoxImage size];
        [controlBoxImage drawInRect:trackFrame fromRect:NSMakeRect(0.0, 0.0, imageSize.width, imageSize.height) operation:NSCompositeSourceOver fraction:1.0];
        
        // Mouse checking
        if([[NSBezierPath bezierPathWithRect:trackFrame] containsPoint:mousePoint] && mouseAction == MNMouseUp && mouseEvent != nil)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectControlBox" object:[data controlBoxFromFilePath:[data controlBoxFilePathAtIndex:dataIndex forSequence:[data currentSequence]]]];
            mouseEvent = nil;
        }
    }
    else if(style == MNChannelGroupStyle)
    {
        NSSize imageSize = [channelGroupImage size];
        [channelGroupImage drawInRect:trackFrame fromRect:NSMakeRect(0.0, 0.0, imageSize.width, imageSize.height) operation:NSCompositeSourceOver fraction:1.0];
        
        // Mouse checking
        if([[NSBezierPath bezierPathWithRect:trackFrame] containsPoint:mousePoint] && mouseAction == MNMouseUp && mouseEvent != nil)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectChannelGroup" object:[data channelGroupFromFilePath:[data channelGroupFilePathAtIndex:dataIndex forSequence:[data currentSequence]]]];
            mouseEvent = nil;
        }
    }
    else if(style == MNAudioClipStyle)
    {
        NSSize imageSize = [audioClipImage size];
        [audioClipImage drawInRect:trackFrame fromRect:NSMakeRect(0.0, 0.0, imageSize.width, imageSize.height) operation:NSCompositeSourceOver fraction:1.0];
    }
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    NSFont *font = [NSFont fontWithName:@"Helvetica Bold" size:20];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineBreakMode:NSLineBreakByCharWrapping];
    [attributes setObject:font forKey:NSFontAttributeName];
    [attributes setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
    NSRect textFrame = NSMakeRect(10, trackFrame.origin.y + 10, TRACK_WIDTH - 60, TRACK_HEIGHT - 20);
    [text drawInRect:textFrame withAttributes:attributes];
    
    if(NO)
    {
        NSSize imageSize = [recordImage size];
        NSRect recordImageRect = NSMakeRect(TRACK_WIDTH - 50, trackFrame.origin.y + TRACK_HEIGHT / 2 - 20, 40, 40);
        [recordImage drawInRect:recordImageRect fromRect:NSMakeRect(0.0, 0.0, imageSize.width, imageSize.height) operation:NSCompositeSourceOver fraction:1.0];
    }
    else
    {
        NSSize imageSize = [blankRecordImage size];
        NSRect recordImageRect = NSMakeRect(TRACK_WIDTH - 50, trackFrame.origin.y + TRACK_HEIGHT / 2 - 20, 40, 40);
        [blankRecordImage drawInRect:recordImageRect fromRect:NSMakeRect(0.0, 0.0, imageSize.width, imageSize.height) operation:NSCompositeSourceOver fraction:1.0];
    }
}

#pragma mark Mouse Methods

- (void)mouseDown:(NSEvent *)theEvent
{
	NSPoint eventLocation = [theEvent locationInWindow];
	mousePoint = [self convertPoint:eventLocation fromView:nil];
    mouseAction = MNMouseDown;
    mouseEvent = theEvent;
    
    [self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint eventLocation = [theEvent locationInWindow];
	mousePoint = [self convertPoint:eventLocation fromView:nil];
    mouseAction = MNMouseDragged;
    mouseEvent = theEvent;
    [self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	NSPoint eventLocation = [theEvent locationInWindow];
	mousePoint = [self convertPoint:eventLocation fromView:nil];
    mouseAction = MNMouseUp;
    mouseEvent = theEvent;

    
    [self setNeedsDisplay:YES];
}

@end

