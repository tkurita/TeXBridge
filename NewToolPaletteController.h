/* ToolPaletteController */

#import <Cocoa/Cocoa.h>
#import "PaletteWindowController.h"

@interface NewToolPaletteController : PaletteWindowController
{
	IBOutlet id statusLabel;
}

- (void)showStatusMessage:(NSString *)msg;

@end
