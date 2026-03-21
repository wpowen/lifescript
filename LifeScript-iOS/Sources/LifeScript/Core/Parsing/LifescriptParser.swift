import Foundation

// MARK: - Lifescript DSL Parser
//
// Parses .ls (Lifescript DSL) files into Chapter + StoryNode arrays.
//
// DSL FORMAT:
// ─────────────────────────────────────────────────────────
// # ch_001 | 1 | 宗祠之辱
// book: urban_001
// hook: 预告文本...
//
// ---
//
// 普通叙述文字，直接写。
// 戏剧性文字，行末加 [dramatic]
// 系统提示文字，行末加 [system]
// 低语文字，行末加 [whisper]
//
// [角色名|情绪]: 对话内容
//
// @choice choice_001_01 [keyDecision]
// prompt: 选择提示语
//
// - c_001_01_a [直接爽]: 选项文本
//   desc: 选项描述
//   effects: 战力+15, 名望+10
//   relations: 林三长老(敬畏+25, 敌意+15), 林月(好感+10)
//   result: 选择后的结果描述文本
//
// @end-choice
// ─────────────────────────────────────────────────────────

struct LifescriptParser: NovelParser {

    func parse(content: String, metadata: NovelMetadata) async throws -> Chapter {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NovelParseError.emptyContent
        }

        let registry = CharacterRegistry(characters: metadata.characters)
        let effectParser = EffectParser(registry: registry)
        let lines = content.components(separatedBy: "\n")
        var nodeIdCounter = 0

        func nextId(_ prefix: String = "n") -> String {
            nodeIdCounter += 1
            return "\(prefix)_\(metadata.chapterId)_\(String(format: "%03d", nodeIdCounter))"
        }

        var nodes: [StoryNode] = []
        var i = 0
        var inContent = false // skip until after ---

        while i < lines.count {
            let raw = lines[i]
            let line = raw.trimmingCharacters(in: .whitespaces)
            i += 1

            // Skip empty lines in header section
            if !inContent && line.isEmpty { continue }

            // Header line: # ch_001 | 1 | Title (already parsed from metadata)
            if line.hasPrefix("# ") { continue }

            // Metadata lines (book:, hook:) — already in metadata struct
            if line.hasPrefix("book:") || line.hasPrefix("hook:") { continue }

            // Content separator
            if line == "---" {
                inContent = true
                continue
            }

            if !inContent { continue }

            // Empty line inside content — skip
            if line.isEmpty { continue }

            // Choice block
            if line.hasPrefix("@choice") {
                let (choiceNode, linesConsumed) = try parseChoiceBlock(
                    lines: lines,
                    startIndex: i - 1,
                    registry: registry,
                    effectParser: effectParser,
                    baseId: nextId("choice")
                )
                nodes.append(.choice(choiceNode))
                i = linesConsumed
                continue
            }

            // Dialogue: [角色名|情绪]: 内容
            if line.hasPrefix("["), let colonRange = line.range(of: "]: ") {
                let headerPart = String(line[line.index(after: line.startIndex)..<colonRange.lowerBound])
                let content = String(line[colonRange.upperBound...])
                let headerParts = headerPart.components(separatedBy: "|")
                let charName = headerParts[0].trimmingCharacters(in: .whitespaces)
                let emotion = headerParts.count > 1 ? headerParts[1].trimmingCharacters(in: .whitespaces) : nil

                // Skip [narrative|emphasis] style — it's a text node handled below
                let isNarrative = charName.lowercased() == "narrative" || charName.lowercased() == "叙述"
                if isNarrative {
                    let emphasis = emphasisFromString(emotion ?? "")
                    let textNode = TextNode(id: nextId(), content: content, emphasis: emphasis)
                    nodes.append(.text(textNode))
                } else {
                    let charId = registry.resolve(charName)
                    let dialogueNode = DialogueNode(id: nextId(), characterId: charId, content: content, emotion: emotion)
                    nodes.append(.dialogue(dialogueNode))
                }
                continue
            }

            // Text node with optional [emphasis] tag at end of line
            if let emphasis = extractEmphasis(from: line) {
                let textContent = removeEmphasisTag(from: line).trimmingCharacters(in: .whitespaces)
                if !textContent.isEmpty {
                    let textNode = TextNode(id: nextId(), content: textContent, emphasis: emphasis)
                    nodes.append(.text(textNode))
                }
            } else {
                let textNode = TextNode(id: nextId(), content: line)
                nodes.append(.text(textNode))
            }
        }

        return Chapter(
            id: metadata.chapterId,
            bookId: metadata.bookId,
            number: metadata.chapterNumber,
            title: metadata.title,
            nodes: nodes,
            isPaid: metadata.isPaid,
            nextChapterHook: metadata.nextChapterHook
        )
    }

    // MARK: - Choice Block Parser

    private func parseChoiceBlock(
        lines: [String],
        startIndex: Int,
        registry: CharacterRegistry,
        effectParser: EffectParser,
        baseId: String
    ) throws -> (ChoiceNode, nextIndex: Int) {
        var i = startIndex
        let headerLine = lines[i].trimmingCharacters(in: .whitespaces)
        i += 1

        // Parse @choice ID [type]
        let (choiceNodeId, choiceType) = parseChoiceHeader(headerLine, fallbackId: baseId)

        // Parse prompt:
        var prompt = ""
        var choices: [Choice] = []
        var choiceCounter = 0

        while i < lines.count {
            let raw = lines[i]
            let line = raw.trimmingCharacters(in: .whitespaces)

            if line == "@end-choice" {
                i += 1
                break
            }

            if line.hasPrefix("prompt:") {
                prompt = line.dropFirst("prompt:".count).trimmingCharacters(in: .whitespaces)
                i += 1
                continue
            }

            // Choice item: - id [type]: text
            if line.hasPrefix("- ") {
                choiceCounter += 1
                let (choice, consumed) = try parseChoiceItem(
                    lines: lines,
                    startIndex: i,
                    registry: registry,
                    effectParser: effectParser,
                    fallbackId: "\(baseId)_\(choiceCounter)"
                )
                choices.append(choice)
                i = consumed
                continue
            }

            i += 1
        }

        guard !choices.isEmpty else {
            throw NovelParseError.invalidChoiceBlock("选择节点 \(choiceNodeId) 没有选项")
        }

        let choiceNode = ChoiceNode(
            id: choiceNodeId,
            prompt: prompt,
            choices: choices,
            timeLimit: nil,
            choiceType: choiceType
        )
        return (choiceNode, i)
    }

    private func parseChoiceHeader(_ line: String, fallbackId: String) -> (String, ChoiceNode.ChoiceType) {
        // "@choice choice_001_01 [keyDecision]" or "@choice [keyDecision]"
        var rest = line.dropFirst("@choice".count).trimmingCharacters(in: .whitespaces)
        var choiceType: ChoiceNode.ChoiceType = .keyDecision
        var choiceId = fallbackId

        if let bracketStart = rest.firstIndex(of: "["),
           let bracketEnd = rest.lastIndex(of: "]") {
            let typeStr = String(rest[rest.index(after: bracketStart)..<bracketEnd])
            choiceType = choiceTypeFrom(typeStr)
            let before = String(rest[rest.startIndex..<bracketStart]).trimmingCharacters(in: .whitespaces)
            if !before.isEmpty { choiceId = before }
            rest = String(rest[rest.index(after: bracketEnd)...]).trimmingCharacters(in: .whitespaces)
        } else if !rest.isEmpty {
            choiceId = rest
        }

        return (choiceId, choiceType)
    }

    private func parseChoiceItem(
        lines: [String],
        startIndex: Int,
        registry: CharacterRegistry,
        effectParser: EffectParser,
        fallbackId: String
    ) throws -> (Choice, nextIndex: Int) {
        var i = startIndex
        let headerLine = lines[i].trimmingCharacters(in: .whitespaces)
        i += 1

        // "- c_001_01_a [直接爽]: 选项文本"
        var itemId = fallbackId
        var satisfactionType: SatisfactionType = .immediatePower
        var text = ""

        let withoutDash = headerLine.dropFirst(2).trimmingCharacters(in: .whitespaces)
        if let colonRange = withoutDash.range(of: "]: ") {
            text = String(withoutDash[colonRange.upperBound...])
            let header = String(withoutDash[withoutDash.startIndex..<colonRange.lowerBound])
            if let bracketStart = header.firstIndex(of: "[") {
                let beforeBracket = String(header[header.startIndex..<bracketStart]).trimmingCharacters(in: .whitespaces)
                let typeStr = String(header[header.index(after: bracketStart)...])
                satisfactionType = satisfactionTypeFrom(typeStr)
                if !beforeBracket.isEmpty { itemId = beforeBracket }
            } else {
                text = String(withoutDash)
            }
        } else {
            text = String(withoutDash)
        }

        // Parse sub-fields (desc:, effects:, relations:, result:)
        var desc: String? = nil
        var statEffects: [StatEffect] = []
        var relationEffects: [RelationshipEffect] = []
        var resultText: String? = nil

        while i < lines.count {
            let subRaw = lines[i]
            let sub = subRaw.trimmingCharacters(in: .whitespaces)

            // End of this choice item
            if sub.hasPrefix("- ") || sub == "@end-choice" || sub.hasPrefix("@choice") { break }
            if sub.isEmpty { i += 1; continue }

            if sub.hasPrefix("desc:") {
                desc = sub.dropFirst("desc:".count).trimmingCharacters(in: .whitespaces)
            } else if sub.hasPrefix("effects:") {
                let effectStr = sub.dropFirst("effects:".count).trimmingCharacters(in: .whitespaces)
                statEffects = try effectParser.parseStatEffects(String(effectStr))
            } else if sub.hasPrefix("relations:") {
                let relStr = sub.dropFirst("relations:".count).trimmingCharacters(in: .whitespaces)
                relationEffects = try effectParser.parseRelationshipEffects(String(relStr))
            } else if sub.hasPrefix("result:") {
                resultText = sub.dropFirst("result:".count).trimmingCharacters(in: .whitespaces)
            }

            i += 1
        }

        let resultNodeIds: [String] = resultText != nil ? ["\(itemId)_result"] : []

        let choice = Choice(
            id: itemId,
            text: text,
            description: desc ?? resultText,
            satisfactionType: satisfactionType,
            statEffects: statEffects,
            relationshipEffects: relationEffects,
            resultNodeIds: resultNodeIds,
            isPremium: false
        )
        return (choice, i)
    }

    // MARK: - Helpers

    private func extractEmphasis(from line: String) -> TextNode.Emphasis? {
        let tags = ["[dramatic]", "[whisper]", "[system]", "[normal]"]
        for tag in tags {
            if line.lowercased().hasSuffix(tag) {
                return emphasisFromString(String(tag.dropFirst().dropLast()))
            }
        }
        return nil
    }

    private func removeEmphasisTag(from line: String) -> String {
        let tags = ["[dramatic]", "[whisper]", "[system]", "[normal]"]
        for tag in tags {
            if line.lowercased().hasSuffix(tag) {
                return String(line.dropLast(tag.count)).trimmingCharacters(in: .whitespaces)
            }
        }
        return line
    }

    private func emphasisFromString(_ s: String) -> TextNode.Emphasis {
        switch s.lowercased() {
        case "dramatic": return .dramatic
        case "whisper": return .whisper
        case "system": return .system
        default: return .normal
        }
    }

    private func choiceTypeFrom(_ s: String) -> ChoiceNode.ChoiceType {
        switch s.lowercased() {
        case "keydecision", "关键抉择": return .keyDecision
        case "stylechoice", "风格选择": return .styleChoice
        case "characterpref", "角色倾向": return .characterPref
        default: return .keyDecision
        }
    }

    private func satisfactionTypeFrom(_ s: String) -> SatisfactionType {
        switch s {
        case "直接爽": return .immediatePower
        case "延迟爽": return .delayedRevenge
        case "阴谋爽": return .cunningScheme
        case "碾压爽": return .dominantCrush
        case "情感爽": return .emotionalPlay
        case "扮猪吃虎": return .undercover
        default: return .immediatePower
        }
    }
}
