#import "LabelDatum.h"

@implementation LabelDatum

@synthesize name;
@synthesize referenceName;
@synthesize nodeIcon;

- (void)dealloc
{
	[name release];
	[referenceName release];
	[nodeIcon release];
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
