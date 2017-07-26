//
//  ULICommandLineApplication.h
//  ocpre
//
//  Created by Uli Kusterer on 26.07.17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ULICommandLineApplication : NSObject

+(NSString*) syntaxForExecutablePath: (NSString*)inPath;

-(BOOL) openFile: (NSString*)filePath;
-(BOOL) openFiles: (NSArray*)files;	// Calls -openFile: for each path in the array.

@end


int	ULICommandLineApplicationMain(Class mainClass, int argc, const char * argv[]);
