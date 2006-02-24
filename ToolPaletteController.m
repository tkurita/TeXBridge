#import "ToolPaletteController.h"
#import "miClient.h"

extern id EditorClient;

@implementation ToolPaletteController

- (BOOL)shouldUpdateVisibilityForApp:(NSString *)appName suggestion:(BOOL)shouldShow
{
	if ([appName isEqualToString:@"mi"]) {
		NSString *theMode = [EditorClient currentDocumentMode];
		shouldShow = [[[NSUserDefaults standardUserDefaults] objectForKey:@"SupportedModes"]
				containsObject:theMode];
	}

	return shouldShow;
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)proposedFrameSize
{
	NSRect currentRect = [sender frame];
	return currentRect.size;
}

- (BOOL)windowShouldClose:(id)sender
{
	[super windowShouldClose:sender];
	
	/* To support AppleScript Studio of MacOS 10.4 */
	[[self window] orderOut:self];
	return NO;
}

- (void)awakeFromNib
{
	[self setFrameName:@"ToolPalette"];
	[self bindApplicationsFloatingOnForKey:@"ToolPaletteApplicationsFloatingOn"];
	[self useFloating];
	[self useWindowCollapse];
}

@end
