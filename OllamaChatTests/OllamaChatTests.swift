//
//  OllamaChatTests.swift
//  Ollama SwiftTests
//
//  Created by Karim ElGhandour on 07.10.23.
//

import XCTest
@testable import OllamaChat

final class OllamaChatTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testApiEndpoint() throws {
        let testCases = [
            // Default cases
            (host: "", port: "", expected: "http://127.0.0.1:11434/api/"),
            
            // Default port for specific hosts
            (host: "localhost", port: "", expected: "http://localhost:11434/api/"),
            (host: "127.0.0.1", port: "", expected: "http://127.0.0.1:11434/api/"),
            
            // Custom valid cases
            (host: "localhost", port: "8080", expected: "http://localhost:8080/api/"),
            (host: "example.com", port: "443", expected: "http://example.com:443/api/"),
            (host: "https://example.com", port: "443", expected: "https://example.com:443/api/"),
            
            // Invalid port cases
            (host: "localhost", port: "invalid", expected: "http://localhost/api/"),
            (host: "localhost", port: "0", expected: "http://localhost:0/api/"),
            (host: "localhost", port: "65536", expected: "http://localhost:65536/api/"),
            
            // Host with protocol
            (host: "http://localhost", port: "8080", expected: "http://localhost:8080/api/"),
            (host: "https://localhost", port: "8080", expected: "https://localhost:8080/api/"),
            
            // Whitespace handling
            (host: " localhost ", port: "8080", expected: "http://localhost:8080/api/"),
            (host: "localhost", port: " 8080 ", expected: "http://localhost:8080/api/"),
            (host: " localhost ", port: " 8080 ", expected: "http://localhost:8080/api/"),
            
            // Hostnames with subdomains
            (host: "api.example.com", port: "443", expected: "http://api.example.com:443/api/"),
            (host: "subdomain.example.co.uk", port: "8080", expected: "http://subdomain.example.co.uk:8080/api/"),
            
            // IP addresses
            (host: "192.168.1.1", port: "8080", expected: "http://192.168.1.1:8080/api/"),
            (host: "192.168.1.1", port: "", expected: "http://192.168.1.1/api/"),
            
            // Host with embedded path (which should be ignored)
            (host: "example.com/path", port: "8080", expected: "http://example.com:8080/api/"),
            (host: "http://example.com/path", port: "8080", expected: "http://example.com:8080/api/"),
            
            // Unusual but valid ports
            (host: "localhost", port: "1", expected: "http://localhost:1/api/"),
            (host: "localhost", port: "65535", expected: "http://localhost:65535/api/"),
            
            // Custom domains without port
            (host: "api.example.com", port: "", expected: "http://api.example.com/api/"),
            
            // Protocol edge cases
            (host: "https://", port: "8080", expected: "https://127.0.0.1:8080/api/"),
            (host: "http://", port: "8080", expected: "http://127.0.0.1:8080/api/"),
            
            // Mixed case in protocol
            (host: "HttP://example.com", port: "8080", expected: "http://example.com:8080/api/"),
            (host: "hTTps://example.com", port: "8080", expected: "https://example.com:8080/api/")
        ]
        
        for testCase in testCases {
            XCTAssertEqual(
                ChatViewModel.processAPIEndPoint(host: testCase.host, port: testCase.port),
                testCase.expected,
                "Failed: <\(testCase.host)> <\(testCase.port)>"
            )
        }
    }

}
