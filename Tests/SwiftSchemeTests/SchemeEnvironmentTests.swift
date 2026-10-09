import Testing
@testable import SwiftScheme


struct SchemeEnvironmentTests {
    
    @Test func test01() throws {
        var env = SchemeEnvironment<Int>()

        env.bind(name: "a", value: 5)
        env.bind(name: "b", value: 6)

        #expect(try env.value(name: "a") == 5)
        #expect(try env.value(name: "b") == 6)
    }

    @Test func test02() throws {
        var env = SchemeEnvironment<Int>()

        env.bind(name: "a", value: 5)
        env.pushRegion()
        env.bind(name: "a", value: 6)

        #expect(try env.value(name: "a") == 6)
        env.popRegion()
        #expect(try env.value(name: "a") == 5)
    }
}