import Testing
@testable import SwiftScheme

struct LexerTests {
    @Test func testBoolean01() throws {
        let data = "#t"
        var lexer = Lexer(data: data)
        let token = try lexer.next()
        #expect(token?.value == .boolean(value: true))
    }

    @Test func testBoolean02() throws {
        let data = "#f"
        var lexer = Lexer(data: data)
        let token = try lexer.next()
        #expect(token?.value == .boolean(value: false))
    }




    @Test func testParens01() throws {
        let data = "("
        var lexer = Lexer(data: data)
        let token = try lexer.next()
        #expect(token?.value == .lparen)
    }

    @Test func testParens02() throws {
        let data = ")"
        var lexer = Lexer(data: data)
        let token = try lexer.next()
        #expect(token?.value == .rparen)
    }



    
    @Test func testNumber01() throws {
        let data = "42"
        var lexer = Lexer(data: data)
        let token = try lexer.next()
        #expect(token?.value == .number(value: 42))
    }

    @Test func testNumber02() throws {
        let data = "-42"
        var lexer = Lexer(data: data)
        let token = try lexer.next()
        #expect(token?.value == .number(value: -42))
    }

    @Test func testNumber03() throws {
        let data = "+42"
        var lexer = Lexer(data: data)
        let token = try lexer.next()
        #expect(token?.value == .number(value: 42))
    }





    @Test func testIdentifier01() throws {
        let data = "abcdef"
        var lexer = Lexer(data: data)
        let token = try lexer.next()
        #expect(token?.value == .identifier(name: "abcdef"))
    }

    @Test func testIdentifier02() throws {
        let data = "+ 0 1"
        var lexer = Lexer(data: data)
        let token = try lexer.next()
        #expect(token?.value == .identifier(name: "+"))
    }






    @Test func testWhitespace01() async throws {
        let data = "     \t\t  \r\n   \n    #t"
        var lexer = Lexer(data: data)
        let token = try lexer.next()
        #expect(token?.value == .boolean(value: true))
    }

    @Test func testWhitespace02() async throws {
        let data = """
                ; comment
                ;comment
                ;
                  \t\t    #t
             """
        var lexer = Lexer(data: data)
        let token = try lexer.next()
        #expect(token?.value == .boolean(value: true))
    }



    @Test func testPeek01() throws {
        let data = "(a b c)"
        var lexer = Lexer(data: data)
        
        #expect(try lexer.peek()?.value == .lparen)
        let _ = try lexer.next()

        #expect(try lexer.peek()?.value == .identifier(name: "a"))
        let _ = try lexer.next()

        #expect(try lexer.peek()?.value == .identifier(name: "b"))
        #expect(try lexer.next()?.value == .identifier(name: "b"))
    }
}

