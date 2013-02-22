#import <Cocoa/Cocoa.h>
#import "AuxFile.h"

@interface ReferenceDataController : NSObject {
	IBOutlet NSTreeController *treeController;
	IBOutlet NSOutlineView *outlineView;
	NSMutableArray *contents;
	AuxFile *unsavedAuxFile;
	NSTreeNode *rootNode;
}

@property (retain) NSMutableArray *contents;
@property (retain) NSTreeNode *rootNode;
@property (retain) AuxFile *unsavedAuxFile;

- (void)watchEditorWithReloading:(BOOL)reloading;

@end
