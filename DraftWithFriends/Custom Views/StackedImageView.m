//
//  StackedImageView.m
//  DraftWithFriends
//
//  Created by Trent Ellingsen on 12/19/13.
//  Copyright (c) 2013 Ryan Schroeder. All rights reserved.
//

#import "StackedImageView.h"
#import "SlidingImageView.h"
#import "ImageStack.h"
#import "Card.h"
#import <SDWebImage/UIImageView+WebCache.h>

#define IMAGE_OFFSET 27
#define IMAGE_HEIGHT 285
#define IMAGE_WIDTH 200

@interface StackedImageView () <UIScrollViewDelegate>

@property (nonatomic) NSArray *cards;
@property (nonatomic) NSArray *imageViews;
@property (nonatomic) CGFloat startingContentOffset;
@property (nonatomic, getter = isConfiguringImages) BOOL configuringImages;

@end

@implementation StackedImageView

- (void)setImageStack:(ImageStack *)imageStack
{
    self.cards = imageStack.cards;
    
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self configureViewWithImageStack:imageStack];
    [self displayImages];
    [self scrollToVisibleImage];
}

- (void)displayImages
{
    for (int i = self.imageViews.count - 1; i >= 0; i--) {
        SlidingImageView *imageView = self.imageViews[i];
        imageView.frame = [self imageFrame];
        NSInteger index = self.imageViews.count - i;
        imageView.originalY = imageView.frame.size.height * 2 + index * IMAGE_OFFSET;
        imageView.frame = CGRectOffset(imageView.frame, 0, imageView.originalY);
        
        [self addSubview:imageView];
    }
}

- (CGRect)imageFrame
{
    return CGRectMake(0, 0, self.frame.size.width, self.frame.size.width * IMAGE_HEIGHT / IMAGE_WIDTH);
}

- (void)scrollToVisibleImage
{
    [self setContentOffset:CGPointMake(0, self.startingContentOffset - self.visibleImageIndex * IMAGE_OFFSET) animated:NO];
    if (self.visibleImageIndex != 0 && self.isConfiguringImages) {
        [self updateImagesAnimated:NO];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.visibleImageIndex == 0 && self.isConfiguringImages) {
        self.configuringImages = NO;
        return;
    }
    
    [self preventDownScrollIfOnLastCard:scrollView.contentOffset.y];
    
    if (self.isConfiguringImages) {
        [self updateImagesAnimated:NO];
        self.configuringImages = NO;
    } else {
        [self updateImagesAnimated:YES];
    }
}

- (void)preventDownScrollIfOnLastCard:(CGFloat)scrollViewY
{
    CGFloat lastCardY = self.startingContentOffset - self.imageViews.count * IMAGE_OFFSET;
    if (scrollViewY < lastCardY) {
        [self setContentOffset:CGPointMake(0, lastCardY + 1) animated:NO];
    }
}

- (void)updateImagesAnimated:(BOOL)animated
{
    for (int i = 0; i < self.imageViews.count; i++) {
        [self updateImageAtIndex:i animated:animated];
    }
}

- (void)updateImageAtIndex:(NSInteger)index animated:(BOOL)animated
{
    SlidingImageView *image = self.imageViews[index];
    
    NSInteger offset = floor((self.startingContentOffset - self.contentOffset.y) / IMAGE_OFFSET);
    BOOL slideAnimationDidOccur = NO;
    
    if (offset > index && index != self.imageViews.count - 1) {
        slideAnimationDidOccur = [image slideDownAnimated:animated];
    } else if (offset < index) {
        slideAnimationDidOccur = [image slideUpAnimated:animated];
    }
    
    if (offset <= 0) {
        offset = 0;
    } else if (offset >= self.imageViews.count) {
        offset = self.imageViews.count - 1;
    }
    
    if (slideAnimationDidOccur) {
        self.visibleImageIndex = offset;
    }
}

#pragma mark - configure methods

- (void)configureViewWithImageStack:(ImageStack *)imageStack
{
    self.configuringImages = YES;
    
    NSMutableArray *slidingImageViews = [[NSMutableArray alloc] init];
    
    for (Card *card in self.cards) {
        UIImageView *imageView = [UIImageView new];
        [imageView setImageWithURL:card.smallImageURL placeholderImage:nil];
        
        SlidingImageView *slidingImageView = [[SlidingImageView alloc] initWithImage:imageView.image];
        [slidingImageViews addObject:slidingImageView];
    }
    
    self.imageViews = [slidingImageViews copy];
    
    // Size of all the images stacked up
    self.contentSize = CGSizeMake(self.frame.size.width,
                                  [self.imageViews[0] size].height * 2 + (self.imageViews.count * IMAGE_OFFSET));
    
    // Scroll to bottom of the list
    self.startingContentOffset = self.contentSize.height - self.frame.size.height;
}

#pragma mark - custom inits

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    self.delegate = self;
    [self setShowsVerticalScrollIndicator:NO];
    [self setShowsHorizontalScrollIndicator:NO];
    
    return self;
}

@end