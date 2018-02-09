//
//  SourceKitObjectTests.swift
//  SourceKitten
//
//  Created by Norio Nomura on 2/7/18.
//  Copyright © 2018 SourceKitten. All rights reserved.
//

import SourceKittenFramework
import XCTest

class SourceKitObjectTests: XCTestCase {

    func testDescription() {
        let path = #file
        let line = 10
        let indentWidth = 4
        let useTabs = true
        let object: SourceKitObject = [
            "key.request": UID("source.request.editor.formattext"),
            "key.name": path,
            "key.line": line,
            "key.editor.format.options": [
                "key.editor.format.indentwidth": indentWidth,
                "key.editor.format.tabwidth": indentWidth,
                "key.editor.format.usetabs": useTabs ? 1 : 0
            ]
        ]
        let expected = """
            {
              key.request: source.request.editor.formattext,
              key.name: \"\(#file)\",
              key.line: 10,
              key.editor.format.options: {
                key.editor.format.indentwidth: \(indentWidth),
                key.editor.format.tabwidth: \(indentWidth),
                key.editor.format.usetabs: 1
              }
            }
            """
        XCTAssertEqual(object.description, expected)
    }
}

extension SourceKitObjectTests {
    static var allTests: [(String, (SourceKitObjectTests) -> () throws -> Void)] {
        return [
            ("testDescription", testDescription)
        ]
    }
}
