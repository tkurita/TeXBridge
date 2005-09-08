#import "RefPanelController.h"

#define useLog 0

@implementation RefPanelController
- (void)pushReloadButton:(NSTimer *)theTimer
{
#if useLog
	NSLog(@"pushReloadButton");
#endif
	if ([[self window] isVisible]) {
		NSLog(@"pushReloadButton action");
		[reloadButton performClick:self];
	}
}

- (void)setReloadTimer
{
#if useLog
	NSLog(@"setReloadTimer");
#endif
	if (reloadTimer != nil) {
		[reloadTimer invalidate];
	}
	[reloadTimer release];
	reloadTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(pushReloadButton:) userInfo:nil repeats:YES];
	[reloadTimer retain];
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

@end

