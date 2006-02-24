/* ToolPaletteController */

#import <Cocoa/Cocoa.h>
#import "PaletteWindowController.h"

@interface ToolPaletteController : PaletteWindowController
{
}

- (BOOL)shouldUpdateVisibilityForApp:(NSString *)appName suggestion:(BOOL)shouldShow;

@end
