//
//  UnicodeEncoderTests.swift
//  WebResponderCore
//
//  Created by Brent Royal-Gordon on 6/22/15.
//  Copyright © 2015 Groundbreaking Software. All rights reserved.
//

import XCTest
import WebResponderCore

func encode8(string: String) -> UnicodeEncoder<UTF8, String.UnicodeScalarView> {
    return UnicodeEncoder(string.unicodeScalars, codec: UTF8.self)
}

func encodeL(string: String) -> UnicodeEncoder<Latin1, String.UnicodeScalarView> {
    return UnicodeEncoder(string.unicodeScalars, codec: Latin1.self)
}

func encode16(string: String) -> UnicodeEncoder<UTF16, String.UnicodeScalarView> {
    return UnicodeEncoder(string.unicodeScalars, codec: UTF16.self)
}

func encode32(string: String) -> UnicodeEncoder<UTF32, String.UnicodeScalarView> {
    return UnicodeEncoder(string.unicodeScalars, codec: UTF32.self)
}

class UnicodeEncoderTests: XCTestCase {
    func testUTF8Encoding() {
        AssertElementsEqual(encode8("hello"), "hello".utf8, "UTF8: ASCII")
        AssertElementsEqual(encode8("\u{FEFF}"), [0xEF, 0xBB, 0xBF], "UTF8: Byte order marker")
        AssertElementsEqual(encode8("κόσμε"), "κόσμε".utf8, "UTF8: Basic multilingual plane")
        AssertElementsEqual(encode8("🜀🜁🜂🜃🜄"), "🜀🜁🜂🜃🜄".utf8, "UTF8: Extraplanar symbols")
    }
    
    func testLatin1Encoding() {
        AssertElementsEqual(encodeL("hello"), "hello".utf8, "Latin1: ASCII")
        AssertElementsEqual(encodeL("El Niño"), "El Niño".unicodeScalars.map { UInt8($0.value) }, "Latin1: High characters")
        AssertElementsEqual(encodeL("κόσμε"), "?????".utf8, "Latin1: Basic multilingual plane")
        AssertElementsEqual(encodeL("🜀🜁🜂🜃🜄"), "?????".utf8, "UTF8: Extraplanar symbols")
    }
    
    func testLatin1BOM() {
        AssertElementsEqual(encodeL("\u{FEFF}El Niño"), "El Niño".unicodeScalars.map { UInt8($0.value) }, "Latin1: Strips BOM")
    }
    
    func testLatin1UnknownCharacterHandler() {
        let defaultHandler = Latin1.unknownCharacterHandler
        Latin1.unknownCharacterHandler = { scalar in Array("[U+\(String(scalar.value, radix: 16))]".utf8) } 
        
        AssertElementsEqual(encodeL("κόσμε"), "[U+3ba][U+1f79][U+3c3][U+3bc][U+3b5]".utf8, "Latin1: unknownCharacterHandler")
        
        Latin1.unknownCharacterHandler = defaultHandler
    }
    
    func testUTF16Encoding() {
        AssertElementsEqual(encode16("hello"), "hello".utf8.flatMap { [0, $0] }, "UTF16: ASCII")
        AssertElementsEqual(encode16("\u{FEFF}"), [0xFE, 0xFF], "UTF16: Byte order marker")
        AssertElementsEqual(encode16("κόσμε"), [0x03, 0xba, 0x1f, 0x79, 0x03, 0xc3, 0x03, 0xbc, 0x03, 0xb5], "UTF16: Basic multilingual plane")
        AssertElementsEqual(encode16("🜀🜁🜂🜃🜄"), [0xd8, 0x3d, 0xdf, 0x00, 0xd8, 0x3d, 0xdf, 0x01, 0xd8, 0x3d, 0xdf, 0x02, 0xd8, 0x3d, 0xdf, 0x03, 0xd8, 0x3d, 0xdf, 0x04], "UTF16: Extraplanar symbols")
    }
    
    func testUTF32Encoding() {
        AssertElementsEqual(encode32("hello"), "hello".utf8.flatMap { [0, 0, 0, $0] }, "UTF32: ASCII")
        AssertElementsEqual(encode32("\u{FEFF}"), [0x00, 0x00, 0xFE, 0xFF], "UTF32: Byte order marker")
        AssertElementsEqual(encode32("κόσμε"), [0, 0, 0x03, 0xba, 0, 0, 0x1f, 0x79, 0, 0, 0x03, 0xc3, 0, 0, 0x03, 0xbc, 0, 0, 0x03, 0xb5], "UTF32: Basic multilingual plane")
        AssertElementsEqual(encode32("🜀🜁🜂🜃🜄"), [0x00, 0x01, 0xf7, 0x00, 0x00, 0x01, 0xf7, 0x01, 0x00, 0x01, 0xf7, 0x02, 0x00, 0x01, 0xf7, 0x03, 0x00, 0x01, 0xf7, 0x04], "UTF32: Extraplanar symbols")
    }
    
    func testUnderestimateCount() {
        XCTAssertEqual(encode8("hello").underestimateCount(), 5, "UTF-8 underestimateCount() accurate")
        XCTAssertEqual(encode16("hello").underestimateCount(), 10, "UTF-16 underestimateCount() accurate")
        XCTAssertEqual(encode32("hello").underestimateCount(), 20, "UTF-32 underestimateCount() accurate")
    }
}
