import XCTest
@testable import LifeScriptSolo

final class SoloContentCompatibilityTests: XCTestCase {
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    func test_choiceDecoding_defaultsMissingSatisfactionTypeToGeneric() throws {
        let data = """
        {
          "id": "choice_missing_style",
          "text": "稳扎稳打"
        }
        """.data(using: .utf8)!

        let choice = try decoder.decode(Choice.self, from: data)

        XCTAssertEqual(choice.satisfactionType, .generic)
        XCTAssertEqual(choice.satisfactionType.displayName, "策略推进")
    }

    func test_choiceDecoding_preservesUnknownSatisfactionType() throws {
        let data = """
        {
          "id": "choice_unknown_style",
          "text": "嘴上先赢一轮",
          "satisfaction_type": "嘴毒打脸"
        }
        """.data(using: .utf8)!

        let choice = try decoder.decode(Choice.self, from: data)

        XCTAssertEqual(choice.satisfactionType.rawValue, "嘴毒打脸")
        XCTAssertEqual(choice.satisfactionType.iconName, "quote.bubble.fill")
    }

    func test_choiceNodeDecoding_preservesUnexpectedChoiceTypes() throws {
        let data = """
        {
          "id": "choice_node_unknown_type",
          "prompt": "面对天机录的新线索，你决定？",
          "choice_type": "质疑",
          "choices": [
            {
              "id": "choice_option_a",
              "text": "先问清楚"
            }
          ]
        }
        """.data(using: .utf8)!

        let node = try decoder.decode(ChoiceNode.self, from: data)

        XCTAssertEqual(node.choiceType.rawValue, "质疑")
        XCTAssertEqual(node.choiceType.displayName, "质疑")
    }

    func test_relationshipState_tracksCustomDimensions() {
        let base = RelationshipState(
            characterId: "char_custom",
            trust: 0,
            affection: 0,
            hostility: 0,
            awe: 0,
            dependence: 0,
            lastChangeReason: nil,
            unlockedEvents: []
        )

        let result = base.applying(effects: [
            RelationshipEffect(
                characterId: "char_custom",
                dimension: .vigilance,
                delta: 45
            )
        ])

        XCTAssertEqual(result.customDimensions["警惕"], 45)
        XCTAssertEqual(result.value(for: .vigilance), 45)
        XCTAssertEqual(result.attitudeLabel, "警惕")
    }

    func test_normalizePackagedChapterData_promotesLeakedNodesAndSplitsCompoundResultNodes() throws {
        let data = """
        {
          "id": "book_ch0001",
          "book_id": "book",
          "number": 1,
          "title": "测试章",
          "is_paid": false,
          "nodes": [
            {
              "choice": {
                "id": "choice_main",
                "prompt": "怎么做？",
                "choice_type": "keyDecision",
                "choices": [
                  {
                    "id": "choice_a",
                    "text": "先看一步",
                    "satisfaction_type": "直接爽",
                    "result_nodes": [
                      {
                        "text": {
                          "id": "result_text",
                          "content": "陈机先稳住局面。"
                        },
                        "dialogue": {
                          "id": "result_dialogue",
                          "character_id": "char_chenji",
                          "content": "还没到翻脸的时候。"
                        }
                      }
                    ]
                  },
                  {
                    "text": {
                      "id": "follow_text",
                      "content": "长廊尽头传来新的脚步声。"
                    }
                  },
                  {
                    "choice": {
                      "id": "choice_followup",
                      "prompt": "是否继续追上去？",
                      "choice_type": "styleChoice",
                      "choices": [
                        {
                          "id": "choice_followup_a",
                          "text": "继续追"
                        }
                      ]
                    }
                  }
                ]
              }
            }
          ]
        }
        """.data(using: .utf8)!

        let normalized = try normalizePackagedChapterData(data)
        let chapter = try decoder.decode(Chapter.self, from: normalized)

        XCTAssertEqual(chapter.nodes.count, 3)

        guard case .choice(let firstChoice) = chapter.nodes[0] else {
            return XCTFail("Expected the first normalized node to remain a choice")
        }

        XCTAssertEqual(firstChoice.choices.count, 1)
        XCTAssertEqual(firstChoice.choices.first?.resultNodes?.count, 2)

        guard case .text(let promotedText) = chapter.nodes[1] else {
            return XCTFail("Expected the leaked text node to be promoted after the choice")
        }
        XCTAssertEqual(promotedText.id, "follow_text")

        guard case .choice(let promotedChoice) = chapter.nodes[2] else {
            return XCTFail("Expected the leaked nested choice to be promoted after the text")
        }
        XCTAssertEqual(promotedChoice.id, "choice_followup")
    }

    func test_normalizePackagedChapterData_convertsDialogueWithoutCharacterIntoText() throws {
        let data = """
        {
          "id": "book_ch0002",
          "book_id": "book",
          "number": 2,
          "title": "缺角色对白",
          "is_paid": false,
          "nodes": [
            {
              "dialogue": {
                "id": "dangling_dialogue",
                "content": "夜清忽然停住了脚步。",
                "emotion": "迟疑"
              }
            }
          ]
        }
        """.data(using: .utf8)!

        let normalized = try normalizePackagedChapterData(data)
        let chapter = try decoder.decode(Chapter.self, from: normalized)

        guard case .text(let textNode) = chapter.nodes.first else {
            return XCTFail("Expected malformed dialogue to be downgraded into text")
        }

        XCTAssertEqual(textNode.id, "dangling_dialogue")
        XCTAssertEqual(textNode.content, "夜清忽然停住了脚步。")
    }

    func test_normalizePackagedChapterData_assignsStableIdsToAnonymousTextAndStringNodes() throws {
        let data = """
        {
          "id": "book_ch0003",
          "book_id": "book",
          "number": 3,
          "title": "匿名节点",
          "is_paid": false,
          "nodes": [
            {
              "text": {
                "content": "没有 id 的叙述。"
              }
            },
            "落入结果数组里的裸文本"
          ]
        }
        """.data(using: .utf8)!

        let normalized = try normalizePackagedChapterData(data)
        let chapter = try decoder.decode(Chapter.self, from: normalized)

        XCTAssertEqual(chapter.nodes.count, 2)

        guard case .text(let firstText) = chapter.nodes[0] else {
            return XCTFail("Expected anonymous text node to remain text")
        }
        XCTAssertEqual(firstText.id, "chapter_nodes_0_text")
        XCTAssertEqual(firstText.content, "没有 id 的叙述。")

        guard case .text(let secondText) = chapter.nodes[1] else {
            return XCTFail("Expected raw string node to be promoted to text")
        }
        XCTAssertEqual(secondText.id, "chapter_nodes_1_text")
        XCTAssertEqual(secondText.content, "落入结果数组里的裸文本")
    }

    func test_normalizePackagedChapterData_dropsInvalidTextEmphasisValues() throws {
        let data = """
        {
          "id": "book_ch0004",
          "book_id": "book",
          "number": 4,
          "title": "脏 emphasis",
          "is_paid": false,
          "nodes": [
            {
              "text": {
                "id": "bad_emphasis",
                "content": "这段叙述不该因为空字符串而解码失败。",
                "emphasis": ""
              }
            }
          ]
        }
        """.data(using: .utf8)!

        let normalized = try normalizePackagedChapterData(data)
        let chapter = try decoder.decode(Chapter.self, from: normalized)

        guard case .text(let textNode) = chapter.nodes.first else {
            return XCTFail("Expected the text node to survive normalization")
        }

        XCTAssertEqual(textNode.id, "bad_emphasis")
        XCTAssertNil(textNode.emphasis)
    }
}
