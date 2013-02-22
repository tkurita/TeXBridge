#import <Cocoa/Cocoa.h>
#import "CocoaLib/PaletteWindowController.h"
#import "ReferenceDataController.h"

@interface NewRefPanelController : PaletteWindowController
{
    IBOutlet id reloadButton;
	IBOutlet NSTreeController *treeController;
	IBOutlet ReferenceDataController *dataController;

	NSTimer *reloadTimer;
	BOOL isWorkedReloadTimer;
	
}

- (void)setReloadTimer;
- (void)temporaryStopReloadTimer;
- (void)restartReloadTimer;

@end
