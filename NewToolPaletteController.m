#import "NewToolPaletteController.h"

#define useLog 0
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
    NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	[user_defaults setBool:[self isOpened] forKey:@"IsOpenedToolPalette"];
	[super applicationWillTerminate:aNotification];
}


- (void)awakeFromNib
{
	[self setFrameName:@"NewToolPalette"];
	[self bindApplicationsFloatingOnForKey:@"ToolPaletteApplicationsFloatingOn"];
	[self useFloating];
	[self useWindowCollapse];
    [self setCollapsedStateName:@"IsCollapsedToolPalette"];
	[self.window setShowsToolbarButton:NO];
}

- (void)showStatusMessage:(NSString *)msg
{
	[statusLabel setStringValue:msg];
	[self.window displayIfNeeded];
}

@end
