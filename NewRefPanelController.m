#import "AppController.h"
#import "NewRefPanelController.h"
#import "miClient.h"
#import <CoreServices/CoreServices.h>
#import "CocoaLib/StringExtra.h"

#define useLog 0

extern id EditorClient;

//const ItemCount		kMaxErrors= 10;
//const ItemCount		kMaxFeatures= 100;

@implementation NewRefPanelController

- (IBAction)forceReload:(id)sender
{
	[dataController watchEditorWithReloading:YES];
}

- (void)periodicReload:(NSTimer *)theTimer
{
	if ([[self window] isVisible] && ![self isCollapsed]) {
		[dataController watchEditorWithReloading:NO];
	}
}

- (void)restartReloadTimer
{
	if (isWorkedReloadTimer) {
		[self setReloadTimer];
	}
}

- (void)temporaryStopReloadTimer
{
	if (reloadTimer != nil) {
		[reloadTimer invalidate];
		[reloadTimer release];
		reloadTimer = nil;		
		isWorkedReloadTimer = YES;
	}
	else {
		isWorkedReloadTimer = NO;
	}
}

- (void)setReloadTimer
{
#if useLog
	NSLog(@"setReloadTimer");
#endif
	if (reloadTimer == nil) {
		reloadTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self 
													 selector:@selector(periodicReload:) 
													 userInfo:nil repeats:YES];
		[reloadTimer retain];

	} 
	else if (![reloadTimer isValid]) {
		[reloadTimer invalidate];
		[reloadTimer release];
		reloadTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self 
													 selector:@selector(periodicReload:) 
													 userInfo:nil repeats:YES];
		[reloadTimer retain];
	}
}

- (IBAction)showWindow:(id)sender
{
	[super showWindow:self];
	[self setReloadTimer];
	[dataController watchEditorWithReloading:NO];
}

- (void)awakeFromNib
{
	[self setFrameName:@"ReferencePalettePalette"];
	[self setApplicationsFloatingOnFromDefaultName:@"ReferencePaletteApplicationsFloatingOn"];
	[self useFloating];
	[self useWindowCollapse];
}

- (BOOL)windowShouldClose:(id)sender
{

	if (reloadTimer != nil) {
		[reloadTimer invalidate];
		[reloadTimer release];
		reloadTimer = nil;
	}

	return [super windowShouldClose:sender];
	
	/* To support AppleScript Studio of MacOS 10.4 */
	[[self window] orderOut:self];
	return NO;
}

@end

