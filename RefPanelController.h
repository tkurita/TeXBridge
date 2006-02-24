#import <Cocoa/Cocoa.h>
#import "PaletteWindowController.h"

@interface RefPanelController : PaletteWindowController
{
    IBOutlet id reloadButton;

	NSTimer *reloadTimer;
	BOOL isWorkedReloadTimer;
}

- (void)setReloadTimer;
- (void)temporaryStopReloadTimer;
- (void)restartReloadTimer;
- (BOOL)shouldUpdateVisibilityForApp:(NSString *)appName suggestion:(BOOL)shouldShow;

@end
