import Testing 
@testable import SwiftScheme







struct ParserTests {
    @Test func testDatum01() throws {
        let data: String = "(hello 1 2 a b 3)"
        var parser = Parser(lexer: Lexer(data: data))
        let datum = try parser.parseDatum()
        #expect(datum.kind == .list(value: [
            .init(start: FilePos(pos: 1, col: 1, line: 0), end: FilePos(pos: 6, col: 6, line: 0), kind: .symbol(value: "hello")),
            .init(start: FilePos(pos: 7, col: 7, line: 0), end: FilePos(pos: 8, col: 8, line: 0), kind: .number(value: 1)),
            .init(start: FilePos(pos: 9, col: 9, line: 0), end: FilePos(pos: 10, col: 10, line: 0), kind: .number(value: 2)),
            .init(start: FilePos(pos: 11, col: 11, line: 0), end: FilePos(pos: 12, col: 12, line: 0), kind: .symbol(value: "a")),
            .init(start: FilePos(pos: 13, col: 13, line: 0), end: FilePos(pos: 14, col: 14, line: 0), kind: .symbol(value: "b")),
            .init(start: FilePos(pos: 15, col: 15, line: 0), end: FilePos(pos: 16, col: 16, line: 0), kind: .number(value: 3)),
        ]))
    }

    @Test func testDatum02() throws {
        let data: String = "(lambda (x) (add x 1))"
        var parser = Parser(lexer: Lexer(data: data))
        let datum = try parser.parseDatum()
        #expect(datum.kind == .list(value: [
            .init(start: FilePos(pos: 1, col: 1, line: 0), end: FilePos(pos: 7, col: 7, line: 0), kind: .symbol(value: "lambda")),
            .init(start: FilePos(pos: 8, col: 8, line: 0), end: FilePos(pos: 11, col: 11, line: 0), kind: .list(value: [
                .init(start: FilePos(pos: 9, col: 9, line: 0), end: FilePos(pos: 10, col: 10, line: 0), kind: .symbol(value: "x")),
            ])),
            .init(start: FilePos(pos: 12, col: 12, line: 0), end: FilePos(pos: 21, col: 21, line: 0), kind: .list(value: [
                .init(start: FilePos(pos: 13, col: 13, line: 0), end: FilePos(pos: 16, col: 16, line: 0), kind: .symbol(value: "add")),
                .init(start: FilePos(pos: 17, col: 17, line: 0), end: FilePos(pos: 18, col: 18, line: 0), kind: .symbol(value: "x")),
                .init(start: FilePos(pos: 19, col: 19, line: 0), end: FilePos(pos: 20, col: 20, line: 0), kind: .number(value: 1)),
            ])),
        ]))
    }







    @Test func testProcedureCall01() throws {
        let data: String = "(hello a b c)"
        var parser = Parser(lexer: Lexer(data: data))
        let expr = try parser.parseExpression()
        #expect(expr.kind == .procedureCall(
            operator: .init(start: FilePos(pos: 1, col: 1, line: 0), end: FilePos(pos: 6, col: 6, line: 0), kind: .variable("hello")), 
            operands: [
                .init(start: FilePos(pos: 7, col: 7, line: 0), end: FilePos(pos: 8, col: 8, line: 0), kind: .variable("a")),
                .init(start: FilePos(pos: 9, col: 9, line: 0), end: FilePos(pos: 10, col: 10, line: 0), kind: .variable("b")),
                .init(start: FilePos(pos: 11, col: 11, line: 0), end: FilePos(pos: 12, col: 12, line: 0), kind: .variable("c")),
            ]))
    }





    @Test func testIf01() throws {
        let data: String = "(if test then else)"
        var parser = Parser(lexer: Lexer(data: data))
        let expr = try parser.parseExpression()
        #expect(expr.kind == .conditional(
            test: .init(start: FilePos(pos: 4, col: 4, line: 0), end: FilePos(pos: 8, col: 8, line: 0), kind: .variable("test")), 
            consequence: .init(start: FilePos(pos: 9, col: 9, line: 0), end: FilePos(pos: 13, col: 13, line: 0), kind: .variable("then")), 
            alternate: .init(start: FilePos(pos: 14, col: 14, line: 0), end: FilePos(pos: 18, col: 18, line: 0), kind: .variable("else"))))
    }

    @Test func testIf02() throws {
        let data: String = "(if test then)"
        var parser = Parser(lexer: Lexer(data: data))
        let expr = try parser.parseExpression()
        #expect(expr.kind == .conditional(
            test: .init(start: FilePos(pos: 4, col: 4, line: 0), end: FilePos(pos: 8, col: 8, line: 0), kind: .variable("test")), 
            consequence: .init(start: FilePos(pos: 9, col: 9, line: 0), end: FilePos(pos: 13, col: 13, line: 0), kind: .variable("then")), 
            alternate: nil))
    }



    @Test func testLambda01() throws {
        let data: String = "(lambda (x) (a x 1))"
        var parser = Parser(lexer: Lexer(data: data))
        let expr = try parser.parseExpression()
        #expect(expr.kind == .procedure(params: ["x"], remainingParams: nil, body: [
            .init(start: FilePos(pos: 12, col: 12, line: 0), end: FilePos(pos: 19, col: 19, line: 0), kind: 
            .procedureCall(operator: .init(start: FilePos(pos: 13, col: 13, line: 0), end: FilePos(pos: 14, col: 14, line: 0), kind: .variable("a")), operands: [
                .init(start: FilePos(pos: 15, col: 15, line: 0), end: FilePos(pos: 16, col: 16, line: 0), kind: .variable("x")),
                .init(start: FilePos(pos: 17, col: 17, line: 0), end: FilePos(pos: 18, col: 18, line: 0), kind: .number(1)),
            ]))
        ]))
    }
}

