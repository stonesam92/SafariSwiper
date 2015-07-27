
#define CGRectZero CGRectMake(0,0,0,0)

typedef enum {
    SSDirectionLeft,
    SSDirectionRight
} SSTabChangeDirection;

@interface TabDocument
- (NSString *)URLString;
@end

@interface BrowserToolbar : UIToolbar
- (void)setActionEnabled:(BOOL)enabled;
@end

@interface TabController : NSObject
- (TabDocument *)activeTabDocument;
- (NSArray *)currentTabDocuments;
- (TabDocument *)tabInDirection:(SSTabChangeDirection)direction;
- (BOOL)canSwitchTabInDirection:(SSTabChangeDirection)direction;
- (void)switchTabInDirection:(SSTabChangeDirection)direction;
- (void)setActiveTabDocument:(TabDocument *)document animated:(BOOL)animated;
@end

@interface BrowserController : NSObject
- (TabController *)tabController;
+ (id)sharedBrowserController;
- (void)setupOverlays;
- (UIView *)newTabView;
@end

@interface MobileSafariWindow : UIWindow
- (void)commonInit;
@end

@interface CABackdropLayer : CALayer
@end

typedef enum _UIBackgroundStyle {
	UIBackgroundStyleDefault,
	UIBackgroundStyleTransparent,
	UIBackgroundStyleLightBlur,
	UIBackgroundStyleDarkBlur,
	UIBackgroundStyleDarkTranslucent
} UIBackgroundStyle;
 
@interface UIApplication (UIBackgroundStyle)
- (void)_setBackgroundStyle:(UIBackgroundStyle)style;
- (void)_setApplicationIsOpaque:(BOOL)opaque;
@end
