//
//  SDTrackPositionView.m
//  Songs
//
//  Created by Steven Degutis on 3/26/13.
//  Copyright (c) 2013 Steven Degutis. All rights reserved.
//

#import "SDTrackSliderCell.h"

#import "SDColors.h"

@implementation SDTrackSliderCell

- (void) setDoubleValue:(double)aDouble {
    if (![self isHighlighted])
        [super setDoubleValue:aDouble];
}

- (void) drawKnob:(NSRect)knobRect {
    if (fabs([self maxValue]) < 0.0005)
        return;
    
    knobRect = [[self controlView] bounds];
    
    CGFloat knobWidth = knobRect.size.height;
    CGFloat availWidth = knobRect.size.width - knobWidth;
    
    knobRect.origin.x += (([self doubleValue] / [self maxValue]) * availWidth);
    knobRect.size.width = knobWidth;
    
    knobRect = NSIntegralRect(knobRect);
    knobRect = NSInsetRect(knobRect, 3.0, 3.0);
    
    
    NSBezierPath* path = [NSBezierPath bezierPathWithOvalInRect:knobRect];
    
//    knobRect = NSInsetRect(knobRect, 10.0, 0.0);
//    NSBezierPath* path = [NSBezierPath bezierPathWithRect:knobRect];
    
    [path setLineWidth:3.0];
    
    [[NSColor windowBackgroundColor] setFill];
    [SDDarkBlue setStroke];
    [path fill];
    [path stroke];
    
//    [SDDarkBlue setFill];
//    [path fill];
}

- (void) drawBarInside:(NSRect)aRect flipped:(BOOL)flipped {
    aRect = NSIntegralRect(aRect);
    aRect = NSInsetRect(aRect, 0.0, 1.0);
    CGFloat r = 2.0;
    
    [[NSColor whiteColor] setFill];
    [[NSBezierPath bezierPathWithRoundedRect:aRect xRadius:r yRadius:r] fill];
}

@end
