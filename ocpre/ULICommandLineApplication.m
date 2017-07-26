//
//  ULICommandLineApplication.m
//  ocpre
//
//  Created by Uli Kusterer on 26.07.17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#include "ULICommandLineApplication.h"


@implementation ULICommandLineApplication

+(NSString*) syntaxForExecutablePath: (NSString*)inPath
{
	return @"";
}

-(BOOL) openFiles: (NSArray*)files
{
	for (NSString * currPath in files) {
		if (![self openFile: currPath])
		return NO;
	}
	
	return YES;
}


-(BOOL) openFile: (NSString*)inPath
{
	return NO;
}

@end


int ULICommandLineApplicationMain(Class mainClass, int argc, const char * argv[])
{
	@autoreleasepool {
		if( argc == 1 ) {
			NSLog( @"Syntax: %@", [mainClass syntaxForExecutablePath: [NSString stringWithUTF8String: argv[0]]] );
			return 0;
		}
		
		// Imitate Cocoa command line storage so we can use the same code to retrieve
		//	them we would use for Cocoa.
		NSMutableArray * files = [NSMutableArray array];
		NSString * currKey = nil;
		NSMutableDictionary * argDict = [NSMutableDictionary dictionary];
		for( int x = 1; x < argc; ++x ) {
			if( argv[x][0] == '-' ) {
				if( currKey ) {
					[argDict setObject: @"" forKey: currKey];
				}
				currKey = [NSString stringWithUTF8String: argv[x] +1];
			} else if( currKey ) {
				NSString * currValue = [NSString stringWithUTF8String: argv[x]];
				[argDict setObject: currValue forKey: currKey];
				currKey = nil;
			} else {
				[files addObject: [NSString stringWithUTF8String: argv[x]]];
			}
		}
		[[NSUserDefaults standardUserDefaults] setVolatileDomain: argDict forName: NSArgumentDomain];
		
		ULICommandLineApplication * app = [mainClass new];
		[app openFiles: files];
	}
	
	return 0;
}
