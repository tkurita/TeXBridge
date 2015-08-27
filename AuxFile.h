#import <Cocoa/Cocoa.h>
#import "TeXDocument.h"

@interface AuxFile : NSObject

@property NSString *basename;
@property TeXDocument *texDocument;
@property NSString *auxFilePath;
@property NSMutableArray *labelsFromAux;
@property NSMutableArray *labelsFromEditor;
@property NSDate *checkedTime;
@property NSUInteger texDocumentSize;
@property NSTreeNode *treeNodeRef;

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