import Foundation
@testable import LifeScript

enum TestFixtures {
    static func makeBook(
        id: String = "test_book",
        title: String = "测试书籍",
        totalChapters: Int = 3
    ) -> Book {
        Book(
            id: id,
            title: title,
            author: "测试作者",
            coverImageName: "test_cover",
            synopsis: "测试简介",
            genre: .urbanReversal,
            tags: ["测试标签"],
            interactionTags: ["高互动"],
            totalChapters: totalChapters,
            freeChapters: 2,
            characters: [makeCharacter()],
            initialStats: .initial
        )
    }

    static func makeCharacter(
        id: String = "test_char",
        name: String = "测试角色",
        role: Character.CharacterRole = .neutral
    ) -> Character {
        Character(
            id: id,
            name: name,
            title: "测试身份",
            avatarImageName: "test_avatar",
            description: "测试描述",
            role: role
        )
    }

    static func makeChapter(
        id: String = "test_chapter",
        bookId: String = "test_book",
        number: Int = 1,
        nodes: [StoryNode] = []
    ) -> Chapter {
        Chapter(
            id: id,
            bookId: bookId,
            number: number,
            title: "测试章节\(number)",
            nodes: nodes,
            isPaid: false,
            nextChapterHook: "下一章预告"
        )
    }

    static func makeChoice(
        id: String = "test_choice",
        statEffects: [StatEffect] = [],
        relationshipEffects: [RelationshipEffect] = []
    ) -> Choice {
        Choice(
            id: id,
            text: "测试选项",
            description: "测试描述",
            satisfactionType: .immediatePower,
            statEffects: statEffects,
            relationshipEffects: relationshipEffects,
            resultNodeIds: []
        )
    }
}
