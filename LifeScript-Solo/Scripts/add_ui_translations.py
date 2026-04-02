#!/usr/bin/env python3
"""
Add missing UI translation keys to all Localizable.strings files.
Covers:
1. New keys from Phase A (SoloChapterBrowserView, SoloArtworkLibrary, SoloStoryStore, etc.)
2. Sync missing keys from EN to JA/KO
3. Add ZH-Hans self-mappings
"""

import os
import re

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RESOURCES = os.path.join(BASE, "Sources", "LifeScriptSolo", "Resources")

def read_existing_keys(filepath):
    """Read existing keys from a Localizable.strings file."""
    keys = set()
    if not os.path.exists(filepath):
        return keys
    with open(filepath, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            m = re.match(r'^"(.+?)"\s*=\s*"', line)
            if m:
                keys.add(m.group(1))
    return keys

def append_entries(filepath, entries, section_comment=""):
    """Append key-value entries to a Localizable.strings file."""
    with open(filepath, "a", encoding="utf-8") as f:
        if section_comment:
            f.write(f"\n/* {section_comment} */\n")
        for key, value in entries:
            # Escape quotes in value
            escaped_value = value.replace('"', '\\"')
            escaped_key = key.replace('"', '\\"')
            f.write(f'"{escaped_key}" = "{escaped_value}";\n')

# ============================================================
# NEW KEYS FROM PHASE A (UI hardcoded Chinese → localized)
# ============================================================

# SoloChapterBrowserView keys
chapter_browser_en = [
    ("章节目录", "Chapter Browser"),
    ("阅读进度", "Reading Progress"),
    ("第%d章", "Chapter %d"),
    ("尚未开始阅读", "Not Started Reading"),
    ("已读 %d 章", "%d Chapters Read"),
    ("共 %d 章", "%d Chapters Total"),
    ("第%d–%d章 · 共%d节", "Ch. %d–%d · %d Sections"),
    ("免费", "Free"),
    ("已解锁", "Unlocked"),
    ("本卷需解锁后阅读", "Unlock This Volume to Read"),
    ("单卷永久解锁", "Permanent Volume Unlock"),
    ("支持恢复购买", "Restore Purchase Supported"),
    ("正在处理购买…", "Processing Purchase..."),
    ("阅读中", "Reading"),
]

chapter_browser_ja = [
    ("章节目录", "章節一覧"),
    ("阅读进度", "読書進捗"),
    ("第%d章", "第%d章"),
    ("尚未开始阅读", "まだ読み始めていません"),
    ("已读 %d 章", "%d章 読了"),
    ("共 %d 章", "全%d章"),
    ("第%d–%d章 · 共%d节", "第%d–%d章 · 全%d節"),
    ("免费", "無料"),
    ("已解锁", "解放済み"),
    ("本卷需解锁后阅读", "この巻はロック解除後にお読みいただけます"),
    ("单卷永久解锁", "巻ごとの永久ロック解除"),
    ("支持恢复购买", "購入復元対応"),
    ("正在处理购买…", "購入処理中…"),
    ("阅读中", "読書中"),
]

chapter_browser_ko = [
    ("章节目录", "챕터 목록"),
    ("阅读进度", "읽기 진행"),
    ("第%d章", "제%d장"),
    ("尚未开始阅读", "아직 읽기 시작하지 않았습니다"),
    ("已读 %d 章", "%d장 읽음"),
    ("共 %d 章", "총 %d장"),
    ("第%d–%d章 · 共%d节", "제%d–%d장 · 총%d절"),
    ("免费", "무료"),
    ("已解锁", "잠금 해제됨"),
    ("本卷需解锁后阅读", "이 권은 잠금 해제 후 읽을 수 있습니다"),
    ("单卷永久解锁", "권별 영구 잠금 해제"),
    ("支持恢复购买", "구매 복원 지원"),
    ("正在处理购买…", "구매 처리 중…"),
    ("阅读中", "읽는 중"),
]

# SoloVolumeStore error messages
volume_store_en = [
    ("当前卷商品还没有在 App Store Connect 配好，请先补齐内购商品。", "This volume's product is not yet configured in App Store Connect. Please set up the in-app purchase product first."),
    ("交易校验失败，本次解锁没有生效。", "Transaction verification failed. This unlock did not take effect."),
]

volume_store_ja = [
    ("当前卷商品还没有在 App Store Connect 配好，请先补齐内购商品。", "この巻の商品はまだApp Store Connectで設定されていません。先にアプリ内課金商品を設定してください。"),
    ("交易校验失败，本次解锁没有生效。", "取引の検証に失敗しました。このロック解除は有効になりませんでした。"),
]

volume_store_ko = [
    ("当前卷商品还没有在 App Store Connect 配好，请先补齐内购商品。", "이 권의 상품이 아직 App Store Connect에서 설정되지 않았습니다. 인앱 구매 상품을 먼저 설정해 주세요."),
    ("交易校验失败，本次解锁没有生效。", "거래 검증에 실패했습니다. 이번 잠금 해제가 적용되지 않았습니다."),
]

# SoloStoryStore RouteMap keys
routemap_en = [
    ("迷雾初开", "Mist Clearing"),
    ("继续推进眼前章节，新的征兆会在行动后显形。", "Continue advancing through the current chapter. New signs will emerge after your actions."),
    ("当前命局停在「%@」，你已经走完 %d 章。", "Current fate stopped at '%@', you've completed %d chapters."),
    ("暗线仍在潜伏，先稳住当前局面。", "Hidden threads still lurk beneath. Stabilize the current situation first."),
    ("已有 %d 条异动露头，别让节奏被暗线牵走。", "%d anomalies have surfaced. Don't let hidden threads dictate your pace."),
    ("天命值 %d · %@", "Destiny %d · %@"),
    ("命途", "Destiny Path"),
    ("看已行之路、眼前棋局与将至征兆", "View the path traveled, the current game, and signs to come"),
    ("当前阶段：%@ · 显形进度 %@", "Current stage: %@ · Progress %@"),
    ("待显形", "Unrevealed"),
    ("在局中", "In Play"),
    ("进入命途推演", "Enter Destiny Path"),
    ("人心", "Hearts"),
    ("看谁已入局、谁可试探、谁需警惕", "See who's in play, who to probe, who to watch"),
    ("%d 人在局", "%d in play"),
    ("进入人心盘", "Enter Hearts Board"),
    ("暗线", "Hidden Threads"),
    ("看异动、疑云与未显形缺口", "View anomalies, doubts, and unrevealed gaps"),
    ("%d 已识别", "%d identified"),
    ("进入暗线观测", "Enter Thread Watch"),
]

routemap_ja = [
    ("迷雾初开", "霧が晴れ始める"),
    ("继续推进眼前章节，新的征兆会在行动后显形。", "現在の章を進めてください。新たな兆しが行動の後に現れます。"),
    ("当前命局停在「%@」，你已经走完 %d 章。", "現在の命局は「%@」で止まっています。%d章を読み終えました。"),
    ("暗线仍在潜伏，先稳住当前局面。", "暗線はまだ潜伏中。まず現状を安定させましょう。"),
    ("已有 %d 条异动露头，别让节奏被暗线牵走。", "%d件の異変が浮上しています。暗線にペースを乱されないように。"),
    ("天命值 %d · %@", "天命値 %d · %@"),
    ("命途", "命途"),
    ("看已行之路、眼前棋局与将至征兆", "歩んだ道、目の前の局面、そして来たる兆しを見る"),
    ("当前阶段：%@ · 显形进度 %@", "現在の段階：%@ · 顕現進度 %@"),
    ("待显形", "未顕現"),
    ("在局中", "局中"),
    ("进入命途推演", "命途推演に入る"),
    ("人心", "人心"),
    ("看谁已入局、谁可试探、谁需警惕", "誰が局中にいるか、誰を探れるか、誰に警戒すべきかを見る"),
    ("%d 人在局", "%d人が局中"),
    ("进入人心盘", "人心盤に入る"),
    ("暗线", "暗線"),
    ("看异动、疑云与未显形缺口", "異変、疑惑、未顕現の隙間を見る"),
    ("%d 已识别", "%d件 識別済み"),
    ("进入暗线观测", "暗線観測に入る"),
]

routemap_ko = [
    ("迷雾初开", "안개가 걷히다"),
    ("继续推进眼前章节，新的征兆会在行动后显形。", "현재 챕터를 계속 진행하세요. 새로운 징조가 행동 후에 나타날 것입니다."),
    ("当前命局停在「%@」，你已经走完 %d 章。", "현재 운명의 국면이 '%@'에 머물러 있으며, %d장을 완료했습니다."),
    ("暗线仍在潜伏，先稳住当前局面。", "암선이 아직 잠복 중입니다. 현재 상황을 먼저 안정시키세요."),
    ("已有 %d 条异动露头，别让节奏被暗线牵走。", "%d개의 이상 징후가 드러났습니다. 암선에 페이스를 빼앗기지 마세요."),
    ("天命值 %d · %@", "천명치 %d · %@"),
    ("命途", "운명의 길"),
    ("看已行之路、眼前棋局与将至征兆", "걸어온 길, 눈앞의 판세, 다가올 징조를 봅니다"),
    ("当前阶段：%@ · 显形进度 %@", "현재 단계: %@ · 현현 진행 %@"),
    ("待显形", "미현현"),
    ("在局中", "국중"),
    ("进入命途推演", "운명의 길 진입"),
    ("人心", "인심"),
    ("看谁已入局、谁可试探、谁需警惕", "누가 판에 있는지, 누구를 탐색할지, 누구를 경계할지 봅니다"),
    ("%d 人在局", "%d명 판 안에"),
    ("进入人心盘", "인심판 진입"),
    ("暗线", "암선"),
    ("看异动、疑云与未显形缺口", "이상 징후, 의혹, 미현현 공백을 봅니다"),
    ("%d 已识别", "%d건 식별됨"),
    ("进入暗线观测", "암선 관측 진입"),
]

# Dossier stat card titles
dossier_stats_en = [
    # Tianjilu
    ("落子", "Move"), ("牌面", "Face"), ("机锋", "Wit"), ("残页", "Pages"),
    ("心魇", "Nightmare"), ("天命", "Destiny"),
    # Cultivation
    ("剑势", "Sword Force"), ("声名", "Renown"), ("灵资", "Spirit Resources"),
    ("气度", "Bearing"),
    # Business War
    ("压制力", "Pressure"), ("声望", "Prestige"), ("筹谋", "Scheming"),
    ("资本", "Capital"), ("游说", "Persuasion"), ("代价", "Cost"), ("风向", "Winds"),
    # Suspense
    ("求生", "Survival"), ("暴露", "Exposure"), ("判断", "Judgment"),
    ("物资", "Supplies"), ("说服", "Convince"), ("污染", "Corruption"), ("直觉", "Intuition"),
    # Apocalypse
    ("战备", "War Ready"), ("声噪", "Notoriety"), ("决断", "Resolve"),
    ("补给", "Supply"), ("凝聚", "Unity"), ("异化", "Mutation"), ("火种", "Spark"),
    # Urban
    ("锋芒", "Edge"), ("手段", "Means"), ("底气", "Confidence"),
    ("拿捏", "Leverage"), ("反噬", "Backlash"), ("势头", "Momentum"),
]

dossier_stats_ja = [
    ("落子", "落子"), ("牌面", "面子"), ("机锋", "機鋒"), ("残页", "残頁"),
    ("心魇", "心魘"), ("天命", "天命"),
    ("剑势", "剣勢"), ("声名", "声名"), ("灵资", "霊資"), ("气度", "気度"),
    ("压制力", "圧制力"), ("声望", "声望"), ("筹谋", "策謀"),
    ("资本", "資本"), ("游说", "遊説"), ("代价", "代償"), ("风向", "風向"),
    ("求生", "生存"), ("暴露", "露出"), ("判断", "判断"),
    ("物资", "物資"), ("说服", "説得"), ("污染", "汚染"), ("直觉", "直感"),
    ("战备", "戦備"), ("声噪", "悪名"), ("决断", "決断"),
    ("补给", "補給"), ("凝聚", "結束"), ("异化", "異化"), ("火种", "火種"),
    ("锋芒", "鋭さ"), ("手段", "手段"), ("底气", "自信"),
    ("拿捏", "駆け引き"), ("反噬", "反噬"), ("势头", "勢い"),
]

dossier_stats_ko = [
    ("落子", "수 놓기"), ("牌面", "면자"), ("机锋", "기봉"), ("残页", "잔편"),
    ("心魇", "심마"), ("天命", "천명"),
    ("剑势", "검세"), ("声名", "명성"), ("灵资", "영자"), ("气度", "기도"),
    ("压制力", "압제력"), ("声望", "명망"), ("筹谋", "모략"),
    ("资本", "자본"), ("游说", "유세"), ("代价", "대가"), ("风向", "풍향"),
    ("求生", "생존"), ("暴露", "노출"), ("判断", "판단"),
    ("物资", "물자"), ("说服", "설득"), ("污染", "오염"), ("直觉", "직감"),
    ("战备", "전비"), ("声噪", "악명"), ("决断", "결단"),
    ("补给", "보급"), ("凝聚", "결속"), ("异化", "이화"), ("火种", "불씨"),
    ("锋芒", "날카로움"), ("手段", "수단"), ("底气", "자신감"),
    ("拿捏", "주도권"), ("反噬", "역습"), ("势头", "기세"),
]

# Dossier module card titles and descriptions
dossier_modules_en = [
    ("天机余裕", "Tianji Buffer"),
    ("天命越高，你越能提前窥一步；机锋越足，你越能把这一步伪装成顺势而为。", "Higher destiny lets you glimpse one step ahead; sharper wit lets you disguise that step as natural."),
    ("关系阈值", "Relationship Threshold"),
    ("%d 条可牵引线", "%d manipulable threads"),
    ("真正关键的不是绝对好感，而是谁既愿意信你、又还没完全看穿你。", "What truly matters isn't absolute affection, but who trusts you yet hasn't fully seen through you."),
    ("暗线牵引", "Hidden Thread Pull"),
    ("残页、机锋与人心正在一起拖动暗线。你手里的筹码越多，盯着你的人也越多。", "Pages, wit, and hearts are dragging hidden threads together. The more chips you hold, the more eyes watch you."),
    ("境界势能", "Realm Momentum"),
    ("战力与天命正在共同抬升你的破境势能，黑化值越高，后续代价越重。", "Combat and destiny raise your breakthrough momentum. Higher darkness means heavier costs ahead."),
    ("人脉因果", "Karma Network"),
    ("%d 条稳固线", "%d stable threads"),
    ("真正能替你挡劫的不是嘴上的盟友，而是高信任与高敬畏叠起来的关系。", "Those who truly shield you aren't verbal allies, but relationships built on trust and reverence."),
    ("名望与筹码", "Fame & Stakes"),
    ("名望决定你是否被看见，财富和谋略决定你被看见之后有没有资格继续压局。", "Fame determines if you're seen. Wealth and strategy determine if you can keep pressing after."),
    ("杠杆总量", "Total Leverage"),
    ("真正有用的不是你手里有什么，而是你能逼对方以为你还有什么。", "What's useful isn't what you have, but what you can make others believe you have."),
    ("牌桌信号", "Table Signals"),
    ("%d 人偏向你", "%d leaning your way"),
    ("高信任并不一定可靠，但低信任一定会在关键回合动摇。", "High trust isn't always reliable, but low trust will always waver at critical moments."),
    ("反噬风险", "Backlash Risk"),
    ("你压住的敌意越多，后面需要付出的切割成本就越大。", "The more hostility you suppress, the greater the severing cost later."),
    ("威胁浓度", "Threat Density"),
    ("敌意与黑化并行升高时，说明危险不只在外面，也开始向你体内渗透。", "When hostility and darkness rise together, danger isn't just external—it's seeping inward."),
    ("线索清晰度", "Clue Clarity"),
    ("谋略与直觉越高，越能在碎片信息里看见真正的因果链。", "Higher strategy and intuition help you spot the real causal chain in fragmented information."),
    ("安全锚点", "Safe Anchors"),
    ("%d 个", "%d"),
    ("在高压故事里，能否找到真正的安全锚点，比一时赢一局更重要。", "In high-pressure stories, finding a true safe anchor matters more than winning a single round."),
    ("避难区承压", "Shelter Pressure"),
    ("越多人知道你手里握着钥匙，越多人会把恐惧和怨气一起压到你身上。", "The more people know you hold the key, the more fear and resentment they pile onto you."),
    ("队伍信号", "Team Signals"),
    ("%d 条稳定线", "%d stable lines"),
    ("真正能陪你熬过断电夜的，不是嘴上说愿意，而是在高压下仍愿意跟着你的人。", "Those who truly survive the blackout night with you aren't those who say they will, but those who stay under pressure."),
    ("生存筹码", "Survival Stakes"),
    ("补给、判断和那点还没熄掉的火种，决定你接下来是守住秩序，还是被局势反咬。", "Supplies, judgment, and that spark still burning decide whether you hold order or get bitten back."),
    ("翻盘势能", "Reversal Momentum"),
    ("翻盘从来不是一拳打回去，而是你在对方以为稳了的时候突然反过来控局。", "Reversal isn't punching back—it's seizing control the moment they think they've won."),
    ("场面筹码", "Social Capital"),
    ("名望、魅力和财富共同决定你在公开场面上的压制力。", "Fame, charm, and wealth together determine your dominance in public."),
    ("站队倾向", "Alignment Tendency"),
    ("%d 人", "%d people"),
    ("站队不是口头支持，而是对方在关键节点是否愿意替你付代价。", "Alignment isn't verbal support—it's whether they'll pay the price for you at critical moments."),
]

dossier_modules_ja = [
    ("天机余裕", "天機余裕"),
    ("天命越高，你越能提前窥一步；机锋越足，你越能把这一步伪装成顺势而为。", "天命が高いほど一手先を覗けます。機鋒が鋭いほど、その一手を自然な流れに偽装できます。"),
    ("关系阈值", "関係閾値"),
    ("%d 条可牵引线", "%d本の操作可能な線"),
    ("真正关键的不是绝对好感，而是谁既愿意信你、又还没完全看穿你。", "本当に重要なのは絶対的な好感度ではなく、あなたを信じつつもまだ完全に見破っていない人です。"),
    ("暗线牵引", "暗線牽引"),
    ("残页、机锋与人心正在一起拖动暗线。你手里的筹码越多，盯着你的人也越多。", "残頁、機鋒、人心が一緒に暗線を引っ張っています。手持ちの駒が多いほど、見張る目も多くなります。"),
    ("境界势能", "境界勢能"),
    ("战力与天命正在共同抬升你的破境势能，黑化值越高，后续代价越重。", "戦力と天命が共に破境勢能を押し上げています。黒化値が高いほど、その後の代償は重くなります。"),
    ("人脉因果", "人脈因果"),
    ("%d 条稳固线", "%d本の安定した線"),
    ("真正能替你挡劫的不是嘴上的盟友，而是高信任与高敬畏叠起来的关系。", "本当にあなたの身代わりになれるのは口先の盟友ではなく、高い信頼と畏敬が重なった関係です。"),
    ("名望与筹码", "名望と駒"),
    ("名望决定你是否被看见，财富和谋略决定你被看见之后有没有资格继续压局。", "名望はあなたが見られるかを決め、財と謀略は見られた後に局を押し続ける資格があるかを決めます。"),
    ("杠杆总量", "レバレッジ総量"),
    ("真正有用的不是你手里有什么，而是你能逼对方以为你还有什么。", "本当に役立つのは手元にあるものではなく、相手にまだ何かあると思わせる力です。"),
    ("牌桌信号", "テーブルシグナル"),
    ("%d 人偏向你", "%d人があなた寄り"),
    ("高信任并不一定可靠，但低信任一定会在关键回合动摇。", "高い信頼は必ずしも頼りになりませんが、低い信頼は必ず重要な場面で揺らぎます。"),
    ("反噬风险", "反噬リスク"),
    ("你压住的敌意越多，后面需要付出的切割成本就越大。", "抑えた敵意が多いほど、後の切断コストは大きくなります。"),
    ("威胁浓度", "脅威濃度"),
    ("敌意与黑化并行升高时，说明危险不只在外面，也开始向你体内渗透。", "敵意と黒化が同時に上がるとき、危険は外だけでなく内側にも浸透し始めています。"),
    ("线索清晰度", "手掛かりの明瞭度"),
    ("谋略与直觉越高，越能在碎片信息里看见真正的因果链。", "謀略と直感が高いほど、断片的な情報から本当の因果関係を見出せます。"),
    ("安全锚点", "安全アンカー"),
    ("%d 个", "%d個"),
    ("在高压故事里，能否找到真正的安全锚点，比一时赢一局更重要。", "高圧的な物語では、真の安全アンカーを見つけることは一時的な勝利より重要です。"),
    ("避难区承压", "避難区負荷"),
    ("越多人知道你手里握着钥匙，越多人会把恐惧和怨气一起压到你身上。", "鍵を握っていると知る人が増えるほど、恐怖と不満があなたに向けられます。"),
    ("队伍信号", "チームシグナル"),
    ("%d 条稳定线", "%d本の安定した線"),
    ("真正能陪你熬过断电夜的，不是嘴上说愿意，而是在高压下仍愿意跟着你的人。", "停電の夜を共に耐えられるのは、口先で同意する人ではなく、高圧下でもついてくる人です。"),
    ("生存筹码", "生存の駒"),
    ("补给、判断和那点还没熄掉的火种，决定你接下来是守住秩序，还是被局势反咬。", "補給、判断、そしてまだ消えていない火種が、秩序を守れるか局勢に逆襲されるかを決めます。"),
    ("翻盘势能", "逆転勢能"),
    ("翻盘从来不是一拳打回去，而是你在对方以为稳了的时候突然反过来控局。", "逆転は殴り返すことではなく、相手が安心した瞬間に局を奪うことです。"),
    ("场面筹码", "社交資本"),
    ("名望、魅力和财富共同决定你在公开场面上的压制力。", "名望、魅力、財が共に公の場でのあなたの圧制力を決めます。"),
    ("站队倾向", "陣営傾向"),
    ("%d 人", "%d人"),
    ("站队不是口头支持，而是对方在关键节点是否愿意替你付代价。", "陣営選びは口先の支持ではなく、重要な場面であなたの代わりに代償を払うかどうかです。"),
]

dossier_modules_ko = [
    ("天机余裕", "천기 여유"),
    ("天命越高，你越能提前窥一步；机锋越足，你越能把这一步伪装成顺势而为。", "천명이 높을수록 한 수 앞을 엿볼 수 있고, 기봉이 날카로울수록 그 한 수를 자연스러운 흐름으로 위장할 수 있습니다."),
    ("关系阈值", "관계 임계값"),
    ("%d 条可牵引线", "%d개의 조종 가능한 선"),
    ("真正关键的不是绝对好感，而是谁既愿意信你、又还没完全看穿你。", "정말 중요한 것은 절대적 호감도가 아니라, 당신을 믿으면서도 아직 완전히 꿰뚫지 못한 사람입니다."),
    ("暗线牵引", "암선 견인"),
    ("残页、机锋与人心正在一起拖动暗线。你手里的筹码越多，盯着你的人也越多。", "잔편, 기봉, 인심이 함께 암선을 끌어당기고 있습니다. 패가 많을수록 당신을 노리는 눈도 많아집니다."),
    ("境界势能", "경계 세능"),
    ("战力与天命正在共同抬升你的破境势能，黑化值越高，后续代价越重。", "전투력과 천명이 함께 돌파 세능을 높이고 있습니다. 흑화치가 높을수록 이후의 대가는 무거워집니다."),
    ("人脉因果", "인맥 인과"),
    ("%d 条稳固线", "%d개의 안정적인 선"),
    ("真正能替你挡劫的不是嘴上的盟友，而是高信任与高敬畏叠起来的关系。", "진정으로 당신을 대신 막아줄 수 있는 건 말뿐인 동맹이 아니라, 높은 신뢰와 경외가 겹쳐진 관계입니다."),
    ("名望与筹码", "명망과 패"),
    ("名望决定你是否被看见，财富和谋略决定你被看见之后有没有资格继续压局。", "명망은 보이느냐를 결정하고, 재물과 모략은 보인 후에 판을 계속 누를 자격이 있느냐를 결정합니다."),
    ("杠杆总量", "레버리지 총량"),
    ("真正有用的不是你手里有什么，而是你能逼对方以为你还有什么。", "진짜 유용한 것은 손에 있는 게 아니라, 상대가 아직 뭔가 있다고 믿게 만드는 힘입니다."),
    ("牌桌信号", "테이블 시그널"),
    ("%d 人偏向你", "%d명이 당신 편으로"),
    ("高信任并不一定可靠，但低信任一定会在关键回合动摇。", "높은 신뢰가 반드시 믿을 만하진 않지만, 낮은 신뢰는 반드시 결정적인 순간에 흔들립니다."),
    ("反噬风险", "역습 위험"),
    ("你压住的敌意越多，后面需要付出的切割成本就越大。", "억누른 적의가 많을수록 나중에 치러야 할 절단 비용이 커집니다."),
    ("威胁浓度", "위협 농도"),
    ("敌意与黑化并行升高时，说明危险不只在外面，也开始向你体内渗透。", "적의와 흑화가 동시에 상승할 때, 위험은 바깥에만 있는 게 아니라 안으로도 스며들기 시작합니다."),
    ("线索清晰度", "단서 명확도"),
    ("谋略与直觉越高，越能在碎片信息里看见真正的因果链。", "모략과 직감이 높을수록 파편 정보에서 진정한 인과 사슬을 볼 수 있습니다."),
    ("安全锚点", "안전 앵커"),
    ("%d 个", "%d개"),
    ("在高压故事里，能否找到真正的安全锚点，比一时赢一局更重要。", "고압적 스토리에서 진정한 안전 앵커를 찾는 것은 한 판 이기는 것보다 중요합니다."),
    ("避难区承压", "피난구 부하"),
    ("越多人知道你手里握着钥匙，越多人会把恐惧和怨气一起压到你身上。", "열쇠를 쥐고 있다는 걸 아는 사람이 많을수록, 두려움과 원망이 당신에게 쏠립니다."),
    ("队伍信号", "팀 시그널"),
    ("%d 条稳定线", "%d개의 안정적인 선"),
    ("真正能陪你熬过断电夜的，不是嘴上说愿意，而是在高压下仍愿意跟着你的人。", "정전의 밤을 함께 버텨줄 사람은 입으로 하겠다는 사람이 아니라, 고압 속에서도 따르는 사람입니다."),
    ("生存筹码", "생존의 패"),
    ("补给、判断和那点还没熄掉的火种，决定你接下来是守住秩序，还是被局势反咬。", "보급, 판단, 그리고 아직 꺼지지 않은 불씨가 질서를 지킬지 상황에 역습당할지를 결정합니다."),
    ("翻盘势能", "역전 세능"),
    ("翻盘从来不是一拳打回去，而是你在对方以为稳了的时候突然反过来控局。", "역전은 되받아치는 게 아니라, 상대가 안심한 순간 판을 뒤집는 것입니다."),
    ("场面筹码", "사교 자본"),
    ("名望、魅力和财富共同决定你在公开场面上的压制力。", "명망, 매력, 재물이 함께 공개 장소에서의 압제력을 결정합니다."),
    ("站队倾向", "진영 경향"),
    ("%d 人", "%d명"),
    ("站队不是口头支持，而是对方在关键节点是否愿意替你付代价。", "편들기는 구두 지지가 아니라, 상대가 결정적 순간에 당신 대신 대가를 치를 의향이 있느냐입니다."),
]

# Artwork Library translations
artwork_en = [
    # Welcome & Hero
    ("卷一 · 废材觉醒", "Vol. 1 · Wastrel Awakens"),
    ("命书初亮，棋局开场", "The fate book first gleams, the game begins"),
    ("第一次看见残页发光之前，陈机只是宗门里最不值得被注意的人。", "Before seeing the remnant pages glow for the first time, Chen Ji was the least noticed person in the sect."),
    ("天机录残页", "Tianji Records Remnant"),
    ("改命的代价，从翻开它开始。", "The price of changing fate begins when you open it."),
    ("仙域绘卷", "Celestial Realm Scroll"),
    ("浮山、云海与命纹一起张开。", "Floating mountains, cloud seas, and fate lines unfurl together."),
    ("首页不再只是封面，而是《天机录》世界在你眼前缓缓显形的第一镜。", "The homepage is no longer just a cover—it's the first lens through which Tianji Records slowly reveals itself."),
    ("天机棋局", "Tianji Chess Game"),
    ("众生还没落子，因果已经先动。", "Before anyone makes a move, cause and effect have already shifted."),
    ("《天机录》的视觉核心不是打斗，而是预见、布局与改命。", "The visual core of Tianji Records isn't combat—it's foresight, strategy, and fate-changing."),
    ("识海观测", "Mind Sea Observation"),
    ("命途、人心与暗线都该被分层看清。", "Destiny, hearts, and hidden threads should all be seen in layers."),
    ("命途图不再只是文字列表，而是一张能回看整条因果链的战局面板。", "The destiny map is no longer just text—it's a panel for reviewing the entire causal chain."),
    ("天青宗内门", "Inner Sect of Tianqing"),
    ("每个关键人物，都有自己的一面局。", "Every key character has their own game to play."),
    ("人物页不只是关系值，而是带立绘、态度、局重和建议的完整角色面板。", "Character pages aren't just relationship values—they're complete panels with portraits, attitudes, stakes, and advice."),
    ("每一次动用，都在让命数重新对齐。", "Every use realigns the numbers of fate."),
    ("天道棋盘", "Heaven's Chessboard"),
    ("暗线不是彩蛋，而是仍在等待你触发的另一盘棋。", "Hidden threads aren't Easter eggs—they're another game waiting for you to trigger."),
    # Character portraits
    ("陈机", "Chen Ji"),
    ("杂役灰袍下的第一层伪装", "The first disguise beneath a servant's grey robe"),
    ("真正的威胁不在他看上去有多强，而在他总是比别人先知道一步。", "The real threat isn't how strong he looks, but that he always knows one step ahead."),
    ("苏青瑶", "Su Qingyao"),
    ("冷锋一样的首席剑修", "Chief sword cultivator sharp as a cold front"),
    ("信任、警惕与欣赏会同时出现在她的关系线上。", "Trust, vigilance, and admiration appear simultaneously on her relationship line."),
    ("夜清", "Ye Qing"),
    ("危险与好奇并存的魔道圣女", "The demon path saintess where danger and curiosity coexist"),
    ("她既可能是最锋利的盟友，也可能是最昂贵的赌注。", "She could be the sharpest ally or the most costly gamble."),
    ("凌渊", "Ling Yuan"),
    ("仁善外衣下的旧棋手", "An old chess player beneath a benevolent exterior"),
    ("真正难读的不是他的表情，而是他到底把你放在棋盘哪一格。", "What's truly hard to read isn't his expression, but which square he's placed you on the board."),
    ("韩烈", "Han Lie"),
    ("玄武宗最锋利的明牌", "Xuanwu Sect's sharpest known card"),
    ("他代表的不是阴谋，而是能够直接撞碎布局的暴烈正面。", "He doesn't represent conspiracy, but the violent directness that can shatter any layout."),
    ("墨先生", "Mr. Mo"),
    ("残页里的旧时代见证者", "A witness of old times within the remnant pages"),
    ("当他愿意说真话时，往往意味着更大的代价已经靠近。", "When he speaks truth, it often means a greater price is approaching."),
    ("陈念", "Chen Nian"),
    ("陈机最柔软也最危险的命门", "Chen Ji's softest yet most dangerous weakness"),
    ("她不是背景设定，而是整条命途里最不能输掉的一枚核心子。", "She's not background lore—she's the core piece that must not be lost in the entire fate path."),
    ("天道之眼", "Eye of Heaven"),
    ("抬头时，你看到的是世界正在回看你。", "When you look up, you see the world looking back at you."),
    ("它让《天机录》的终局不只是一场争斗，而是与命运本身对局。", "It makes the finale of Tianji Records not just a battle, but a game against fate itself."),
    # Volume visuals
    ("卷一", "Vol. 1"), ("废材觉醒", "Wastrel Awakens"),
    ("命数第一次回响，真正的陈机从这里开始出手。", "Fate echoes for the first time. The real Chen Ji begins to act."),
    ("天青宗", "Tianqing Sect"),
    ("局从宗门最底层开始长出来。", "The game grows from the sect's lowest level."),
    ("关键帧", "Keyframe"),
    ("天机录初次激活", "Tianji Records First Activation"),
    ("你第一次意识到，这不是一件法宝，而是一张会反噬使用者的命书。", "You first realize this isn't a treasure—it's a fate book that bites back."),
    ("卷二", "Vol. 2"), ("宗门暗战", "Sect Shadow War"),
    ("从外门到内门，明面秩序开始被暗线撬动。", "From outer to inner gates, the surface order begins to be pried open by hidden threads."),
    ("内门深处", "Deep Inner Sect"),
    ("真正危险的，不是刀，而是知道你底牌的人。", "The real danger isn't the blade, but those who know your hand."),
    ("苏青瑶逼近真相", "Su Qingyao Approaches Truth"),
    ("关系线在这里不再只是好感，而开始牵扯立场和试探。", "Relationship lines here are no longer just affection—they involve positions and probing."),
    ("卷三", "Vol. 3"), ("秘境争锋", "Secret Realm Contest"),
    ("局第一次被拉到宗门之外，真相与资源同时变得稀缺。", "The game extends beyond the sect for the first time. Truth and resources become scarce."),
    ("上古秘境", "Ancient Secret Realm"),
    ("外部势力入局后，每一步都不再只影响一宗。", "After external forces join, every step affects more than one sect."),
    ("扮猪吃虎反转", "Hidden Dragon Reversal"),
    ("真正的爽点来自提前铺好的后手终于被你亲手点燃。", "The real thrill comes from finally igniting the backup plans you laid in advance."),
    ("卷四", "Vol. 4"), ("魔道渗透", "Demon Path Infiltration"),
    ("正魔边界开始失真，盟友与敌人的定义一起松动。", "The boundary between righteous and demonic blurs. Definitions of ally and enemy loosen."),
    ("魔道圣宗", "Demon Sacred Sect"),
    ("一切合作都带着代价，一切代价都在改写命途。", "Every cooperation carries a price. Every price rewrites fate."),
    ("夜清黑雾救援", "Ye Qing's Dark Mist Rescue"),
    ("当她出手时，危险和吸引往往会同时靠近。", "When she acts, danger and allure often approach together."),
    ("卷五", "Vol. 5"), ("天命反噬", "Fate Backlash"),
    ("越想快一步赢，命书就越会向你讨回代价。", "The more you rush to win, the more the fate book demands its price."),
    ("识海深处", "Depths of Mind Sea"),
    ("这时最可怕的敌人，可能是你自己。", "At this point, the most terrifying enemy might be yourself."),
    ("假死逃脱", "Feigned Death Escape"),
    ("反转不只是逃出生天，更是主动把别人送进你安排的误判。", "Reversal isn't just escaping death—it's sending others into the misjudgment you arranged."),
    ("卷六", "Vol. 6"), ("大陆格局", "Continental Landscape"),
    ("从宗门一局，正式走到天下一局。", "From a sect-level game to a continent-wide game."),
    ("皇朝京城", "Imperial Capital"),
    ("棋盘被放大之后，谁都不再只是配角。", "Once the board expands, no one is just a supporting character."),
    ("统筹各方势力", "Coordinating All Factions"),
    ("这是《天机录》最游戏化的一段，所有之前积累的关系与判断都开始兑现。", "This is the most game-like part of Tianji Records. All accumulated relationships and judgments begin to pay off."),
    ("卷七", "Vol. 7"), ("上古真相", "Ancient Truth"),
    ("你终于开始接近命书本身为什么会存在。", "You finally begin to approach why the fate book exists."),
    ("陈玄遗迹", "Chenxuan Ruins"),
    ("旧时代留下来的，从来不只有答案。", "What the old era left behind was never just answers."),
    ("墨先生浮现", "Mr. Mo Emerges"),
    ("当旧时代真正说话时，世界观也会跟着一起翻面。", "When the old era truly speaks, the worldview flips with it."),
    ("卷八", "Vol. 8"), ("魔道大战", "Demon War"),
    ("局面全面失控时，你的每个决定都开始影响阵营级后果。", "When the situation spirals, every decision affects faction-level consequences."),
    ("三宗激战", "Three Sects Battle"),
    ("到了这一卷，任何一步迟疑都会被放大。", "By this volume, any hesitation gets amplified."),
    ("凌渊面具破碎", "Ling Yuan's Mask Shatters"),
    ("真正震荡玩家的，不是揭晓，而是你终于看懂他一直在算什么。", "What truly shakes the player isn't the reveal, but finally understanding what he'd been calculating."),
    ("卷九", "Vol. 9"), ("天道裂变", "Heaven's Fracture"),
    ("《天机录》的终盘不只是对人，而是对天道本身。", "The endgame of Tianji Records isn't just against people—it's against heaven itself."),
    ("天道棋盘", "Heaven's Chessboard"),
    ("你看见的不是未来，而是未来如何试图吞掉你。", "What you see isn't the future—it's how the future tries to devour you."),
    ("陈机对抗天道之眼", "Chen Ji vs Eye of Heaven"),
    ("抬头那一刻，故事正式从权谋修仙跃迁到命运战争。", "The moment you look up, the story leaps from political cultivation to fate warfare."),
    ("卷十", "Vol. 10"), ("棋局终局", "Endgame"),
    ("一切分支、好感、暗线与命数压力都会在这里汇合。", "All branches, relationships, hidden threads, and fate pressure converge here."),
    ("终局前夜", "Night Before Endgame"),
    ("你终于走到那枚最后的未落之子面前。", "You finally stand before the last unplaced piece."),
    ("踏出预言之外", "Beyond Prophecy"),
    ("最好的结局感，不是赢，而是你真的把自己从既定命运里拿了出来。", "The best ending isn't winning—it's truly pulling yourself free from predetermined fate."),
    # Volume labels
    ("卷二 · 宗门暗战", "Vol. 2 · Sect Shadow War"),
    ("卷三 · 秘境争锋", "Vol. 3 · Secret Realm Contest"),
    ("卷四 · 魔道渗透", "Vol. 4 · Demon Infiltration"),
    ("卷五 · 天命反噬", "Vol. 5 · Fate Backlash"),
    ("卷六 · 大陆格局", "Vol. 6 · Continental Landscape"),
    ("卷七 · 上古真相", "Vol. 7 · Ancient Truth"),
    ("卷八 · 魔道大战", "Vol. 8 · Demon War"),
    ("卷九 · 天道裂变", "Vol. 9 · Heaven's Fracture"),
    ("卷十 · 棋局终局", "Vol. 10 · Endgame"),
]

artwork_ja = [
    ("卷一 · 废材觉醒", "巻一 · 廃材覚醒"),
    ("命书初亮，棋局开场", "命書が初めて輝き、棋局が開幕する"),
    ("第一次看见残页发光之前，陈机只是宗门里最不值得被注意的人。", "残頁が初めて光るのを見る前、陳機は宗門で最も注目されない人物でした。"),
    ("天机录残页", "天機録の残頁"),
    ("改命的代价，从翻开它开始。", "命を変える代償は、それを開いた時から始まる。"),
    ("仙域绘卷", "仙域絵巻"),
    ("浮山、云海与命纹一起张开。", "浮山、雲海、命紋が共に広がる。"),
    ("首页不再只是封面，而是《天机录》世界在你眼前缓缓显形的第一镜。", "トップページはもはやただの表紙ではなく、天機録の世界があなたの目の前でゆっくりと姿を現す最初のレンズです。"),
    ("天机棋局", "天機棋局"),
    ("众生还没落子，因果已经先动。", "誰もまだ手を打っていないのに、因果はすでに動き出している。"),
    ("《天机录》的视觉核心不是打斗，而是预见、布局与改命。", "天機録のビジュアルの核心は戦闘ではなく、予見、布局、そして改命です。"),
    ("识海观测", "識海観測"),
    ("命途、人心与暗线都该被分层看清。", "命途、人心、暗線はすべて層ごとに見極めるべきです。"),
    ("命途图不再只是文字列表，而是一张能回看整条因果链的战局面板。", "命途図はもはやテキストリストではなく、因果連鎖全体を振り返る戦局パネルです。"),
    ("天青宗内门", "天青宗内門"),
    ("每个关键人物，都有自己的一面局。", "すべてのキーキャラクターには、独自の局があります。"),
    ("人物页不只是关系值，而是带立绘、态度、局重和建议的完整角色面板。", "キャラクターページは関係値だけでなく、立ち絵、態度、局の重さ、アドバイスを含む完全なパネルです。"),
    ("每一次动用，都在让命数重新对齐。", "使うたびに、命数が再調整されます。"),
    ("天道棋盘", "天道棋盤"),
    ("暗线不是彩蛋，而是仍在等待你触发的另一盘棋。", "暗線はイースターエッグではなく、あなたの発動を待つもう一つの棋局です。"),
    ("陈机", "陳機"), ("杂役灰袍下的第一层伪装", "雑役の灰色の衣の下の最初の偽装"),
    ("真正的威胁不在他看上去有多强，而在他总是比别人先知道一步。", "本当の脅威は彼の強さではなく、常に他者より一歩先を知っていることです。"),
    ("苏青瑶", "蘇青瑶"), ("冷锋一样的首席剑修", "冷たい刃のような首席剣修"),
    ("信任、警惕与欣赏会同时出现在她的关系线上。", "信頼、警戒、賞賛が彼女の関係線上に同時に現れます。"),
    ("夜清", "夜清"), ("危险与好奇并存的魔道圣女", "危険と好奇心が共存する魔道聖女"),
    ("她既可能是最锋利的盟友，也可能是最昂贵的赌注。", "彼女は最も鋭い盟友にも、最も高価な賭けにもなり得ます。"),
    ("凌渊", "凌淵"), ("仁善外衣下的旧棋手", "仁善の外衣の下の旧い棋手"),
    ("真正难读的不是他的表情，而是他到底把你放在棋盘哪一格。", "本当に読めないのは彼の表情ではなく、彼があなたを棋盤のどのマスに置いているかです。"),
    ("韩烈", "韓烈"), ("玄武宗最锋利的明牌", "玄武宗で最も鋭い表札"),
    ("他代表的不是阴谋，而是能够直接撞碎布局的暴烈正面。", "彼が代表するのは陰謀ではなく、布局を直接粉砕できる暴烈な正面突破です。"),
    ("墨先生", "墨先生"), ("残页里的旧时代见证者", "残頁の中の旧時代の証人"),
    ("当他愿意说真话时，往往意味着更大的代价已经靠近。", "彼が真実を語る時、それはより大きな代償が近づいていることを意味します。"),
    ("陈念", "陳念"), ("陈机最柔软也最危险的命门", "陳機の最も柔らかく最も危険な急所"),
    ("她不是背景设定，而是整条命途里最不能输掉的一枚核心子。", "彼女は背景設定ではなく、命途全体で最も失ってはならない核心の駒です。"),
    ("天道之眼", "天道の眼"), ("抬头时，你看到的是世界正在回看你。", "見上げた時、世界があなたを見返しているのが見えます。"),
    ("它让《天机录》的终局不只是一场争斗，而是与命运本身对局。", "それにより天機録の終局はただの争いではなく、運命そのものとの対局となります。"),
    ("卷一", "巻一"), ("废材觉醒", "廃材覚醒"),
    ("命数第一次回响，真正的陈机从这里开始出手。", "命数が初めて響き、真の陳機がここから動き出す。"),
    ("天青宗", "天青宗"), ("局从宗门最底层开始长出来。", "局は宗門の最底辺から生え始める。"),
    ("关键帧", "キーフレーム"), ("天机录初次激活", "天機録初回起動"),
    ("你第一次意识到，这不是一件法宝，而是一张会反噬使用者的命书。", "初めて気づく。これは法宝ではなく、使用者に反噬する命書だと。"),
    ("卷二", "巻二"), ("宗门暗战", "宗門暗闘"),
    ("从外门到内门，明面秩序开始被暗线撬动。", "外門から内門へ、表の秩序が暗線に揺さぶられ始める。"),
    ("内门深处", "内門深層"), ("真正危险的，不是刀，而是知道你底牌的人。", "本当に危険なのは刃ではなく、あなたの手札を知る者。"),
    ("苏青瑶逼近真相", "蘇青瑶、真相に迫る"),
    ("关系线在这里不再只是好感，而开始牵扯立场和试探。", "ここでの関係線はもはや好感度だけでなく、立場と探りを含み始める。"),
    ("卷三", "巻三"), ("秘境争锋", "秘境争鋒"),
    ("局第一次被拉到宗门之外，真相与资源同时变得稀缺。", "局が初めて宗門外に引き出され、真相と資源が同時に希少になる。"),
    ("上古秘境", "上古秘境"), ("外部势力入局后，每一步都不再只影响一宗。", "外部勢力の参入後、一歩ごとに影響は一宗に留まらない。"),
    ("扮猪吃虎反转", "韬光養晦の逆転"),
    ("真正的爽点来自提前铺好的后手终于被你亲手点燃。", "真の爽快感は、事前に仕込んだ伏線をあなた自身の手で点火する瞬間にある。"),
    ("卷四", "巻四"), ("魔道渗透", "魔道浸透"),
    ("正魔边界开始失真，盟友与敌人的定义一起松动。", "正魔の境界が曖昧になり、味方と敵の定義が共に揺らぐ。"),
    ("魔道圣宗", "魔道聖宗"), ("一切合作都带着代价，一切代价都在改写命途。", "すべての協力には代償が伴い、すべての代償が命途を書き換える。"),
    ("夜清黑雾救援", "夜清の黒霧救援"),
    ("当她出手时，危险和吸引往往会同时靠近。", "彼女が動く時、危険と魅力はしばしば同時に近づく。"),
    ("卷五", "巻五"), ("天命反噬", "天命反噬"),
    ("越想快一步赢，命书就越会向你讨回代价。", "早く勝とうとするほど、命書はより大きな代償を求める。"),
    ("识海深处", "識海深層"), ("这时最可怕的敌人，可能是你自己。", "この時最も恐ろしい敵は、あなた自身かもしれない。"),
    ("假死逃脱", "偽死脱出"),
    ("反转不只是逃出生天，更是主动把别人送进你安排的误判。", "逆転は生還だけでなく、相手をあなたが仕組んだ誤判に送り込むこと。"),
    ("卷六", "巻六"), ("大陆格局", "大陸格局"),
    ("从宗门一局，正式走到天下一局。", "宗門の局から、正式に天下の局へ。"),
    ("皇朝京城", "皇朝京城"), ("棋盘被放大之后，谁都不再只是配角。", "棋盤が拡大された後、誰もがもはや脇役ではない。"),
    ("统筹各方势力", "各方勢力の統括"),
    ("这是《天机录》最游戏化的一段，所有之前积累的关系与判断都开始兑现。", "天機録で最もゲーム的な部分。これまで積み重ねた関係と判断がすべて実を結び始める。"),
    ("卷七", "巻七"), ("上古真相", "上古の真相"),
    ("你终于开始接近命书本身为什么会存在。", "命書そのものがなぜ存在するのかに、ついに近づき始める。"),
    ("陈玄遗迹", "陳玄遺跡"), ("旧时代留下来的，从来不只有答案。", "旧時代が残したものは、答えだけではない。"),
    ("墨先生浮现", "墨先生浮上"),
    ("当旧时代真正说话时，世界观也会跟着一起翻面。", "旧時代が本当に語る時、世界観も一緒に裏返る。"),
    ("卷八", "巻八"), ("魔道大战", "魔道大戦"),
    ("局面全面失控时，你的每个决定都开始影响阵营级后果。", "局面が全面的に制御不能になった時、すべての決定が陣営レベルの結果に影響する。"),
    ("三宗激战", "三宗激戦"), ("到了这一卷，任何一步迟疑都会被放大。", "この巻に至ると、いかなる躊躇も増幅される。"),
    ("凌渊面具破碎", "凌淵の仮面砕ける"),
    ("真正震荡玩家的，不是揭晓，而是你终于看懂他一直在算什么。", "真にプレイヤーを震撼させるのは発覚ではなく、彼が何を計算していたかをついに理解する瞬間。"),
    ("卷九", "巻九"), ("天道裂变", "天道裂変"),
    ("《天机录》的终盘不只是对人，而是对天道本身。", "天機録の終盤は人に対するだけでなく、天道そのものに対する。"),
    ("你看见的不是未来，而是未来如何试图吞掉你。", "見えるのは未来ではなく、未来がいかにしてあなたを飲み込もうとするか。"),
    ("陈机对抗天道之眼", "陳機 vs 天道の眼"),
    ("抬头那一刻，故事正式从权谋修仙跃迁到命运战争。", "見上げたその瞬間、物語は権謀修仙から運命戦争へと正式に跳躍する。"),
    ("卷十", "巻十"), ("棋局终局", "棋局終局"),
    ("一切分支、好感、暗线与命数压力都会在这里汇合。", "すべての分岐、好感、暗線、命数圧力がここに集約される。"),
    ("终局前夜", "終局前夜"), ("你终于走到那枚最后的未落之子面前。", "ついにあの最後の未落の駒の前に立つ。"),
    ("踏出预言之外", "予言の外へ"),
    ("最好的结局感，不是赢，而是你真的把自己从既定命运里拿了出来。", "最高の結末感は勝つことではなく、本当に既定の運命から自分を引き出したこと。"),
    ("卷二 · 宗门暗战", "巻二 · 宗門暗闘"),
    ("卷三 · 秘境争锋", "巻三 · 秘境争鋒"),
    ("卷四 · 魔道渗透", "巻四 · 魔道浸透"),
    ("卷五 · 天命反噬", "巻五 · 天命反噬"),
    ("卷六 · 大陆格局", "巻六 · 大陸格局"),
    ("卷七 · 上古真相", "巻七 · 上古の真相"),
    ("卷八 · 魔道大战", "巻八 · 魔道大戦"),
    ("卷九 · 天道裂变", "巻九 · 天道裂変"),
    ("卷十 · 棋局终局", "巻十 · 棋局終局"),
]

# KO artwork translations (abbreviated for volume labels)
artwork_ko = [
    ("卷一 · 废材觉醒", "제1권 · 폐재의 각성"),
    ("命书初亮，棋局开场", "명서가 처음 빛나고, 바둑판이 펼쳐지다"),
    ("第一次看见残页发光之前，陈机只是宗门里最不值得被注意的人。", "잔편이 빛나는 것을 처음 보기 전, 진기는 종문에서 가장 주목받지 못하는 사람이었다."),
    ("天机录残页", "천기록 잔편"),
    ("改命的代价，从翻开它开始。", "운명을 바꾸는 대가는 그것을 펼치는 순간 시작된다."),
    ("仙域绘卷", "선계 두루마리"),
    ("浮山、云海与命纹一起张开。", "부산, 운해와 명문이 함께 펼쳐진다."),
    ("首页不再只是封面，而是《天机录》世界在你眼前缓缓显形的第一镜。", "홈페이지는 더 이상 표지가 아니라, 천기록 세계가 눈앞에서 서서히 모습을 드러내는 첫 번째 렌즈입니다."),
    ("天机棋局", "천기 바둑판"),
    ("众生还没落子，因果已经先动。", "아무도 수를 두지 않았는데, 인과는 이미 움직였다."),
    ("《天机录》的视觉核心不是打斗，而是预见、布局与改命。", "천기록의 시각적 핵심은 전투가 아니라, 예견, 포석, 그리고 운명 바꾸기입니다."),
    ("识海观测", "식해 관측"),
    ("命途、人心与暗线都该被分层看清。", "운명의 길, 인심, 암선 모두 층별로 파악해야 합니다."),
    ("命途图不再只是文字列表，而是一张能回看整条因果链的战局面板。", "운명도는 더 이상 텍스트 목록이 아니라, 전체 인과 사슬을 되돌아볼 수 있는 전국 패널입니다."),
    ("天青宗内门", "천청종 내문"),
    ("每个关键人物，都有自己的一面局。", "모든 핵심 인물에게는 자신만의 판이 있습니다."),
    ("人物页不只是关系值，而是带立绘、态度、局重和建议的完整角色面板。", "캐릭터 페이지는 관계 수치만이 아니라, 일러스트, 태도, 판의 무게, 조언이 포함된 완전한 패널입니다."),
    ("每一次动用，都在让命数重新对齐。", "사용할 때마다 운명의 수가 재정렬됩니다."),
    ("天道棋盘", "천도 바둑판"),
    ("暗线不是彩蛋，而是仍在等待你触发的另一盘棋。", "암선은 이스터에그가 아니라, 당신의 발동을 기다리는 또 다른 바둑판입니다."),
    ("陈机", "진기"), ("杂役灰袍下的第一层伪装", "잡역의 회색 옷 아래 첫 번째 위장"),
    ("真正的威胁不在他看上去有多强，而在他总是比别人先知道一步。", "진정한 위협은 그의 강함이 아니라, 항상 남보다 한 발 먼저 아는 것입니다."),
    ("苏青瑶", "소청요"), ("冷锋一样的首席剑修", "냉풍 같은 수석 검수"),
    ("信任、警惕与欣赏会同时出现在她的关系线上。", "신뢰, 경계, 존경이 그녀의 관계선에 동시에 나타납니다."),
    ("夜清", "야청"), ("危险与好奇并存的魔道圣女", "위험과 호기심이 공존하는 마도 성녀"),
    ("她既可能是最锋利的盟友，也可能是最昂贵的赌注。", "그녀는 가장 날카로운 동맹이 될 수도, 가장 비싼 도박이 될 수도 있습니다."),
    ("凌渊", "릉연"), ("仁善外衣下的旧棋手", "인자한 외피 아래의 오래된 기사"),
    ("真正难读的不是他的表情，而是他到底把你放在棋盘哪一格。", "정말 읽기 어려운 것은 그의 표정이 아니라, 그가 당신을 바둑판 어디에 놓았느냐입니다."),
    ("韩烈", "한렬"), ("玄武宗最锋利的明牌", "현무종 가장 날카로운 공개 패"),
    ("他代表的不是阴谋，而是能够直接撞碎布局的暴烈正面。", "그가 대표하는 것은 음모가 아니라, 포석을 직접 부수는 맹렬한 정면입니다."),
    ("墨先生", "묵선생"), ("残页里的旧时代见证者", "잔편 속 구시대의 증인"),
    ("当他愿意说真话时，往往意味着更大的代价已经靠近。", "그가 진실을 말할 때, 이는 종종 더 큰 대가가 다가오고 있음을 의미합니다."),
    ("陈念", "진념"), ("陈机最柔软也最危险的命门", "진기의 가장 부드럽고도 가장 위험한 급소"),
    ("她不是背景设定，而是整条命途里最不能输掉的一枚核心子。", "그녀는 배경 설정이 아니라, 전체 운명의 길에서 가장 잃어서는 안 될 핵심 말입니다."),
    ("天道之眼", "천도의 눈"), ("抬头时，你看到的是世界正在回看你。", "고개를 들면, 세계가 당신을 되돌아보고 있는 것이 보입니다."),
    ("它让《天机录》的终局不只是一场争斗，而是与命运本身对局。", "이로써 천기록의 종국은 단순한 싸움이 아니라 운명 그 자체와의 대국이 됩니다."),
    ("卷一", "제1권"), ("废材觉醒", "폐재의 각성"),
    ("命数第一次回响，真正的陈机从这里开始出手。", "운명의 수가 처음 울려 퍼지고, 진정한 진기가 여기서 행동을 시작합니다."),
    ("天青宗", "천청종"), ("局从宗门最底层开始长出来。", "판은 종문의 가장 밑바닥에서 자라기 시작합니다."),
    ("关键帧", "키프레임"), ("天机录初次激活", "천기록 최초 활성화"),
    ("你第一次意识到，这不是一件法宝，而是一张会反噬使用者的命书。", "처음 깨닫습니다. 이것은 법보가 아니라 사용자를 역습하는 명서라는 것을."),
    ("卷二", "제2권"), ("宗门暗战", "종문 암투"),
    ("从外门到内门，明面秩序开始被暗线撬动。", "외문에서 내문으로, 표면 질서가 암선에 의해 흔들리기 시작합니다."),
    ("内门深处", "내문 깊숙이"), ("真正危险的，不是刀，而是知道你底牌的人。", "진짜 위험한 것은 칼이 아니라, 당신의 패를 아는 사람입니다."),
    ("苏青瑶逼近真相", "소청요, 진상에 접근하다"),
    ("关系线在这里不再只是好感，而开始牵扯立场和试探。", "여기서의 관계선은 더 이상 호감만이 아니라 입장과 탐색을 포함하기 시작합니다."),
    ("卷三", "제3권"), ("秘境争锋", "비경 쟁봉"),
    ("局第一次被拉到宗门之外，真相与资源同时变得稀缺。", "판이 처음으로 종문 밖으로 확장되고, 진상과 자원이 동시에 희소해집니다."),
    ("上古秘境", "상고 비경"), ("外部势力入局后，每一步都不再只影响一宗。", "외부 세력이 참여한 후, 모든 한 수가 한 종문에만 영향을 미치지 않습니다."),
    ("扮猪吃虎反转", "돼지인 척 호랑이를 잡는 반전"),
    ("真正的爽点来自提前铺好的后手终于被你亲手点燃。", "진정한 쾌감은 미리 깔아둔 복선을 당신의 손으로 직접 점화하는 순간에 옵니다."),
    ("卷四", "제4권"), ("魔道渗透", "마도 침투"),
    ("正魔边界开始失真，盟友与敌人的定义一起松动。", "정마의 경계가 흐려지고, 동맹과 적의 정의가 함께 흔들립니다."),
    ("魔道圣宗", "마도 성종"), ("一切合作都带着代价，一切代价都在改写命途。", "모든 협력에는 대가가 따르고, 모든 대가는 운명의 길을 다시 씁니다."),
    ("夜清黑雾救援", "야청의 흑무 구원"),
    ("当她出手时，危险和吸引往往会同时靠近。", "그녀가 나설 때, 위험과 매력은 종종 동시에 다가옵니다."),
    ("卷五", "제5권"), ("天命反噬", "천명 역습"),
    ("越想快一步赢，命书就越会向你讨回代价。", "빨리 이기려 할수록, 명서는 더 큰 대가를 요구합니다."),
    ("识海深处", "식해 깊숙이"), ("这时最可怕的敌人，可能是你自己。", "이때 가장 무서운 적은 당신 자신일 수 있습니다."),
    ("假死逃脱", "가사 탈출"),
    ("反转不只是逃出生天，更是主动把别人送进你安排的误判。", "반전은 살아남는 것만이 아니라, 상대를 당신이 설계한 오판 속으로 보내는 것입니다."),
    ("卷六", "제6권"), ("大陆格局", "대륙 격국"),
    ("从宗门一局，正式走到天下一局。", "종문의 판에서 천하의 판으로 정식 진입합니다."),
    ("皇朝京城", "황조 경성"), ("棋盘被放大之后，谁都不再只是配角。", "바둑판이 확대된 후, 누구도 더 이상 조연이 아닙니다."),
    ("统筹各方势力", "각 세력 통솔"),
    ("这是《天机录》最游戏化的一段，所有之前积累的关系与判断都开始兑现。", "이것은 천기록에서 가장 게임적인 부분입니다. 이전에 쌓아온 모든 관계와 판단이 실현되기 시작합니다."),
    ("卷七", "제7권"), ("上古真相", "상고의 진상"),
    ("你终于开始接近命书本身为什么会存在。", "드디어 명서 자체가 왜 존재하는지에 접근하기 시작합니다."),
    ("陈玄遗迹", "진현 유적"), ("旧时代留下来的，从来不只有答案。", "구시대가 남긴 것은 답만이 아닙니다."),
    ("墨先生浮现", "묵선생 등장"),
    ("当旧时代真正说话时，世界观也会跟着一起翻面。", "구시대가 진정으로 말할 때, 세계관도 함께 뒤집힙니다."),
    ("卷八", "제8권"), ("魔道大战", "마도 대전"),
    ("局面全面失控时，你的每个决定都开始影响阵营级后果。", "상황이 전면 통제 불능이 되면, 모든 결정이 진영급 결과에 영향을 미칩니다."),
    ("三宗激战", "삼종 격전"), ("到了这一卷，任何一步迟疑都会被放大。", "이 권에 이르면, 어떤 망설임도 증폭됩니다."),
    ("凌渊面具破碎", "릉연의 가면이 깨지다"),
    ("真正震荡玩家的，不是揭晓，而是你终于看懂他一直在算什么。", "플레이어를 진정으로 충격시키는 것은 공개가 아니라, 그가 줄곧 무엇을 계산하고 있었는지 마침내 이해하는 순간입니다."),
    ("卷九", "제9권"), ("天道裂变", "천도 열변"),
    ("《天机录》的终盘不只是对人，而是对天道本身。", "천기록의 종반은 사람에 대한 것만이 아니라 천도 그 자체에 대한 것입니다."),
    ("你看见的不是未来，而是未来如何试图吞掉你。", "보이는 것은 미래가 아니라, 미래가 어떻게 당신을 삼키려 하는지입니다."),
    ("陈机对抗天道之眼", "진기 vs 천도의 눈"),
    ("抬头那一刻，故事正式从权谋修仙跃迁到命运战争。", "고개를 든 그 순간, 이야기는 권모 수선에서 운명 전쟁으로 정식 도약합니다."),
    ("卷十", "제10권"), ("棋局终局", "바둑판 종국"),
    ("一切分支、好感、暗线与命数压力都会在这里汇合。", "모든 분기, 호감, 암선, 명수 압력이 여기서 합류합니다."),
    ("终局前夜", "종국 전야"), ("你终于走到那枚最后的未落之子面前。", "마침내 그 마지막 놓이지 않은 돌 앞에 섭니다."),
    ("踏出预言之外", "예언 너머로"),
    ("最好的结局感，不是赢，而是你真的把自己从既定命运里拿了出来。", "최고의 엔딩감은 이기는 게 아니라, 정해진 운명에서 정말로 자신을 꺼낸 것입니다."),
    ("卷二 · 宗门暗战", "제2권 · 종문 암투"),
    ("卷三 · 秘境争锋", "제3권 · 비경 쟁봉"),
    ("卷四 · 魔道渗透", "제4권 · 마도 침투"),
    ("卷五 · 天命反噬", "제5권 · 천명 역습"),
    ("卷六 · 大陆格局", "제6권 · 대륙 격국"),
    ("卷七 · 上古真相", "제7권 · 상고의 진상"),
    ("卷八 · 魔道大战", "제8권 · 마도 대전"),
    ("卷九 · 天道裂变", "제9권 · 천도 열변"),
    ("卷十 · 棋局终局", "제10권 · 바둑판 종국"),
]


def main():
    for lang, sections in [
        ("en", [
            ("Chapter Browser UI", chapter_browser_en),
            ("Volume Store Errors", volume_store_en),
            ("Route Map & Hub", routemap_en),
            ("Dossier Stat Labels", dossier_stats_en),
            ("Dossier Module Cards", dossier_modules_en),
            ("Artwork & Volume Visuals", artwork_en),
        ]),
        ("ja", [
            ("Chapter Browser UI", chapter_browser_ja),
            ("Volume Store Errors", volume_store_ja),
            ("Route Map & Hub", routemap_ja),
            ("Dossier Stat Labels", dossier_stats_ja),
            ("Dossier Module Cards", dossier_modules_ja),
            ("Artwork & Volume Visuals", artwork_ja),
        ]),
        ("ko", [
            ("Chapter Browser UI", chapter_browser_ko),
            ("Volume Store Errors", volume_store_ko),
            ("Route Map & Hub", routemap_ko),
            ("Dossier Stat Labels", dossier_stats_ko),
            ("Dossier Module Cards", dossier_modules_ko),
            ("Artwork & Volume Visuals", artwork_ko),
        ]),
    ]:
        filepath = os.path.join(RESOURCES, f"{lang}.lproj", "Localizable.strings")
        existing = read_existing_keys(filepath)

        total_added = 0
        for section_name, entries in sections:
            new_entries = [(k, v) for k, v in entries if k not in existing]
            if new_entries:
                append_entries(filepath, new_entries, section_name)
                total_added += len(new_entries)
                existing.update(k for k, _ in new_entries)

        print(f"[{lang}] Added {total_added} new keys to {filepath}")

    # ZH-Hans: add self-mappings for all new keys
    zh_filepath = os.path.join(RESOURCES, "zh-Hans.lproj", "Localizable.strings")
    zh_existing = read_existing_keys(zh_filepath)

    # Collect all unique Chinese keys
    all_keys = set()
    for entries_list in [
        chapter_browser_en, volume_store_en, routemap_en,
        dossier_stats_en, dossier_modules_en, artwork_en
    ]:
        for key, _ in entries_list:
            all_keys.add(key)

    zh_new = [(k, k) for k in sorted(all_keys) if k not in zh_existing]
    if zh_new:
        append_entries(zh_filepath, zh_new, "New UI Keys (self-mapping)")
        print(f"[zh-Hans] Added {len(zh_new)} self-mapping keys")
    else:
        print("[zh-Hans] No new keys needed")


if __name__ == "__main__":
    main()
