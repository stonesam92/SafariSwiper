#import <UIKit/UIKit.h>
#import "interface.h"
#import "CKBlurView.h"
#import <QuartzCore/QuartzCore.h>

extern NSString * const kCAFilterGaussianBlur;

%hook TabController
%new
- (TabDocument *)tabInDirection:(SSTabChangeDirection)direction {
    NSArray *currentTabs = [self currentTabDocuments];
    TabDocument *activeTab = [self activeTabDocument];
    int currentIndex = [currentTabs indexOfObject:activeTab];
    int targetIndex = currentIndex + (direction == SSDirectionLeft ? -1 : 1);
    if (targetIndex == -1 || targetIndex == currentTabs.count) {
        return nil;
    }
    return currentTabs[targetIndex];
}

%new
- (BOOL)canSwitchTabInDirection:(SSTabChangeDirection)direction {
    return [self tabInDirection:direction] != nil;
}

%new
- (void)switchTabInDirection:(SSTabChangeDirection)direction {
    TabDocument *newTab = [self tabInDirection:direction];
    [self setActiveTabDocument:newTab animated:NO];
}
%end

%hook BrowserToolbar

- (BrowserToolbar *)initWithPlacement:(long long)arg1 {
    self = %orig;
    BrowserController *bc = [%c(BrowserController) sharedBrowserController];
    UIPanGestureRecognizer *gr = [[UIPanGestureRecognizer alloc] initWithTarget:bc
                                                                         action:@selector(didPan:)];
    [gr addTarget:self action:@selector(didPan:)];
    [self addGestureRecognizer:gr];
    [self setActionEnabled:NO];
    [gr release];
    return self;
}

%new
- (void)didPan:(UIPanGestureRecognizer *)sender {
    UIBarButtonItem *bookmarks = MSHookIvar<UIBarButtonItem *>(self, "_bookmarksItem");
    UIBarButtonItem *newTab = MSHookIvar<UIBarButtonItem *>(self, "_addTabItem");
    if (sender.state == UIGestureRecognizerStateCancelled ||
            sender.state == UIGestureRecognizerStateEnded ||
            sender.state == UIGestureRecognizerStateFailed) {
        bookmarks.enabled = YES;
        newTab.enabled = YES;
        [self setActionEnabled:YES];
    } else {
        bookmarks.enabled = NO;
        newTab.enabled = NO;
        [self setActionEnabled:NO];
    }
}

%end

%hook BrowserController
%new
- (void)didPan:(UIPanGestureRecognizer *)gr {
    UIView *pageView = MSHookIvar<UIView *>(self, "_pageView");
    CGPoint translation = [gr translationInView:gr.view];
    SSTabChangeDirection direction = translation.x < 0 ? SSDirectionRight : SSDirectionLeft;
    CGRect newFrame = pageView.frame;
    [self setupOverlays];

    if (![self.tabController canSwitchTabInDirection:direction]) {
        return;
    } else if (gr.state == UIGestureRecognizerStateCancelled ||
            gr.state == UIGestureRecognizerStateEnded ||
            gr.state == UIGestureRecognizerStateFailed) {
        newFrame.origin.x = 0;
        [UIView animateWithDuration:0.2
                        animations:^{
                            pageView.frame = newFrame;
                            }];
    } else if (ABS(translation.x) > pageView.frame.size.width * 0.45) {
        gr.enabled = NO;
        [self.tabController switchTabInDirection:direction];
        newFrame.origin.x = 0;
        [UIView animateWithDuration:0.2
                        animations:^{
                            pageView.frame = newFrame;
                        }
                        completion:^(BOOL finished) {
                            gr.enabled = YES;
                       }];
    } else {
        newFrame.origin.x = translation.x * 1.2;
        pageView.frame = newFrame;
    }
}

%new
- (void)setupOverlays {
    [[UIApplication sharedApplication] _setApplicationIsOpaque:NO];
    [UIApplication sharedApplication].keyWindow.backgroundColor = [UIColor clearColor];

    UIView *pageView = MSHookIvar<UIView *>(self, "_pageView");
    for (UIView *view in pageView.subviews) {
        if ([view isKindOfClass:[UIScrollView class]])
            view.clipsToBounds = YES;
    }
    return;
}

%end

%hook MobileSafariWindow

+ (Class)layerClass {
    return [CABackdropLayer class];
}

- (id)initWithFrame:(CGRect)frame {
    self = %orig;
    [self commonInit];
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = %orig;
    [self commonInit];
    return self;
}

%new
- (void)commonInit {
    CKBlurView *blurView = [[CKBlurView alloc] initWithFrame:self.bounds];
    blurView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:blurView];
    [self sendSubviewToBack:blurView];
    for (NSString *constraintString in @[@"|-(0)-[blurView]-(0)-|", @"V:|-(0)-[blurView]-(0)-|"]) {
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:constraintString 
                     options:0
                     metrics:nil
                       views:@{@"blurView" : blurView}]];
    }
}
%end
