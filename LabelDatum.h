#import <Cocoa/Cocoa.h>

@interface LabelDatum : NSObject

@property NSString *name;
@property NSString *referenceName;
@property NSTreeNode *treeNodeRef;

+ (LabelDatum *)labelDatumWithName:(NSString *)aName referenceName:(NSString *)aRefName;
- (NSTreeNode *)treeNode;
- (NSImage *)nodeIcon;

@end
