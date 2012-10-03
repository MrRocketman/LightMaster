//
//  LibraryView.m
//  LightMaster
//
//  Created by James Adams on 12/14/11.
//  Copyright (c) 2011 Pencil Busters, Inc. All rights reserved.
//

#import "LibraryView.h"

@implementation LibraryView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
    {
        // Custom initialization code here
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    [[NSColor orangeColor] set];
    NSRectFill([self bounds]);
}

@end
