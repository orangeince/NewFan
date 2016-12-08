import XCTest
@testable import NewFan

class NewFanTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(NewFan().text, "Hello, World!")
    }


    static var allTests : [(String, (NewFanTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
