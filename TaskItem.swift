import Foundation

struct TaskItem: Identifiable, Codable, Sendable {
    let id: String
    let title: String
    let status: String?
}

// Structs to decode the JSON response structure from Notion API
struct NotionQueryResponse: Codable, Sendable {
    let results: [NotionPage]
}

struct NotionPage: Codable, Sendable {
    let id: String
    let properties: NotionProperties
}

struct NotionProperties: Codable, Sendable {
    let Name: NotionTitleProperty?
    let Status: NotionStatusProperty?
    
    enum CodingKeys: String, CodingKey {
        case Name
        case Status
    }
}

struct NotionTitleProperty: Codable, Sendable {
    let title: [NotionTextContent]
}

struct NotionStatusProperty: Codable, Sendable {
    let status: NotionStatusValue?
    let select: NotionSelectValue?
}

struct NotionStatusValue: Codable, Sendable {
    let name: String
}

struct NotionSelectValue: Codable, Sendable {
    let name: String
}

struct NotionTextContent: Codable, Sendable {
    let plainText: String
    
    enum CodingKeys: String, CodingKey {
        case plainText = "plain_text"
    }
}
