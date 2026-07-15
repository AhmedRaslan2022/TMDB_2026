import Foundation
import Testing
@testable import CoreNetworking

private struct PingEndpoint: Endpoint {
    let path = "/ping"
}

struct RequestInterceptorTests {
    @Test func bearerInterceptorSetsAuthorizationHeader() async throws {
        let interceptor = BearerAuthInterceptor(tokenProvider: { "secret-token" })
        var request = try URLRequest(url: #require(URL(string: "https://api.example.com/3/ping")))

        request = try await interceptor.adapt(request)

        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer secret-token")
    }

    @Test func clientAppliesInterceptorsToOutgoingRequests() async throws {
        let (session, stub) = URLProtocolStub.makeSession()
        stub.stub(statusCode: 200)
        let client = try URLSessionAPIClient(
            baseURL: #require(URL(string: "https://api.example.com/3")),
            session: session,
            interceptors: [BearerAuthInterceptor(tokenProvider: { "abc123" })]
        )

        try await client.sendRaw(PingEndpoint())

        #expect(stub.lastRequest?.value(forHTTPHeaderField: "Authorization") == "Bearer abc123")
    }

    @Test func interceptorsRunInOrder() async throws {
        struct HeaderInterceptor: RequestInterceptor {
            let value: String
            func adapt(_ request: URLRequest) async throws -> URLRequest {
                var request = request
                request.setValue(value, forHTTPHeaderField: "X-Order")
                return request
            }
        }
        let (session, stub) = URLProtocolStub.makeSession()
        stub.stub(statusCode: 200)
        let client = try URLSessionAPIClient(
            baseURL: #require(URL(string: "https://api.example.com/3")),
            session: session,
            interceptors: [HeaderInterceptor(value: "first"), HeaderInterceptor(value: "second")]
        )

        try await client.sendRaw(PingEndpoint())

        #expect(stub.lastRequest?.value(forHTTPHeaderField: "X-Order") == "second")
    }
}
