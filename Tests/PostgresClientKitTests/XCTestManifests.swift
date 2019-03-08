import XCTest

extension LoggingTest {
    static let __allTests = [
        ("test", test),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(LoggingTest.__allTests),
    ]
}
#endif
