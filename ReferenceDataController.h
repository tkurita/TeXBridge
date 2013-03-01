#import <Cocoa/Cocoa.h>
#import "AuxFile.h"

@interface ReferenceDataController : NSObject {
	IBOutlet NSTreeController *treeController;
	IBOutlet NSOutlineView *outlineView;
	IBOutlet id window;
	AuxFile *unsavedAuxFile;
	NSTreeNode *rootNode;
}

@property (retain) NSTreeNode *rootNode;
@property (retain) AuxFile *unsavedAuxFile;

- (void)watchEditorWithReloading:(BOOL)reloading;
- (BOOL)rebuildLabelsFromAuxForDoc:(TeXDocument *)texDoc;
- (IBAction)removeSelection:(id)sender;
- (IBAction)clickAction:(id)sender;

@end
