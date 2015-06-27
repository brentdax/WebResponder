//
//  CoreVersionResponder.swift
//  WebResponderCore
//
//  Created by Brent Royal-Gordon on 6/24/15.
//  Copyright © 2015 Groundbreaking Software. All rights reserved.
//

public class CoreVersionResponder: WebResponderType {
    public init() {}
    
    public func respond(response: HTTPResponseType, toRequest request: HTTPRequestType) {
        var unameResult = utsname()
        uname(&unameResult)
        let platform = withUnsafePointer(&unameResult.version) { tuplePointer in
            String.fromCString(UnsafePointer<Int8>(tuplePointer))!
        } 

        let version = WebResponderCoreVersionNumber
        
        response.status = .OK
        response.headers["Content-Type"] = ["text/html; charset=UTF-8"]
        response.body = HTTPBody(string: "<!DOCTYPE html><html><head><title>WebResponderCore</title><style>html { font-family: sans-serif; margin: 1em 25%; background-color: #eee } body { border: 1px solid #ddd; background-color: white; font-size: 1.2em/1.5em } dt { font-weight: bold } dd { margin: 0; padding: 0; margin-bottom: 0.5em; }</style></head><body><h1>WebResponderCore</h1><dl><dt>Version</dt><dd>\(version)</dd><dt>Platform</dt><dd>\(platform)</dd></dl></body></html>", codec: UTF8.self)
        
        response.respond()
    }
}
