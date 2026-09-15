//
//  JSHandlerCompatible.swift
//  BleBrowser
//
//  The allowed data types to be handed natively back to the webkit javascript
//  runtime are
//
//      NSNumber, NSString, NSDate, NSArray, NSDictionary, and NSNull
//
//  as documented in
//  developer.apple.com/documentation/webkit/wkscriptmessagehandlerwithreply/usercontentcontroller(_:didreceive:replyhandler:)

import Foundation
import CoreBluetooth


protocol JSHandlerCompatible {
    func forJSHandler() -> Any
}
extension Double: JSHandlerCompatible {
    func forJSHandler() -> Any {
        return self
    }
}
extension Int: JSHandlerCompatible {
    func forJSHandler() -> Any {
        return self
    }
}
extension String: JSHandlerCompatible {
    func forJSHandler() -> Any {
        return self
    }
}
extension Bool: JSHandlerCompatible {
    func forJSHandler() -> Any {
        return self
    }
}
extension CBUUID: JSHandlerCompatible {
    func forJSHandler() -> Any {
        return self.uuidString
    }
}
extension Array: JSHandlerCompatible {
    func forJSHandler() -> Any {
        return self.map{($0 as! JSHandlerCompatible).forJSHandler()}
    }
}

extension Dictionary: JSHandlerCompatible {
    func forJSHandler() -> Any {
        let cleanDictionary: [String: Any] = self.reduce(into: [:]) { (result, element) in
            let (key, value) = element
            result[key as! String] = (value as! JSHandlerCompatible).forJSHandler()
        }
        return cleanDictionary
    }
}

extension Data: JSHandlerCompatible {
    func forJSHandler() -> Any {
        return Array(self)
    }
}
