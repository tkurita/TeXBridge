#import <Cocoa/Cocoa.h>
#import "TeXDocument.h"

@interface AuxFile : NSObject {
	NSTreeNode *treeNode;
	NSString *basename;
	TeXDocument *texDocument;
	NSString *auxFilePath;
	NSMutableArray *labelsFromAux;
	NSMutableArray *labelsFromEditor;
	NSDate *checkedTime;
	NSUInteger texDocumentSize;
}

@property (retain) NSString *basename;
@property (retain) TeXDocument *texDocument;
@property (retain) NSString *auxFilePath;
@property (retain) NSMutableArray *labelsFromAux;
@property (retain) NSMutableArray *labelsFromEditor;
@property (retain) NSDate *checkedTime;
@property NSUInteger texDocumentSize;

+ (AuxFile *)auxFileWithTexDocument:(TeXDocument *)aTeXDocument;
+ (AuxFile *)auxFileWithPath:(NSString *)anAuxFilePath textEncoding:(NSString *)encodingName;
- (NSTreeNode *)treeNode;
- (BOOL)hasTreeNode;
- (BOOL)hasMaster;
- (BOOL)checkAuxFile;
- (NSString *)readAuxFileReturningError:(NSError **)error;
- (void)addLabelFromAux:(NSString *)labelName referenceName:(NSString *)refName;
- (void)addLabelFromEditor:(NSString *)labelNamel;
- (void)addChildAuxFile:(AuxFile *)childAuxFile;
- (BOOL)hasLabel:(NSString *)labelName;
- (void)clearLabelsFromEditor;
- (void)clearLabelsFromEditorRecursively:(BOOL)recursively;
- (BOOL)findLabelsFromEditorWithForceUpdate:(BOOL)forceUpdate;
//- (void)insertIntoTree:(NSTreeController *)treeController atIndexPath:(NSIndexPath *)indexPath;
- (void)updateLabelsFromEditor;
- (void)updateChildren;
- (BOOL)parseAuxFile;
- (void)remove;

// methods for outline
- (NSString *)name;
- (NSString *)referenceName;
- (NSImage *)nodeIcon;
@end

NSArray *orderdEncodingCandidates(NSString *firstCandidateName);