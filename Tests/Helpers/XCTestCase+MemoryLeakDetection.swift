//
//  XCTestCase+MemoryLeakDetection.swift
//  Tests
//
//  Created by Fabio Mignogna on 06/03/2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation
import XCTest

extension XCTestCase {
	func trackForMemoryLeak(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
		addTeardownBlock { [weak instance] in
			XCTAssertNil(instance, "Instance should be deallocated. Potential memory leak!", file: file, line: line)
		}
	}
}
