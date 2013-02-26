#import "NewToolPaletteController.h"

@implementation NewToolPaletteController
/*
- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)proposedFrameSize
{
	NSRect currentRect = [sender frame];
	return currentRect.size;
}
*/
- (BOOL)windowShouldClose:(id)sender
{
	[super windowShouldClose:sender];
	
	/* To support AppleScript Studio of MacOS 10.4 */
	[[self window] orderOut:self];
	return NO;
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	[user_defaults setBool:[self isOpened] forKey:@"IsOpenedToolPalette"];
}

- (void)awakeFromNib
{
	[self setFrameName:@"NewToolPalette"];
	[self bindApplicationsFloatingOnForKey:@"ToolPaletteApplicationsFloatingOn"];
	[self useFloating];
	[self useWindowCollapse];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(applicationWillTerminate:)
												 name:NSApplicationWillTerminateNotification
											   object:NSApp];
	[self.window setShowsToolbarButton:NO];
}

- (void)showStatusMessage:(NSString *)msg
{
	[statusLabel setStringValue:msg];
	[self.window displayIfNeeded];
}

@end
