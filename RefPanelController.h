#import <Cocoa/Cocoa.h>
#import "PaletteWindowController.h"

@interface RefPanelController : PaletteWindowController
{
    IBOutlet id reloadButton;
	NSTimer *reloadTimer;
}
@end
