#import "LabelDatum.h"

@implementation LabelDatum

@synthesize name;
@synthesize referenceName;

- (NSImage *)nodeIcon
{
	static NSImage *nodeIcon = nil;
	if (!nodeIcon) nodeIcon = [NSImage imageNamed:@"tag-gray-16.png"];
	return nodeIcon;
}

- (void)dealloc
{
	[name release];
	[referenceName release];
	[super dealloc];
}

+ (LabelDatum *)labelDatumWithName:(NSString *)aName referenceName:(NSString *)aRefName
{
	LabelDatum *result = [[LabelDatum new] autorelease];
	result.name = aName;
	result.referenceName = aRefName;
	return result;
}

- (NSTreeNode *)treeNode
{
	if (! treeNode) {
		treeNode = [NSTreeNode treeNodeWithRepresentedObject:self];
	}
	return treeNode;
}

@end
