import Foundation
import Testing
@testable import CoreNetworking

private struct TestEndpoint: Endpoint {
    var path = "/movies/popular"
    var method = HTTPMethod.get
    var queryItems = [URLQueryItem]()
    var headers = [String: String]()
    var body: Data?
}

struct RequestBuilderTests {
    private let baseURL = URL(string: "https://api.example.com/3")!

    @Test func buildsURLFromBaseAndPath() throws {
        let request = try RequestBuilder.makeRequest(for: TestEndpoint(), baseURL: baseURL)

        #expect(request.url?.absoluteString == "https://api.example.com/3/movies/popular")
        #expect(request.httpMethod == "GET")
    }

    @Test func appendsQueryItems() throws {
        var endpoint = TestEndpoint()
        endpoint.queryItems = [
            URLQueryItem(name: "page", value: "2"),
            URLQueryItem(name: "language", value: "en-US"),
        ]

        let request = try RequestBuilder.makeRequest(for: endpoint, baseURL: baseURL)

        #expect(request.url?.query() == "page=2&language=en-US")
    }

    @Test func setsBodyAndContentTypeForPost() throws {
        var endpoint = TestEndpoint()
        endpoint.method = .post
        endpoint.body = Data(#"{"value":8.5}"#.utf8)

        let request = try RequestBuilder.makeRequest(for: endpoint, baseURL: baseURL)

        #expect(request.httpMethod == "POST")
        #expect(request.httpBody == endpoint.body)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test func omitsContentTypeWithoutBody() throws {
        let request = try RequestBuilder.makeRequest(for: TestEndpoint(), baseURL: baseURL)

        #expect(request.value(forHTTPHeaderField: "Content-Type") == nil)
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test func appliesEndpointHeaders() throws {
        var endpoint = TestEndpoint()
        endpoint.headers = ["X-Custom": "value"]

        let request = try RequestBuilder.makeRequest(for: endpoint, baseURL: baseURL)

        #expect(request.value(forHTTPHeaderField: "X-Custom") == "value")
    }
}
