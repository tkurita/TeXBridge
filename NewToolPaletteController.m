#import "NewToolPaletteController.h"

@implementation NewToolPaletteController

- (BOOL)windowShouldClose:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setBool:NO 
											forKey:@"IsOpenedToolPalette"];
	return [super windowShouldClose:sender];	
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"start applicationWillTerminate in NewToolPaletteController");
#endif	
	[[NSUserDefaults standardUserDefaults] setBool:[self isOpened] 
											forKey:@"IsOpenedToolPalette"];	
	[super applicationWillTerminate:aNotification];
}

- (void)awakeFromNib
{
	[self setFrameName:@"NewToolPalette"];
	[self bindApplicationsFloatingOnForKey:@"ToolPaletteApplicationsFloatingOn"];
	[self useFloating];
	[self useWindowCollapse];
	[self.window setShowsToolbarButton:NO];
}

- (void)showStatusMessage:(NSString *)msg
{
	[statusLabel setStringValue:msg];
	[self.window displayIfNeeded];
}

@end
