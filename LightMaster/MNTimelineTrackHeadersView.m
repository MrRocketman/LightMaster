//
//  MNTimelineTrackHeadersView.m
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNTimelineTrackHeadersView.h"

@interface MNTimelineTrackHeadersView()

- (void)drawTrackWithStyle:(int)style text:(NSString *)text trackIndex:(int)trackIndex trackItemsCount:(int)trackItemsCount andDataIndex:(int)dataIndex;
- (NSFont *)fontSizedForAreaSize:(NSSize)size withString:(NSString *)string usingFont:(NSFont *)font;
- (float)scaleToAspectFit:(CGSize)source into:(CGSize)into padding:(float)padding;

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

- (NSFont *)fontSizedForAreaSize:(NSSize)size withString:(NSString *)string usingFont:(NSFont *)font
{
    NSFont *sampleFont = [NSFont fontWithDescriptor:font.fontDescriptor size:12.0];
    CGSize sampleSize = [string sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:sampleFont, NSFontAttributeName, nil]];
    float scale = [self scaleToAspectFit:sampleSize into:size padding:10];
    return [NSFont fontWithDescriptor:font.fontDescriptor size:scale * sampleFont.pointSize];
}

- (float)scaleToAspectFit:(CGSize)source into:(CGSize)into padding:(float)padding
{
    return MIN((into.width - padding) / source.width, (into.height - padding) / source.height);
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Draw the background
    [[NSColor colorWithPatternImage:[NSImage imageNamed:@"TimelineTrackBackgroundImage.png"]] set];
    NSRectFill(self.bounds);
    
    // Draw the Top Bar
    NSRect trackFrame = NSMakeRect(0, self.frame.size.height - TOP_BAR_HEIGHT, self.frame.size.width, TOP_BAR_HEIGHT);
    NSSize imageSize = [topBarImage size];
    [topBarImage drawInRect:trackFrame fromRect:NSMakeRect(0.0, 0.0, imageSize.width, imageSize.height) operation:NSCompositeSourceOver fraction:1.0];
    
    // Get some state variables
    int trackItemsCount = [data trackItemsCount];
    
    // Set the Frame
    if(trackItemsCount * TRACK_ITEM_HEIGHT + TOP_BAR_HEIGHT > [[self superview] frame].size.height)
    {
        [self setFrame:NSMakeRect(0.0, 0.0, self.bounds.size.width, trackItemsCount * TRACK_ITEM_HEIGHT + TOP_BAR_HEIGHT - 25)];
    }
    else
    {
        [self setFrame:NSMakeRect(0.0, 0.0, self.bounds.size.width, [[self superview] frame].size.height)];
    }
    
    trackItemsCount = 0;
    int thisTrackItemsCount = 0;
    // Draw the audio track
    if([data audioClipFilePathsCountForSequence:[data currentSequence]] > 0)
    {
        thisTrackItemsCount = [data audioClipFilePathsCountForSequence:[data currentSequence]];
        [self drawTrackWithStyle:MNAudioClipStyle text:@"Audio" trackIndex:trackItemsCount trackItemsCount:thisTrackItemsCount andDataIndex:-1];
        trackItemsCount += thisTrackItemsCount;
    }
    // Draw the controlBox tracks
    for(int i = 0; i < [data controlBoxFilePathsCountForSequence:[data currentSequence]]; i ++)
    {
        thisTrackItemsCount = [data channelsCountForControlBox:[data controlBoxForCurrentSequenceAtIndex:i]];
        
        [self drawTrackWithStyle:MNControlBoxStyle text:[data descriptionForControlBox:[data controlBoxForCurrentSequenceAtIndex:i]] trackIndex:trackItemsCount trackItemsCount:thisTrackItemsCount andDataIndex:i];
        
        trackItemsCount += thisTrackItemsCount;
    }
    // Draw the channelGroup tracks
    for(int i = 0; i < [data channelGroupFilePathsCountForSequence:[data currentSequence]]; i ++)
    {
        thisTrackItemsCount = [data itemsCountForChannelGroup:[data channelGroupForCurrentSequenceAtIndex:i]];
        
        [self drawTrackWithStyle:MNChannelGroupStyle text:[data descriptionForChannelGroup:[data channelGroupForCurrentSequenceAtIndex:i]] trackIndex:trackItemsCount trackItemsCount:thisTrackItemsCount andDataIndex:i];
        
        trackItemsCount += thisTrackItemsCount;
    }
}

- (void)drawTrackWithStyle:(int)style text:(NSString *)text trackIndex:(int)trackIndex trackItemsCount:(int)trackItemsCount andDataIndex:(int)dataIndex
{
    NSRect trackFrame = NSMakeRect(0, self.frame.size.height - trackIndex * TRACK_ITEM_HEIGHT - trackItemsCount * TRACK_ITEM_HEIGHT - TOP_BAR_HEIGHT, self.frame.size.width, TRACK_ITEM_HEIGHT * trackItemsCount);
    if(style == MNControlBoxStyle)
    {
        NSSize imageSize = [controlBoxImage size];
        [controlBoxImage drawInRect:trackFrame fromRect:NSMakeRect(0.0, 0.0, imageSize.width, imageSize.height) operation:NSCompositeSourceOver fraction:1.0];
        
        // Mouse checking
        if([[NSBezierPath bezierPathWithRect:trackFrame] containsPoint:mousePoint] && mouseAction == MNMouseUp && mouseEvent != nil)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectControlBox" object:[data controlBoxForCurrentSequenceAtIndex:dataIndex]];
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
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectChannelGroup" object:[data channelGroupForCurrentSequenceAtIndex:dataIndex]];
            mouseEvent = nil;
        }
    }
    else if(style == MNAudioClipStyle)
    {
        NSSize imageSize = [audioClipImage size];
        [audioClipImage drawInRect:trackFrame fromRect:NSMakeRect(0.0, 0.0, imageSize.width, imageSize.height) operation:NSCompositeSourceOver fraction:1.0];
    }
    
    // Draw the text
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    NSFont *font = [NSFont fontWithName:@"Helvetica Bold" size:60];
    NSRect textFrame = NSMakeRect(10, trackFrame.origin.y + 5, self.frame.size.width - 60, TRACK_ITEM_HEIGHT * trackItemsCount - 10);
    font = [self fontSizedForAreaSize:textFrame.size withString:text usingFont:font];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineBreakMode:NSLineBreakByCharWrapping];
    [attributes setObject:font forKey:NSFontAttributeName];
    [attributes setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
    [text drawInRect:textFrame withAttributes:attributes];
    
    /*if(NO)
    {
        NSSize imageSize = [recordImage size];
        NSRect recordImageRect = NSMakeRect(self.frame.size.width - 50, trackFrame.origin.y + TRACK_ITEM_HEIGHT * trackItemsCount / 2 - 20, 40, 40);
        [recordImage drawInRect:recordImageRect fromRect:NSMakeRect(0.0, 0.0, imageSize.width, imageSize.height) operation:NSCompositeSourceOver fraction:1.0];
    }
    else
    {
        NSSize imageSize = [blankRecordImage size];
        NSRect recordImageRect = NSMakeRect(self.frame.size.width - 50, trackFrame.origin.y + TRACK_ITEM_HEIGHT * trackItemsCount / 2 - 20, 40, 40);
        [blankRecordImage drawInRect:recordImageRect fromRect:NSMakeRect(0.0, 0.0, imageSize.width, imageSize.height) operation:NSCompositeSourceOver fraction:1.0];
    }*/
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

