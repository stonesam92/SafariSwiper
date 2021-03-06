#import <UIKit/UIKit.h>
#import "interface.h"
#import "CKBlurView.h"
#import <QuartzCore/QuartzCore.h>
#import "substrate.h"

static BOOL tabLoopingEnabled = YES;
static float sensitivity = 1.0;

#define PREFS_LOCATION @"/var/mobile/Library/Preferences/com.samstone.safariswiper.plist"

%hook TabController
%new
- (TabDocument *)tabInDirection:(SSTabChangeDirection)direction {
    NSArray *currentTabs = [self currentTabDocuments];
    TabDocument *activeTab = [self activeTabDocument];
    int currentIndex = [currentTabs indexOfObject:activeTab];
    int targetIndex = currentIndex + (direction == SSDirectionLeft ? -1 : 1);

    if (targetIndex >= 0 && targetIndex < currentTabs.count) 
        return currentTabs[targetIndex];
    else if (tabLoopingEnabled && targetIndex == -1)
        return currentTabs[currentTabs.count-1];
    else if (tabLoopingEnabled && targetIndex == currentTabs.count)
        return currentTabs[0];
    else
        return nil;
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
- (UIView *)newTabView {
    UIView *newTabView;
    UIView *pageView = MSHookIvar<UIView *>(self, "_pageView");
    for (UIView *subview in pageView.subviews) {
        if ([subview isKindOfClass:[UIScrollView class]]) continue;
        if ([subview isKindOfClass:[%c(NavigationBar) class]]) continue;
        newTabView = subview;
    }

    return newTabView;
}

%new
- (void)didPan:(UIPanGestureRecognizer *)gr {
    UIView *pageView = MSHookIvar<UIView *>(self, "_scrollView").superview.superview;
    UIView *newTabView = nil;
    if (![[self.tabController activeTabDocument] URLString]) {
        newTabView = [self newTabView];
    }
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
                            newTabView.frame = newFrame;
                            }];
    } else if (ABS(translation.x * sensitivity) > pageView.frame.size.width * 0.5) {
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
        newFrame.origin.x = translation.x * sensitivity;
        pageView.frame = newFrame;
        newTabView.frame = newFrame;
    }
}

%new
- (void)setupOverlays {
    UIView *pageView = MSHookIvar<UIView *>(self, "_scrollView").superview;
    pageView.clipsToBounds = YES;
}

%end

%hook MobileSafariWindow
- (id)initWithFrame:(CGRect)frame {
    self = %orig;
    [self setBackgroundColor:[UIColor clearColor]];
    [[UIApplication sharedApplication] _setApplicationIsOpaque:NO];
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = %orig;
    [self setBackgroundColor:[UIColor clearColor]];
    [[UIApplication sharedApplication] _setApplicationIsOpaque:NO];
    return self;
}

- (void)setBackgroundColor:(UIColor *)color {
    %orig([UIColor clearColor]);
}
%end

%hook UIApplication
- (void)_setBackgroundStyle:(long long)arg1 {
    %orig(UIBackgroundStyleDarkTranslucent);
}
%end

//reload preferences 
void reloadSettings(void) {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREFS_LOCATION];
    NSNumber *sensitivityObj = prefs[@"sensitivity"];
    NSNumber *loopPages = prefs[@"loopPages"];
    sensitivity = sensitivityObj.floatValue;
    tabLoopingEnabled = loopPages.boolValue;
}

%ctor {
    reloadSettings();
    CFNotificationCenterRef const center = CFNotificationCenterGetDarwinNotifyCenter();
    CFStringRef identifier = (__bridge CFStringRef)@"com.samstone.safariswiper";
    CFNotificationCenterAddObserver(center, NULL, (CFNotificationCallback)reloadSettings, 
            identifier, NULL, CFNotificationSuspensionBehaviorCoalesce);
}
