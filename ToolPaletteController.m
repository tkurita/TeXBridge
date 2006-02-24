#import "ToolPaletteController.h"
#import "miClient.h"

extern id EditorClient;

@implementation ToolPaletteController

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
