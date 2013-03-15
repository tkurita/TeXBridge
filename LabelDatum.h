#import <Cocoa/Cocoa.h>

@interface LabelDatum : NSObject {
	NSTreeNode *treeNode;
	NSString *name;
	NSString *referenceName;
}

@property (retain) NSString *name;
@property (retain) NSString *referenceName;

+ (LabelDatum *)labelDatumWithName:(NSString *)aName referenceName:(NSString *)aRefName;
- (NSTreeNode *)treeNode;
- (NSImage *)nodeIcon;

@end
