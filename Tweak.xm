#import <UIKit/UIKit.h>
#import "interface.h"

static UIView *leftOverlay, *rightOverlay;

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
    if (sender.state == UIGestureRecognizerStateBegan) {
        bookmarks.enabled = NO;
        [self setActionEnabled:NO];
    } else if (sender.state == UIGestureRecognizerStateCancelled ||
            sender.state == UIGestureRecognizerStateEnded ||
            sender.state == UIGestureRecognizerStateFailed) {
        bookmarks.enabled = YES;
        [self setActionEnabled:YES];
    }
}


%end

%hook BrowserController
- (BrowserController *)init {
    self = %orig;
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(didRotate:)
                                                name:UIDeviceOrientationDidChangeNotification
                                              object:nil];
    return self;
}

%new
- (void)didRotate:(NSNotification *)notification {
    leftOverlay.frame = CGRectZero;
    rightOverlay.frame = CGRectZero;
}

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
    static dispatch_once_t onceToken;
    CGFloat sbHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    UIView *pageView = MSHookIvar<UIView *>(self, "_pageView");

    dispatch_once(&onceToken, ^{
        UIImage *texture = [UIImage imageWithContentsOfFile:@"/Library/Application Support/SafariSwiper/texture.png"];

        leftOverlay = [[UIView alloc] initWithFrame:CGRectZero];
        rightOverlay = [[UIView alloc] initWithFrame:CGRectZero];

        leftOverlay.backgroundColor = [[UIColor alloc] initWithPatternImage:texture];
        rightOverlay.backgroundColor = [[UIColor alloc] initWithPatternImage:texture];

        //leftOverlay.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];
        //rightOverlay.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];

        [pageView addSubview:leftOverlay];
        [pageView addSubview:rightOverlay];
    });

    CGRect leftFrame = pageView.bounds;
    CGRect rightFrame = pageView.bounds;

    leftFrame.origin.x = -leftFrame.size.width;
    leftFrame.origin.y = -sbHeight;
    leftFrame.size.height += sbHeight;

    rightFrame.origin.x = rightFrame.size.width;
    rightFrame.origin.y = -sbHeight;
    rightFrame.size.height += sbHeight;

    leftOverlay.frame = leftFrame;
    rightOverlay.frame = rightFrame;

    NSLog(@"setup views: %@", rightOverlay);

}

%end

