//
//  WebResponderChainTests.swift
//  WebResponderCore
//
//  Created by Brent Royal-Gordon on 7/1/15.
//  Copyright © 2015 Groundbreaking Software. All rights reserved.
//

import XCTest
import WebResponderCore

class WebResponderChainTests: XCTestCase {
    func testNoHelpers() {
        var ran = false
        let finalResponder = SimpleWebResponder { response, _, request, next in
            ran = true
        }
        let chain = finalResponder.withHelperResponders()
        
        XCTAssertTrue(chain === finalResponder, "withHelperResponders() returns self if there aren't any")
        XCTAssertTrue(chain.nextResponder == nil, "withHelperResponders() doesn't add any additional responders")
        
        chain.respond(SimpleHTTPResponse(), toRequest: SimpleHTTPRequest())
        XCTAssertTrue(ran, "Runs final responder")
    }
    
    func testHelperResponders() {
        var ran = false
        let helper = SimpleWebResponder { response, _, request, next in
            ran = true
            next.respond(response, toRequest: request)
        }
        let finalResponder = SimpleWebResponder(helperResponders: [helper]) { response, _, request, _ in }
        let chain = finalResponder.withHelperResponders()
        
        XCTAssertTrue(chain === helper, "Helper responders are inserted")
        XCTAssertTrue(chain.nextResponder === finalResponder, "Final responder is correct with helpers")
        
        chain.respond(SimpleHTTPResponse(), toRequest: SimpleHTTPRequest())
        XCTAssertTrue(ran, "Runs helper")
    }
    
    func testHelperRespondersMultiple() {
        var requestID: String?
        let helper = SimpleWebResponder { response, _, request, next in
            requestID = request.requestID
            next.respond(response, toRequest: request)
        }
        let finalResponder = SimpleWebResponder(helperResponders: [RequestIDHelper(), helper]) { response, _, request, _ in }
        let chain = finalResponder.withHelperResponders()
        
        XCTAssertTrue((chain.nextResponder as! WebResponderType).nextResponder === finalResponder, "Final responder is correct with helper responder")
        XCTAssertTrue(chain is RequestIDHelper, "Earlier helper responder inserted ahead of later helper responder")
        
        chain.respond(SimpleHTTPResponse(), toRequest: SimpleHTTPRequest())
        XCTAssertTrue(requestID != nil, "Helper runs in correct order")
    }
    
    func testHelperRespondersNested() {
        var requestID: String?
        let helper = SimpleWebResponder(helperResponders: [RequestIDHelper()]) { response, _, request, next in
            requestID = request.requestID
            next.respond(response, toRequest: request)
        }
        let finalResponder = SimpleWebResponder(helperResponders: [helper]) { response, _, request, _ in }
        let firstResponder = finalResponder.withHelperResponders()
        
        XCTAssertTrue((firstResponder.nextResponder as? WebResponderType)?.nextResponder === finalResponder, "Final responder is correct with helper responder")
        XCTAssertTrue(firstResponder is RequestIDHelper, "Nested helper responder inserted ahead of top-level one")
        
        firstResponder.respond(SimpleHTTPResponse(), toRequest: SimpleHTTPRequest())
        XCTAssertTrue(requestID != nil, "Helpers run in correct order")
    }
    
    func testCompleteChain() {
        class MockServer: WebResponderChainable {
            var nextResponder: WebResponderRespondable! = Tail()
            
            class Tail: WebResponderRespondable {
                var responded = false
                
                private func respond(response: HTTPResponseType, toRequest request: HTTPRequestType) {
                    responded = true
                }
                
                private func respond(response: HTTPResponseType, withError error: ErrorType, toRequest request: HTTPRequestType) {
                    responded = true
                }
            }
        }
        
        let server = MockServer()
        let serverTail = server.nextResponder as! MockServer.Tail
        
        let responder = SimpleWebResponder { response, error, request, next in
            next.respond(response, toRequest: request)
        }
        
        server.insertNextResponder(responder)
        XCTAssert(server.nextResponder === responder, "After insertion, server.nextResponder == responder")
        XCTAssert(responder.nextResponder === serverTail, "After insertion, responder.nextResponder === serverTail")
        
        server.nextResponder.respond(SimpleHTTPResponse(), toRequest: SimpleHTTPRequest())
        XCTAssertTrue(serverTail.responded, "Request passed through complete responder chain")
    }
    
//    func testResponderChainMutation() {
//        var finalResponderRequestID: String?
//        var middlewareRequestID: String?
//        
//        let middleware = SimpleWebMiddleware { response, _, request, next in
//            middlewareRequestID = request.requestID
//            next(request, response)
//        }
//        let finalResponder = SimpleWebResponder(requiredMiddleware: [middleware]) { response, request in
//            finalResponderRequestID = request.requestID
//        }
//        let chain = WebResponderChain(finalResponder: finalResponder)
//        
//        let requestIDMiddleware = RequestIDMiddleware()
//        
//        let rootRequest = SimpleHTTPRequest()
//        let rootResponse = SimpleHTTPResponse { _, _ in }
//        
//        chain.respond(rootResponse, toRequest: rootRequest)
//        XCTAssertNil(middlewareRequestID, "No requestID in middleware without request ID middleware installed")
//        XCTAssertNil(finalResponderRequestID, "No requestID in final without request ID midleware installed")
//        
//        chain.prependMiddleware(requestIDMiddleware)
//        
//        chain.respond(rootResponse, toRequest: rootRequest)
//        XCTAssertNotNil(middlewareRequestID, "Has requestID in middleware with request ID middleware prepended")
//        XCTAssertNotNil(finalResponderRequestID, "Has requestID in final with request ID midleware prepended")
//        
//        chain.removeMiddleware(requestIDMiddleware)
//        
//        chain.respond(rootResponse, toRequest: rootRequest)
//        XCTAssertNil(middlewareRequestID, "No requestID in middleware with request ID middleware removed")
//        XCTAssertNil(finalResponderRequestID, "No requestID in final with request ID midleware removed")
//        
//        chain.appendMiddleware(requestIDMiddleware)
//        
//        chain.respond(rootResponse, toRequest: rootRequest)
//        XCTAssertNil(middlewareRequestID, "No requestID in middleware with request ID middleware appended")
//        XCTAssertNotNil(finalResponderRequestID, "Has requestID in final with request ID midleware appended")
//        
//        chain.removeMiddleware(requestIDMiddleware)
//        chain.respond(rootResponse, toRequest: rootRequest)
//        XCTAssertNil(middlewareRequestID, "No requestID in middleware with request ID middleware removed near final responder")
//        XCTAssertNil(finalResponderRequestID, "No requestID in final with request ID midleware removed near final responder")
//        
//        chain.insertMiddleware(requestIDMiddleware, after: middleware)
//        
//        chain.respond(rootResponse, toRequest: rootRequest)
//        XCTAssertNil(middlewareRequestID, "No requestID in middleware with request ID middleware inserted after")
//        XCTAssertNotNil(finalResponderRequestID, "Has requestID in final with request ID midleware inserted after")
//    }
//    
//    func testResponderChainMutationFailures() {
//        func makeChain() -> (WebResponderChain, WebMiddlewareType, WebResponderType) {
//            let middleware = SimpleWebMiddleware { response, request, next in
//                next(request, response)
//            }
//            let finalResponder = SimpleWebResponder(requiredMiddleware: [middleware]) { response, request in
//            }
//            return (WebResponderChain(finalResponder: finalResponder), middleware, finalResponder)
//        }
//        
//        let (chain1, middleware1, _) = makeChain()
//        let (chain2, middleware2, _) = makeChain()
//        let otherMiddleware = RequestIDMiddleware()
//        
//        XCTAssertTrue(chain1.insertMiddleware(otherMiddleware, after: middleware1), "Valid insertMiddleware(_:after:) returns true")
//        
//        XCTAssertFalse(chain2.removeMiddleware(otherMiddleware), "Invalid removeMiddleware(_:) returns false")
//        XCTAssertTrue(chain1.removeMiddleware(otherMiddleware), "Valid removeMiddleware(_:) returns true")
//        
//        XCTAssertTrue(chain1.insertMiddleware(otherMiddleware, before: middleware1), "Valid insertMiddleware(_:before:) returns true")
//        XCTAssertTrue(chain1.removeMiddleware(otherMiddleware), "Valid removeMiddleware(_:) returns true")
//        
//        XCTAssertFalse(chain1.insertMiddleware(otherMiddleware, after: middleware2), "Invalid insertMiddleware(_:after:) returns false")
//        XCTAssertFalse(chain1.insertMiddleware(otherMiddleware, before: middleware2), "Invalid insertMiddleware(_:before:) returns false")
//    }
}
