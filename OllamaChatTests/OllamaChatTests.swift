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
                ChatViewModel.processBaseEndPoint(host: testCase.host, port: testCase.port),
                testCase.expected,
                "Failed: <\(testCase.host)> <\(testCase.port)>"
            )
        }
    }

    func testOllamaThinkingResponseDecodesThinkingOnlyChunk() throws {
        let data = """
        {
          "model": "qwen3",
          "created_at": "2026-03-07T00:00:00Z",
          "done": false,
          "message": {
            "role": "assistant",
            "thinking": "Working through the answer"
          }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ResponseModel.self, from: data)

        XCTAssertEqual(response.message.role, .assistant)
        XCTAssertEqual(response.message.content, "")
        XCTAssertEqual(response.message.thinking, "Working through the answer")
        XCTAssertEqual(
            response.chatStreamChunk,
            ChatStreamChunk(content: "", thinking: "Working through the answer")
        )
    }

    func testOllamaThinkingResponseDecodesContentAndThinkingChunk() throws {
        let data = """
        {
          "model": "qwen3",
          "created_at": "2026-03-07T00:00:00Z",
          "done": false,
          "message": {
            "role": "assistant",
            "content": "Final answer",
            "thinking": "Reasoning text"
          }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ResponseModel.self, from: data)

        XCTAssertEqual(response.message.content, "Final answer")
        XCTAssertEqual(response.message.thinking, "Reasoning text")
    }

    func testChatMessageRoundTripPreservesThinking() throws {
        let original = [
            ChatMessage(role: .assistant, content: "Final answer", thinking: "Reasoning text")
        ]

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode([ChatMessage].self, from: data)

        XCTAssertEqual(decoded.first?.content, "Final answer")
        XCTAssertEqual(decoded.first?.thinking, "Reasoning text")
    }

    func testChatMessageDecodesOldHistoryWithoutThinking() throws {
        let data = """
        [
          {
            "role": "assistant",
            "content": "Legacy response"
          }
        ]
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode([ChatMessage].self, from: data)

        XCTAssertEqual(decoded.first?.content, "Legacy response")
        XCTAssertNil(decoded.first?.thinking)
    }

    func testAutomaticThinkModeOmitsThinkKey() throws {
        let request = ChatModel(
            model: "qwen3",
            messages: [ChatMessage(role: .user, content: "Hello")],
            configuration: .defaultValue
        )

        let json = try jsonObject(from: JSONEncoder().encode(request))

        XCTAssertNil(json["think"])
    }

    func testBooleanThinkModeEncodesBoolean() throws {
        let request = ChatModel(
            model: "qwen3",
            messages: [ChatMessage(role: .user, content: "Hello")],
            configuration: ChatConfiguration(think: .enabled, options: .defaultValue)
        )

        let json = try jsonObject(from: JSONEncoder().encode(request))

        XCTAssertEqual(json["think"] as? Bool, true)
    }

    func testLevelThinkModeEncodesStringLevel() throws {
        let request = ChatModel(
            model: "gpt-oss:20b",
            messages: [ChatMessage(role: .user, content: "Hello")],
            configuration: ChatConfiguration(think: .medium, options: .defaultValue)
        )

        let json = try jsonObject(from: JSONEncoder().encode(request))

        XCTAssertEqual(json["think"] as? String, "medium")
    }

    func testRequestConfigurationOmitsThinkWhenServiceDisablesThinkField() throws {
        let configuration = OllamaService.requestConfiguration(
            from: ChatConfiguration(think: .disabled, options: .defaultValue),
            includeThinkField: false
        )

        let request = ChatModel(
            model: "qwen3",
            messages: [ChatMessage(role: .user, content: "Hello")],
            configuration: configuration
        )

        let json = try jsonObject(from: JSONEncoder().encode(request))

        XCTAssertEqual(configuration.think, .automatic)
        XCTAssertNil(json["think"])
    }

    func testRequestOmitsEmptyStopArray() throws {
        let request = ChatModel(
            model: "qwen3",
            messages: [ChatMessage(role: .user, content: "Hello")],
            configuration: .defaultValue
        )

        let json = try jsonObject(from: JSONEncoder().encode(request))
        let options = try XCTUnwrap(json["options"] as? [String: Any])

        XCTAssertNil(options["stop"])
    }

    func testListModelsResponseDecodesCurrentTagsSchema() throws {
        let data = """
        {
          "models": [
            {
              "name": "gemma3",
              "model": "gemma3",
              "remote_model": "library/gemma3",
              "remote_host": "https://ollama.com",
              "modified_at": "2025-10-03T23:34:03.409490317-07:00",
              "size": 3338801804,
              "digest": "a2af6cc3eb7fa8be8504abaf9b04e88f17a119ec3f04a3addf55f92841195f5a",
              "details": {
                "format": "gguf",
                "family": "gemma",
                "families": ["gemma"],
                "parameter_size": "4.3B",
                "quantization_level": "Q4_K_M"
              }
            }
          ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OllamaModelGroup.self, from: data)
        let model = try XCTUnwrap(response.models.first)

        XCTAssertEqual(model.name, "gemma3")
        XCTAssertEqual(model.model, "gemma3")
        XCTAssertEqual(model.remoteModel, "library/gemma3")
        XCTAssertEqual(model.remoteHost, "https://ollama.com")
        XCTAssertEqual(model.details?.format, "gguf")
        XCTAssertEqual(model.details?.family, "gemma")
        XCTAssertEqual(model.details?.families, ["gemma"])
        XCTAssertEqual(model.details?.parameterSize, "4.3B")
        XCTAssertEqual(model.details?.quantizationLevel, "Q4_K_M")
    }

    func testListModelsResponseDecodesWithoutDetailsObject() throws {
        let data = """
        {
          "models": [
            {
              "name": "llama3.2",
              "model": "llama3.2",
              "modified_at": "2026-03-07T00:00:00Z",
              "size": 2019393189,
              "digest": "deadbeef"
            }
          ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OllamaModelGroup.self, from: data)
        let model = try XCTUnwrap(response.models.first)

        XCTAssertEqual(model.name, "llama3.2")
        XCTAssertNil(model.details)
        XCTAssertEqual(model.modelInfo.modelName, "Llama3.2")
    }

    func testShowModelResponseDecodesDocumentedFields() throws {
        let data = """
        {
          "parameters": "num_ctx 4096",
          "license": "Apache-2.0",
          "modified_at": "2026-03-10T00:00:00Z",
          "template": "{{ .Prompt }}",
          "capabilities": ["completion", "thinking"]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OllamaShowModelResponse.self, from: data)

        XCTAssertEqual(response.parameters, "num_ctx 4096")
        XCTAssertEqual(response.license, "Apache-2.0")
        XCTAssertEqual(response.modifiedAt, "2026-03-10T00:00:00Z")
        XCTAssertEqual(response.template, "{{ .Prompt }}")
        XCTAssertEqual(response.thinkSupport, .supported)
    }

    func testShowModelRequestEncodesVerboseFlag() throws {
        let request = OllamaShowModelRequest(model: "gemma3", verbose: true)

        let json = try jsonObject(from: JSONEncoder().encode(request))

        XCTAssertEqual(json["model"] as? String, "gemma3")
        XCTAssertEqual(json["verbose"] as? Bool, true)
    }

    func testShowModelResponseDetectsUnsupportedThinking() throws {
        let data = """
        {
          "capabilities": ["completion"]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OllamaShowModelResponse.self, from: data)

        XCTAssertEqual(response.thinkSupport, .unsupported)
    }

    func testShowModelResponseDecodesDetailsModelInfoAndAdditionalFields() throws {
        let data = """
        {
          "details": {
            "parent_model": "qwen3",
            "format": "gguf",
            "family": "qwen",
            "families": ["qwen"],
            "parameter_size": "14B",
            "quantization_level": "Q4_K_M",
            "context_window": 4096
          },
          "model_info": {
            "general.architecture": "qwen2",
            "qwen2.context_length": 4096,
            "qwen2.attention.head_count": 40,
            "general.file_type": 15,
            "general.quantization_version": 2,
            "tokenizer.ggml.add_bos_token": false
          },
          "projector_info": {
            "clip.vision.embedding_length": 1024
          }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OllamaShowModelResponse.self, from: data)

        XCTAssertEqual(response.details?.parentModel, "qwen3")
        XCTAssertEqual(response.details?.format, "gguf")
        XCTAssertEqual(response.details?.family, "qwen")
        XCTAssertEqual(response.details?.families, ["qwen"])
        XCTAssertEqual(response.details?.parameterSize, "14B")
        XCTAssertEqual(response.details?.quantizationLevel, "Q4_K_M")
        XCTAssertEqual(response.details?.additionalFields["context_window"], .int(4096))
        XCTAssertEqual(response.modelInfo?["general.architecture"], .string("qwen2"))
        XCTAssertEqual(response.modelInfo?["qwen2.context_length"], .int(4096))
        XCTAssertEqual(response.modelInfo?["tokenizer.ggml.add_bos_token"], .bool(false))
        XCTAssertEqual(
            response.additionalFields["projector_info"],
            .object(["clip.vision.embedding_length": .int(1024)])
        )
    }

    func testShowModelResponseWithoutCapabilitiesDefaultsToUnknown() throws {
        let data = """
        {
          "license": "Apache-2.0"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OllamaShowModelResponse.self, from: data)

        XCTAssertEqual(response.thinkSupport, .unknown)
    }

    func testServerErrorLocalizedDescriptionIncludesResponseBody() throws {
        let error = ChatCompletionError.serverError(
            statusCode: 400,
            message: "unknown field `think`"
        )

        XCTAssertEqual(
            error.localizedDescription,
            "Ollama returned HTTP 400: unknown field `think`"
        )
    }

}

private func jsonObject(from data: Data) throws -> [String: Any] {
    let jsonObject = try JSONSerialization.jsonObject(with: data)
    return try XCTUnwrap(jsonObject as? [String: Any])
}
