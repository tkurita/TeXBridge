/* ToolPaletteController */

#import <Cocoa/Cocoa.h>
#import "PaletteWindowController.h"

@interface NewToolPaletteController : PaletteWindowController
{
    IBOutlet id statusLabel;
    IBOutlet NSView *helpButtonView;
}

@property (nonatomic) NSMutableDictionary *toolbarItems;

- (void)showStatusMessage:(NSString *)msg;

@end
