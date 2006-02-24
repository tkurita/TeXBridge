/* PaletteWindowController */

#import <Cocoa/Cocoa.h>

@interface PaletteWindowController : NSWindowController
{
	BOOL isCollapsed;
	NSRect expandedRect;
	NSString *frameName;
	id contentViewBuffer;
	NSArray *applicationsFloatingOn;
	NSString *applicationsFloatingOnKeyPath;
	NSString *applicationsFloatingOnEntryName;
}
+ (void)setVisibilityController:(id)theObj;
+ (id)visibilityController;

- (BOOL)shouldUpdateVisibilityForApp:(NSString *)appName;
- (void)setVisibility:(BOOL)shouldShow;

//accessor methods
- (void)setFrameName:(NSString *)theName;
- (void)setApplicationsFloagingOn:(NSArray *)appList;
- (BOOL)isCollapsed;

//setup behavior
- (void)bindApplicationsFloatingOnForKey:(NSString *)theKeyPath;
- (void)setApplicationsFloatingOnFromDefaultName:(NSString *)entryName;
- (void)useWindowCollapse;
- (void)useFloating;

//methods for override
- (void)saveDefaults;

//private
- (void)collapseAction;
- (float)titleBarHeight;
- (void)toggleCollapseWithAnimate:(BOOL)flag;
- (void)willApplicationQuit:(NSNotification *)aNotification;
@end
