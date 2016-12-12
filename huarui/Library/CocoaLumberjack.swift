// Software License Agreement (BSD License)
//
// Copyright (c) 2014-2015, Deusty, LLC
// All rights reserved.
//
// Redistribution and use of this software in source and binary forms,
// with or without modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice,
//   this list of conditions and the following disclaimer.
//
// * Neither the name of Deusty nor the names of its contributors may be used
//   to endorse or promote products derived from this software without specific
//   prior written permission of Deusty, LLC.

import Foundation
//import CocoaLumberjack

extension DDLogFlag {
    public static func fromLogLevel(logLevel: DDLogLevel) -> DDLogFlag {
        return DDLogFlag(rawValue: logLevel.rawValue)
    }
    
    ///returns the log level, or the lowest equivalant.
    public func toLogLevel() -> DDLogLevel {
        if let ourValid = DDLogLevel(rawValue: self.rawValue) {
            return ourValid
        } else {
            let logFlag = self
            if logFlag.intersect(.Verbose) == .Verbose {
                return .Verbose
            } else if logFlag.intersect(.Debug) == .Debug {
                return .Debug
            } else if logFlag.intersect(.Info) == .Info {
                return .Info
            } else if logFlag.intersect(.Warning) == .Warning {
                return .Warning
            } else if logFlag.intersect(.Error) == .Error {
                return .Error
            } else {
                return .Off
            }
        }
    }
}

extension DDMultiFormatter {
    public var formatterArray: [DDLogFormatter] {
        return self.formatters as! [DDLogFormatter]
    }
}

public var defaultDebugLevel = DDLogLevel.Verbose

public func resetDefaultDebugLevel() {
    defaultDebugLevel = DDLogLevel.Verbose
}

public func SwiftLogMacro(isAsynchronous: Bool, level: DDLogLevel, flag flg: DDLogFlag, context: Int = 0, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, tag: AnyObject? = nil, @autoclosure string:  () -> String) {
    if level.rawValue & flg.rawValue != 0 {
        // Tell the DDLogMessage constructor to copy the C strings that get passed to it. Using string interpolation to prevent integer overflow warning when using StaticString.stringValue
        let logMessage = DDLogMessage(message: string(), level: level, flag: flg, context: context, file: "\(file)", function: "\(function)", line: line, tag: tag, options: [.CopyFile, .CopyFunction], timestamp: nil)
        DDLog.log(isAsynchronous, message: logMessage)
    }
}

public func DDLogDebug(@autoclosure logText:  () -> String, level: DDLogLevel = defaultDebugLevel, context: Int = 0, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, tag: AnyObject? = nil, asynchronous async: Bool = true) {
    SwiftLogMacro(async, level: level, flag: .Debug, context: context, file: file, function: function, line: line, tag: tag, string: logText)
}

public func DDLogInfo(@autoclosure logText:  () -> String, level: DDLogLevel = defaultDebugLevel, context: Int = 0, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, tag: AnyObject? = nil, asynchronous async: Bool = true) {
    SwiftLogMacro(async, level: level, flag: .Info, context: context, file: file, function: function, line: line, tag: tag, string: logText)
}

public func DDLogWarn(@autoclosure logText:  () -> String, level: DDLogLevel = defaultDebugLevel, context: Int = 0, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, tag: AnyObject? = nil, asynchronous async: Bool = true) {
    SwiftLogMacro(async, level: level, flag: .Warning, context: context, file: file, function: function, line: line, tag: tag, string: logText)
}

public func DDLogVerbose(@autoclosure logText:  () -> String, level: DDLogLevel = defaultDebugLevel, context: Int = 0, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, tag: AnyObject? = nil, asynchronous async: Bool = true) {
    SwiftLogMacro(async, level: level, flag: .Verbose, context: context, file: file, function: function, line: line, tag: tag, string: logText)
}

public func DDLogError(@autoclosure logText:  () -> String, level: DDLogLevel = defaultDebugLevel, context: Int = 0, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, tag: AnyObject? = nil, asynchronous async: Bool = true) {
    SwiftLogMacro(async, level: level, flag: .Error, context: context, file: file, function: function, line: line, tag: tag, string: logText)
}

/// Analogous to the C preprocessor macro THIS_FILE
public func CurrentFileName(fileName: StaticString = #file) -> String {
    // Using string interpolation to prevent integer overflow warning when using StaticString.stringValue
//    return "\(fileName)".lastPathComponent.stringByDeletingPathExtension
	return NSURL(fileURLWithPath: "\(fileName)").URLByDeletingLastPathComponent!.absoluteString!
}
