#import <Cocoa/Cocoa.h>
#import "CocoaLib/PaletteWindowController.h"
#import "ReferenceDataController.h"

@interface NewRefPanelController : PaletteWindowController
{
    IBOutlet id reloadButton;
	IBOutlet NSTreeController *treeController;
	IBOutlet ReferenceDataController *dataController;

	BOOL isWorkedReloadTimer;
}

@property NSTimer *reloadTimer;

- (IBAction)forceReload:(id)sender;
- (void)temporaryStopReloadTimer;
- (void)restartReloadTimer;
- (void)rebuildLabelsFromAux:(NSString *)texFilePath textEncoding:(NSString *)encodingName;
- (void)setupReloadTimer;
@end
