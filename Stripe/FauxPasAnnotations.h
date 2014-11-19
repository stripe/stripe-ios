//
//  FauxPasAnnotations.h
//  ---
//
//  This file defines macros that can be used to suppress
//  specific Faux Pas diagnostics within desired units of
//  code.
//
//  The arguments to the macros should be the short names of
//  the rules whose diagnostics should be suppressed. The
//  suppression macros should be present _inside_ whichever
//  code entity they refer to. For example, if you wish
//  to suppress diagnostics from the `NSLogUsed` and
//  `DotSyntax` rules within an Objective-C method, you
//  would do this:
//
//      - (void) myMethod {
//          FAUXPAS_IGNORED_IN_METHOD(NSLogUsed, DotSyntax)
//
//          NSLog(@"Hello world from %@", self.class);
//      }
//
//  The FAUXPAS_IGNORED() macro refers to the innermost
//  code entity it is contained in (an Obj-C method, a C
//  function, or an Obj-C class). This macro cannot be used
//  to suppress diagnostics within the whole file. For that,
//  use the more explicit FAUXPAS_IGNORED_IN_FILE() macro.
//
//  ---
//  http://fauxpasapp.com
//

#pragma once

#define FAUXPAS_IGNORED(...)
#define FAUXPAS_IGNORED_IN_FILE(...)
#define FAUXPAS_IGNORED_IN_METHOD(...)
#define FAUXPAS_IGNORED_IN_FUNCTION(...)
#define FAUXPAS_IGNORED_IN_CLASS(...)
#define FAUXPAS_IGNORED_ON_LINE(...)

// CamelCase variants:
#define FauxPasIgnored(...)
#define FauxPasIgnoredInFile(...)
#define FauxPasIgnoredInMethod(...)
#define FauxPasIgnoredInFunction(...)
#define FauxPasIgnoredInClass(...)
#define FauxPasIgnoredOnLine(...)

// snake_case variants:
#define fauxpas_ignored(...)
#define fauxpas_ignored_in_file(...)
#define fauxpas_ignored_in_method(...)
#define fauxpas_ignored_in_function(...)
#define fauxpas_ignored_in_class(...)
#define fauxpas_ignored_on_line(...)
