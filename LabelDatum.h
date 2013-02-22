#import <Cocoa/Cocoa.h>

@interface LabelDatum : NSObject {
	NSTreeNode *treeNode;
	NSString *name;
	NSString *referenceName;
	NSImage *nodeIcon;
}

@property (retain) NSString *name;
@property (retain) NSString *referenceName;
@property (retain) NSImage *nodeIcon;


+ (LabelDatum *)labelDatumWithName:(NSString *)aName referenceName:(NSString *)aRefName;
- (NSTreeNode *)treeNode;

@end
