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
- (IBAction)forceReload:(id)sender;

- (void)setReloadTimer;
- (void)temporaryStopReloadTimer;
- (void)restartReloadTimer;
- (void)rebuildLabelsFromAux:(NSString *)texFilePath textEncoding:(NSString *)encodingName;
@end
