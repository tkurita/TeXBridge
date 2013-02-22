#import <Cocoa/Cocoa.h>
#import "TeXDocument.h"

@interface AuxFile : NSObject {
	NSTreeNode *treeNode;
	NSString *basename;
	NSImage *nodeIcon;
	TeXDocument *texDocument;
	NSString *auxFilePath;
	NSMutableArray *labelsFromAux;
	NSMutableArray *labelsFromEditor;
	NSDate *checkedTime;
	NSUInteger texDocumentSize;
}

@property (retain) NSString *basename;
@property (retain) NSImage *nodeIcon;
@property (retain) TeXDocument *texDocument;
@property (retain) NSString *auxFilePath;
@property (retain) NSMutableArray *labelsFromAux;
@property (retain) NSMutableArray *labelsFromEditor;
@property (retain) NSDate *checkedTime;
@property NSUInteger texDocumentSize;

+ (AuxFile *)auxFileWithTexDocument:(TeXDocument *)aTeXDocument;
+ (AuxFile *)auxFileWithPath:(NSString *)path textEncoding:(NSString *)encodingName;
- (NSTreeNode *)treeNode;
- (BOOL)hasTreeNode;
- (BOOL)hasMaster;
- (void)checkAuxFile;
- (NSString *)readAuxFileReturningError:(NSError **)error;
- (void)addLabelFromAux:(NSString *)labelName referenceName:(NSString *)refName;
- (void)addLabelFromEditor:(NSString *)labelNamel;
- (void)addChildAuxFile:(AuxFile *)childAuxFile;
- (BOOL)hasLabel:(NSString *)labelName;
- (BOOL)findLabelsFromEditorWithForceUpdate:(BOOL)forceUpdate;
- (void)insertIntoTree:(NSTreeController *)treeController atIndexPath:(NSIndexPath *)indexPath;
- (void)updateLabelsFromEditor;

// methods for outline
- (NSString *)name;
- (NSString *)referenceName;
@end

NSArray *orderdEncodingCandidates(NSString *firstCandidateName);