#import <Preferences/Preferences.h>

@interface SafariSwiperPrefsListController: PSListController {
}
@end

@implementation SafariSwiperPrefsListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"SafariSwiperPrefs" target:self] retain];
	}
	return _specifiers;
}
@end

// vim:ft=objc
