#import "LabelDatum.h"

@implementation LabelDatum

- (NSImage *)nodeIcon
{
	static NSImage *nodeIcon = nil;
	//if (!nodeIcon) nodeIcon = [NSImage imageNamed:@"tag-gray-16.png"];
	if (!nodeIcon) nodeIcon = [NSImage imageNamed:@"tag-blue-16.png"];
	return nodeIcon;
}

+ (LabelDatum *)labelDatumWithName:(NSString *)aName referenceName:(NSString *)aRefName
{
	LabelDatum *result = [LabelDatum new];
	result.name = aName;
	result.referenceName = aRefName;
	return result;
}

- (NSTreeNode *)treeNode
{
	if (! _treeNodeRef) {
		self.treeNodeRef = [NSTreeNode treeNodeWithRepresentedObject:self];
	}
	return _treeNodeRef;
}

@end
