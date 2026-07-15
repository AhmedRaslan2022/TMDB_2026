import Foundation
import Testing
@testable import CoreNetworking

private struct ConfigurationEndpoint: Endpoint {
    let path = "/configuration"
}

private struct ImagesResponse: Decodable, Equatable {
    let baseUrl: String
}

/// Serialized: all cases share the URLProtocolStub's global state.
@Suite(.serialized)
final class URLSessionAPIClientTests {
    private let client = URLSessionAPIClient(
        baseURL: URL(string: "https://api.example.com/3")!,
        session: URLProtocolStub.makeSession()
    )

    deinit {
        URLProtocolStub.reset()
    }

    @Test func decodesSnakeCaseSuccessResponse() async throws {
        URLProtocolStub.stub(statusCode: 200, data: Data(#"{"base_url":"https://image.tmdb.org"}"#.utf8))

        let response: ImagesResponse = try await client.send(ConfigurationEndpoint())

        #expect(response == ImagesResponse(baseUrl: "https://image.tmdb.org"))
        #expect(URLProtocolStub.lastRequest?.url?.path() == "/3/configuration")
    }

    @Test func mapsUnauthorized() async {
        URLProtocolStub.stub(statusCode: 401)

        await #expect(throws: APIError.self) {
            try await self.client.sendRaw(ConfigurationEndpoint())
        }
        await expectAPIError(.unauthorized)
    }

    @Test func mapsNotFound() async {
        URLProtocolStub.stub(statusCode: 404)
        await expectAPIError(.notFound)
    }

    @Test func mapsClientError() async {
        URLProtocolStub.stub(statusCode: 422)
        await expectAPIError(.client(statusCode: 422))
    }

    @Test func mapsServerError() async {
        URLProtocolStub.stub(statusCode: 503)
        await expectAPIError(.server(statusCode: 503))
    }

    @Test func mapsTransportError() async {
        URLProtocolStub.stub(error: URLError(.notConnectedToInternet))

        do {
            try await client.sendRaw(ConfigurationEndpoint())
            Issue.record("expected transport error")
        } catch let APIError.transport(urlError) {
            #expect(urlError.code == .notConnectedToInternet)
        } catch {
            Issue.record("unexpected error: \(error)")
        }
    }

    @Test func mapsDecodingFailure() async {
        URLProtocolStub.stub(statusCode: 200, data: Data(#"{"unexpected":true}"#.utf8))

        do {
            let _: ImagesResponse = try await client.send(ConfigurationEndpoint())
            Issue.record("expected decoding error")
        } catch APIError.decoding {
            // expected
        } catch {
            Issue.record("unexpected error: \(error)")
        }
    }

    private func expectAPIError(
        _ expected: APIError,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        do {
            try await client.sendRaw(ConfigurationEndpoint())
            Issue.record("expected \(expected)", sourceLocation: sourceLocation)
        } catch let error as APIError {
            #expect(String(describing: error) == String(describing: expected), sourceLocation: sourceLocation)
        } catch {
            Issue.record("unexpected error: \(error)", sourceLocation: sourceLocation)
        }
    }
}
