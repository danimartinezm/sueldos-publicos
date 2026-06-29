import Vapor

/// The single error envelope used by every endpoint: `{ "error": { "code", "message" } }`.
/// Internal/implementation details are never exposed (FR-015).
struct APIErrorEnvelope: Content {
    struct Payload: Content {
        let code: String
        let message: String
    }
    let error: Payload
}

/// Converts thrown errors into the consistent envelope without leaking internals.
struct APIErrorMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response
    {
        do {
            return try await next.respond(to: request)
        } catch {
            let status: HTTPResponseStatus
            let message: String
            if let abort = error as? any AbortError {
                status = abort.status
                message = abort.reason
            } else {
                status = .internalServerError
                message = "An unexpected error occurred."
            }

            let code: String
            switch status {
            case .notFound: code = "not_found"
            case .badRequest: code = "invalid_parameter"
            case .internalServerError: code = "internal_error"
            default: code = "error"
            }

            let response = Response(status: status)
            try response.content.encode(
                APIErrorEnvelope(error: .init(code: code, message: message)))
            return response
        }
    }
}
