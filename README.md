# OCPRE

A simple Objective-C preprocessor for Swift-style string interpolation.

## What does it do?

In short:

	NSLog( @"my Foo \(self.foo) your foo \(otherObject.foo)" );

becomes:

	NSLog( @"my Foo %1$@ your foo %2$@", (self.foo), (otherObject.foo) );

Optionally, you can pass the --generate-localized-strings 1 option to instead turn it into:

	NSLog( NSLocalizedStringFromTable(@"FILENAME_ab32fg0099", @"Filename", @"my Foo %1$@ your foo %2$@"), (self.foo), (otherObject.foo) );

and also generate a Filename.strings file that contains

	"FILENAME_ab32fg0099" = "my Foo %1$@ your foo %2$@";

(this, of course, works with multiple strings). The hex number is the string's hash, 
so should in practice be fairly stable unless the original string changes (in which case
you'll want to re-localize anyway)


## What is this for?

Add Swift-style string interpolation to Objective-C, but do it in a localizable fashion.


## License

	Copyright 2017 by Uli Kusterer.
	
	This software is provided 'as-is', without any express or implied
	warranty. In no event will the authors be held liable for any damages
	arising from the use of this software.
	
	Permission is granted to anyone to use this software for any purpose,
	including commercial applications, and to alter it and redistribute it
	freely, subject to the following restrictions:
	
	1. The origin of this software must not be misrepresented; you must not
	claim that you wrote the original software. If you use this software
	in a product, an acknowledgment in the product documentation would be
	appreciated but is not required.
	
	2. Altered source versions must be plainly marked as such, and must not be
	misrepresented as being the original software.
	
	3. This notice may not be removed or altered from any source
	distribution.
