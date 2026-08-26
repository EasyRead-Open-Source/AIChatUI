//
//  AIChatRole.swift
//  AIChatUI
//
//  Created by Phineas Guo on 2026/8/26
//

import Foundation

/// The identity and presentation metadata for one AI participant.
public struct AIChatRole: Identifiable, Hashable {
    public var id: String
    public var name: String
    public var subtitle: String?
    public var avatarImageData: Data?
    public var avatarURL: URL?

    public init(
        id: String = UUID().uuidString,
        name: String,
        subtitle: String? = nil,
        avatarImageData: Data? = nil,
        avatarURL: URL? = nil
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.avatarImageData = avatarImageData
        self.avatarURL = avatarURL
    }
}
