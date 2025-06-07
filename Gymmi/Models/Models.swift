import Foundation

struct User: Codable, Identifiable {
    let id: Int
    let email: String
    let name: String?
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case isActive = "is_active"
    }
}

struct UserResponse: Codable {
    let id: Int
    let email: String
    let name: String?
    let is_active: Bool
}

struct AuthResponse: Codable {
    let token: String
    let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case token = "access_token"
        case tokenType = "token_type"
    }
}

struct ErrorResponse: Codable {
    let detail: String
}

struct ValidationErrorResponse: Codable {
    let detail: [ValidationErrorDetail]
}

struct ValidationErrorDetail: Codable {
    let type: String
    let loc: [String]
    let msg: String
    let input: String
    let ctx: [String: String]?
} 