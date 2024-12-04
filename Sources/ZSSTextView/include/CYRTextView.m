//
//  CYRTextView.m
//
//  Version 0.2.0
//
//  Created by Illya Busigin on 01/05/2014.
//  Copyright (c) 2014 Cyrillian, Inc.
//  Copyright (c) 2013 Dominik Hauser
//  Copyright (c) 2013 Sam Rijs
//
//  Distributed under MIT license.
//  Get the latest version from here:
//
//  https://github.com/illyabusigin/CYRTextView
//
// The MIT License (MIT)
//
// Copyright (c) 2014 Cyrillian, Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "CYRTextView.h"
#import "CYRLayoutManager.h"
#import "CYRTextStorage.h"

static void *CYRTextViewContext = &CYRTextViewContext;
static const float kCursorVelocity = 1.0f/8.0f;

@interface CYRTextView()

    @property (nonatomic, strong) CYRLayoutManager *lineNumberLayoutManager;
    @property (nonatomic, strong) CYRTextStorage *syntaxTextStorage;

@end

@implementation CYRTextView {

    NSRange startRange;
}

#pragma mark - Initialization & Setup

- (id) initWithFrame: (CGRect) frame {

    CYRTextStorage *textStorage = [CYRTextStorage new];
    CYRLayoutManager *layoutManager = [CYRLayoutManager new];

    self.lineNumberLayoutManager = layoutManager;

    NSTextContainer* textContainer = [[NSTextContainer alloc] initWithSize: CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];

    // Wrap text to the text view's frame
    textContainer.widthTracksTextView = YES;

    [layoutManager addTextContainer: textContainer];

    [textStorage removeLayoutManager: textStorage.layoutManagers.firstObject];
    [textStorage addLayoutManager: layoutManager];

    self.syntaxTextStorage = textStorage;

    if ((self = [super initWithFrame: frame textContainer: textContainer])) {

        self.contentMode = UIViewContentModeRedraw; // causes drawRect: to be called on frame resizing and device rotation

        [self _commonSetup];
    }

    return self;
}

- (void) _commonSetup {

    // Setup observers
    [self addObserver:self forKeyPath:NSStringFromSelector(@selector(font)) options:NSKeyValueObservingOptionNew context:CYRTextViewContext];
    [self addObserver:self forKeyPath:NSStringFromSelector(@selector(textColor)) options:NSKeyValueObservingOptionNew context:CYRTextViewContext];
    [self addObserver:self forKeyPath:NSStringFromSelector(@selector(selectedTextRange)) options:NSKeyValueObservingOptionNew context:CYRTextViewContext];
    [self addObserver:self forKeyPath:NSStringFromSelector(@selector(selectedRange)) options:NSKeyValueObservingOptionNew context:CYRTextViewContext];

    // Setup defaults
    self.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.autocorrectionType = UITextAutocorrectionTypeNo;
    self.lineCursorEnabled = YES;

    self.gutterBackgroundColor = [UIColor systemGray5Color];
    self.gutterLineColor = [UIColor systemGray3Color];

    // Inset the content to make room for line numbers
    self.textContainerInset = UIEdgeInsetsMake(8, self.lineNumberLayoutManager.gutterWidth, 8, 0);

    // Setup the gesture recognizers
    _singleFingerPanRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(singleFingerPanHappend:)];
    _singleFingerPanRecognizer.maximumNumberOfTouches = 1;
    [self addGestureRecognizer:_singleFingerPanRecognizer];

    _doubleFingerPanRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(doubleFingerPanHappend:)];
    _doubleFingerPanRecognizer.minimumNumberOfTouches = 2;
    [self addGestureRecognizer:_doubleFingerPanRecognizer];
}

#pragma mark - Cleanup

- (void) dealloc {

    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(font))];
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(textColor))];
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(selectedTextRange))];
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(selectedRange))];
}

#pragma mark - KVO

- (void) observeValueForKeyPath: (NSString *)keyPath
                       ofObject: (id)object
                         change: (NSDictionary *)change
                        context: (void *)context {

    if ([keyPath isEqualToString: NSStringFromSelector(@selector(font))] && context == CYRTextViewContext) {

        // Whenever the UITextView font is changed we want to keep a reference in the stickyFont ivar.
        // We do this to counteract a bug where the underlying font can be changed without notice and cause undesired behaviour.
        self.syntaxTextStorage.defaultFont = self.font;
    }
    else if ([keyPath isEqualToString:NSStringFromSelector(@selector(textColor))] && context == CYRTextViewContext) {

        self.syntaxTextStorage.defaultTextColor = self.textColor;
    }
    else if (([keyPath isEqualToString: NSStringFromSelector(@selector(selectedTextRange))] ||
              [keyPath isEqualToString: NSStringFromSelector(@selector(selectedRange))]) && context == CYRTextViewContext) {

        [self setNeedsDisplay];
    }
    else {
        [super observeValueForKeyPath: keyPath
                             ofObject: object
                               change: change
                              context: context];
    }
}

#pragma mark - Overrides

- (void) setTokens: (NSMutableArray*) tokens {

    [self.syntaxTextStorage setTokens:tokens];
}

- (NSArray*) tokens {

    CYRTextStorage *syntaxTextStorage = (CYRTextStorage *)self.textStorage;

    return syntaxTextStorage.tokens;
}

- (void) setText: (NSString*) text {

    UITextRange* textRange = [self textRangeFromPosition: self.beginningOfDocument
                                              toPosition: self.endOfDocument];
    [self replaceRange: textRange
              withText: text];
}

#pragma mark - Line Drawing

// Original implementation sourced from: https://github.com/alldritt/TextKit_LineNumbers
- (void) drawRect: (CGRect) rect {

    // Drag the line number gutter background.  The line numbers themselves are drawn by LineNumberLayoutManager.
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect bounds = self.bounds;

    CGFloat height = MAX(CGRectGetHeight(bounds), self.contentSize.height) + 200;

    // Set the regular fill
    CGContextSetFillColorWithColor(context, self.gutterBackgroundColor.CGColor);
    CGContextFillRect(context, CGRectMake(bounds.origin.x,
                                          bounds.origin.y,
                                          self.lineNumberLayoutManager.gutterWidth,
                                          height));
    // Draw line
    CGContextSetFillColorWithColor(context, self.gutterLineColor.CGColor);
    CGContextFillRect(context, CGRectMake(self.lineNumberLayoutManager.gutterWidth,
                                          bounds.origin.y,
                                          0.5,
                                          height));
    if (_lineCursorEnabled) {

        self.lineNumberLayoutManager.selectedRange = self.selectedRange;

        NSRange glyphRange = [self.lineNumberLayoutManager.textStorage.string paragraphRangeForRange:self.selectedRange];
        glyphRange = [self.lineNumberLayoutManager glyphRangeForCharacterRange:glyphRange actualCharacterRange:NULL];
        self.lineNumberLayoutManager.selectedRange = glyphRange;
        [self.lineNumberLayoutManager invalidateDisplayForGlyphRange:glyphRange];
    }

    [super drawRect: rect];
}

#pragma mark - Gestures

// Sourced from: https://github.com/srijs/NLTextView
- (BOOL) gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer
{
    // Only accept horizontal pans for the code navigation to preserve correct scrolling behaviour.
    if (gestureRecognizer == _singleFingerPanRecognizer || gestureRecognizer == _doubleFingerPanRecognizer)
    {
        CGPoint translation = [gestureRecognizer translationInView:self];
        
        float translationX = (float)translation.x;
        float translationY = (float)translation.y;
        
        return fabsf(translationX) > fabsf(translationY);
    }
    
    return YES;
}

// Sourced from: https://github.com/srijs/NLTextView
- (void) singleFingerPanHappend:(UIPanGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        startRange = self.selectedRange;
    }
    
    CGFloat cursorLocation = MAX(startRange.location + [sender translationInView:self].x * kCursorVelocity, 0);
    
    self.selectedRange = NSMakeRange(cursorLocation, 0);
}

// Sourced from: https://github.com/srijs/NLTextView
- (void) doubleFingerPanHappend:(UIPanGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        startRange = self.selectedRange;
    }
    
    CGFloat cursorLocation = MAX(startRange.location + [sender translationInView:self].x * kCursorVelocity, 0);
    
    float location = startRange.location - cursorLocation;
    
    if (cursorLocation > startRange.location)
    {
        self.selectedRange = NSMakeRange(startRange.location, fabsf(location));
    }
    else
    {
        self.selectedRange = NSMakeRange(cursorLocation, fabsf(location));
    }
}

@end
