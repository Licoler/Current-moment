import Foundation

// MARK: - DTOs

struct RegisterRequest: Codable {
    let username: String
    let email: String
    let password: String
    let fullName: String
}

struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct LoginResponse: Codable {
    let token: String?
}

struct UpdateProfileRequest: Codable {
    let full_name: String?
    let username: String?
    let avatar_url: String?
}

struct CreateReplyRequest: Codable {
    let momentId: String
    let content: String
}

struct CreateMomentRequest: Codable {
    let imageUrl: String
    let caption: String?
    let isLivePhoto: Bool
}

enum APIError: Error {
    case invalidResponse
    case invalidToken
    case decodingError
    case invalidCredentials
    case serverMessage(String)
}

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Server error. Please try again."
        case .invalidToken: return "Authentication failed. Please log in again."
        case .decodingError: return "Data error. Please contact support."
        case .invalidCredentials: return "Invalid username or password."
        case .serverMessage(let msg): return msg
        }
    }
}

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let baseURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        self.session = URLSession(configuration: config)
        self.baseURL = URL(string: "http://localhost:8080")!
        self.decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - AUTH

    func login(username: String, password: String) async throws -> String {
        let url = baseURL.appendingPathComponent("users/login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = LoginRequest(username: username, password: password)
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if http.statusCode == 401 {
            if let errorJson = try? JSONDecoder().decode([String: String].self, from: data),
               let reason = errorJson["reason"] {
                throw APIError.serverMessage(reason)
            } else {
                throw APIError.invalidCredentials
            }
        }

        guard (200..<300).contains(http.statusCode) else {
            throw APIError.invalidResponse
        }

        let decoded = try decoder.decode(LoginResponse.self, from: data)
        guard let token = decoded.token else {
            throw APIError.invalidToken
        }

        AuthTokenStore.save(token)
        return token
    }

    var hasToken: Bool {
        AuthTokenStore.load() != nil
    }

    func clearToken() {
        AuthTokenStore.clear()
    }

    // MARK: - GET REQUEST

    private func request<T: Decodable>(_ path: String) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let token = AuthTokenStore.load() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            if let http = response as? HTTPURLResponse, http.statusCode == 401 {
                throw APIError.invalidToken
            }
            throw APIError.invalidResponse
        }

        return try decoder.decode(T.self, from: data)
    }

    func fetchCurrentUser() async throws -> APIUser {
        try await request("users/me")
    }

    func fetchUsers() async throws -> [APIUser] {
        try await request("users")
    }

    func fetchMoments() async throws -> [APIMoment] {
        try await request("moments")
    }

    func fetchFriendships(for userId: String) async throws -> [APIFriendship] {
        try await request("friendships/\(userId)")
    }

    func register(_ request: RegisterRequest) async throws -> LoginResponse {
        let url = baseURL.appendingPathComponent("users/register")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try encoder.encode(request)

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            if let errorJson = try? JSONDecoder().decode([String: String].self, from: data),
               let reason = errorJson["reason"] {
                throw APIError.serverMessage(reason)
            }
            throw APIError.invalidResponse
        }
        return try decoder.decode(LoginResponse.self, from: data)
    }

    // MARK: - UPDATE PROFILE

    func updateProfile(fullName: String, username: String, avatarURL: String?) async throws -> APIUser {
        let url = baseURL.appendingPathComponent("users/me")
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthTokenStore.load() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let body = UpdateProfileRequest(full_name: fullName, username: username, avatar_url: avatarURL)
        request.httpBody = try encoder.encode(body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.invalidResponse
        }
        return try decoder.decode(APIUser.self, from: data)
    }

    // MARK: - REPLIES

    func createReply(momentId: String, content: String) async throws -> APIReply {
        let url = baseURL.appendingPathComponent("replies")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthTokenStore.load() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let body = CreateReplyRequest(momentId: momentId, content: content)
        request.httpBody = try encoder.encode(body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            if let errorJson = try? JSONDecoder().decode([String: String].self, from: data),
               let reason = errorJson["reason"] {
                throw APIError.serverMessage(reason)
            }
            throw APIError.invalidResponse
        }
        return try decoder.decode(APIReply.self, from: data)
    }

    func fetchReplies(for momentId: String) async throws -> [APIReply] {
        try await request("replies/\(momentId)")
    }

    // MARK: - MOMENTS

    func deleteMoment(_ momentId: String) async throws {
        let url = baseURL.appendingPathComponent("moments/\(momentId)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        if let token = AuthTokenStore.load() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            if let http = response as? HTTPURLResponse, http.statusCode == 403 {
                throw APIError.serverMessage("You can only delete your own moments")
            }
            throw APIError.invalidResponse
        }
    }

    func createMoment(imageUrl: String, caption: String?, isLivePhoto: Bool) async throws -> APIMoment {
        let url = baseURL.appendingPathComponent("moments")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthTokenStore.load() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let body = CreateMomentRequest(imageUrl: imageUrl, caption: caption, isLivePhoto: isLivePhoto)
        request.httpBody = try encoder.encode(body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.invalidResponse
        }
        return try decoder.decode(APIMoment.self, from: data)
    }
}
