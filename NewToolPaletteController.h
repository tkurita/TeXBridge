/* ToolPaletteController */

#import <Cocoa/Cocoa.h>
#import "CocoaLib/PaletteWindowController.h"

@interface NewToolPaletteController : PaletteWindowController
{
	IBOutlet id statusLabel;
}

- (void)showStatusMessage:(NSString *)msg;

@end
