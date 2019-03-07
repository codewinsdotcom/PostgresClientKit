import XCTest

extension PostgresClientKitTests {
    static let __allTests = [
        ("testExample", testExample),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(PostgresClientKitTests.__allTests),
    ]
}
#endif
