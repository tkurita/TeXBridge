#import "RefPanelController.h"

#define useLog 0

@implementation RefPanelController
- (void)pushReloadButton:(NSTimer *)theTimer
{
#if useLog
	NSLog(@"start pushReloadButton");
#endif
	if ([[self window] isVisible] && ![self isCollapsed]) {
#if useLog
		NSLog(@"pushReloadButton action");
#endif
		[reloadButton performClick:self];
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
		reloadTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(pushReloadButton:) userInfo:nil repeats:YES];
		[reloadTimer retain];

	} 
	else if (![reloadTimer isValid]) {
		[reloadTimer invalidate];
		[reloadTimer release];
		reloadTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(pushReloadButton:) userInfo:nil repeats:YES];
		[reloadTimer retain];
	}
}

- (IBAction)showWindow:(id)sender
{
	[super showWindow:self];
	[self setReloadTimer];

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

	[super windowShouldClose:sender];
	
	/* To support AppleScript Studio of MacOS 10.4 */
	[[self window] orderOut:self];
	return NO;
}
@end

