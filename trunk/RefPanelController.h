#import <Cocoa/Cocoa.h>
#import "CocoaLib/PaletteWindowController.h"

@interface RefPanelController : PaletteWindowController
{
    IBOutlet id reloadButton;

	NSTimer *reloadTimer;
	BOOL isWorkedReloadTimer;
}

- (void)setReloadTimer;
- (void)temporaryStopReloadTimer;
- (void)restartReloadTimer;

@end
