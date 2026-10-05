import Testing 
@testable import SwiftScheme







struct ParserTests {
    @Test func testDatum01() throws {
        let data: String = "(hello 1 2 a b 3)"
        var parser = Parser(lexer: PeekableLexer(data: data))
        let datum = try parser.parseDatum()
        #expect(datum?.kind == .list(value: [
            .init(start: 1, end: 6, kind: .symbol(value: "hello")),
            .init(start: 7, end: 8, kind: .number(value: 1)),
            .init(start: 9, end: 10, kind: .number(value: 2)),
            .init(start: 11, end: 12, kind: .symbol(value: "a")),
            .init(start: 13, end: 14, kind: .symbol(value: "b")),
            .init(start: 15, end: 16, kind: .number(value: 3)),
        ]))
    }

    @Test func testDatum02() throws {
        let data: String = "(lambda (x) (add x 1))"
        var parser = Parser(lexer: PeekableLexer(data: data))
        let datum = try parser.parseDatum()
        #expect(datum?.kind == .list(value: [
            .init(start: 1, end: 7, kind: .symbol(value: "lambda")),
            .init(start: 8, end: 11, kind: .list(value: [
                .init(start: 9, end: 10, kind: .symbol(value: "x")),
            ])),
            .init(start: 12, end: 21, kind: .list(value: [
                .init(start: 13, end: 16, kind: .symbol(value: "add")),
                .init(start: 17, end: 18, kind: .symbol(value: "x")),
                .init(start: 19, end: 20, kind: .number(value: 1)),
            ])),
        ]))
    }
}


