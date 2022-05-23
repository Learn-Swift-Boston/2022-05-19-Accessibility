import Foundation

struct TopLevelResponse: Codable {
    var data: RedditData
}

struct RedditData: Codable {
    var children: [RedditChild]
}

struct RedditChild: Codable {
    var data: RedditPost
}

struct RedditPost: Codable, Identifiable {
    var url: URL
    var title: String
    var thumbnail: URL?
    var author: String
    var created: Date
    var id: URL {
        url
    }
}
