#import "ToolPaletteController.h"
#import "miClient.h"

extern id EditorClient;

@implementation ToolPaletteController

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)proposedFrameSize
{
	NSRect currentRect = [sender frame];
	return currentRect.size;
}

- (void)awakeFromNib
{
	[self setFrameName:@"ToolPalette"];
	[self bindApplicationsFloatingOnForKey:@"ToolPaletteApplicationsFloatingOn"];
	[self useFloating];
	[self useWindowCollapse];
}

@end
