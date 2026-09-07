import SwiftUI

// MARK: - 看图识字首页

/// 三个分类入口：数字 / 声母 / 韵母
struct LearningHomeView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var learning: LearningRepository
    @State private var appeared = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                header
                cards
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.cream.ignoresSafeArea())
        .navigationTitle("看图识字")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) { appeared = true }
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            ModuleIconView(module: .learning, size: 56)
            Text("看图识字")
                .font(.system(size: Theme.scaled(26, settings: settings), weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
            Text("看一看，听一听，认识新朋友")
                .font(.system(size: Theme.scaled(14, settings: settings), weight: .medium))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(.top, 8)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
    }

    private var cards: some View {
        VStack(spacing: 16) {
            NavigationLink {
                NumberView()
            } label: {
                LearningCategoryCard(topic: .numbers, title: "数字", subtitle: "0 – 9",
                                     count: learning.numbers.count)
            }
            .buttonStyle(PressableButtonStyle(settings: settings))

            NavigationLink {
                PinyinView(type: .initial)
            } label: {
                LearningCategoryCard(topic: .initial, title: "声母", subtitle: "认识拼音声母",
                                     count: learning.pinyins(of: .initial).count)
            }
            .buttonStyle(PressableButtonStyle(settings: settings))

            NavigationLink {
                PinyinView(type: .final)
            } label: {
                LearningCategoryCard(topic: .final, title: "韵母", subtitle: "认识拼音韵母",
                                     count: learning.pinyins(of: .final).count)
            }
            .buttonStyle(PressableButtonStyle(settings: settings))
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 18)
    }
}

/// 分类大卡片（与拼图页入口卡片同一套视觉语言：柔和渐变底 + 矢量图标）
struct LearningCategoryCard: View {
    @EnvironmentObject var settings: SettingsManager
    let topic: LearningTopic
    let title: String
    let subtitle: String
    let count: Int

    var body: some View {
        HStack(spacing: 18) {
            LearningTopicIcon(topic: topic, size: 64)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: Theme.scaled(23, settings: settings), weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: Theme.scaled(13, settings: settings), weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                Text("\(count) 个")
                    .font(.system(size: Theme.scaled(12, settings: settings), weight: .semibold))
                    .foregroundStyle(.white.opacity(0.75))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(20)
        .frame(minHeight: 112 * settings.buttonScaleFactor)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .shadow(color: colors[0].opacity(0.32), radius: 12, y: 7)
    }

    private var colors: [Color] {
        switch topic {
        case .numbers: return [Theme.fruit.opacity(0.85), Theme.fruit.opacity(0.55)]
        case .initial: return [Theme.animal.opacity(0.85), Theme.animal.opacity(0.55)]
        case .final: return [Theme.plant.opacity(0.85), Theme.plant.opacity(0.55)]
        }
    }
}

// MARK: - 数字 0–9

/// 左右滑动浏览，形成「数量 → 数字 → 中文 → 声音」的认知关系
struct NumberView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var learning: LearningRepository
    @State private var index = 0

    private var items: [NumberItem] { learning.numbers }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $index) {
                ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                    NumberCard(item: item)
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            PageDots(count: items.count, index: index)
                .padding(.bottom, 20)
        }
        .background(Theme.cream.ignoresSafeArea())
        .navigationTitle("数字")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NumberCard: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var audio: AudioManager
    let item: NumberItem

    private var key: String { "number-\(item.id)" }

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 8)
            quantityView

            Button { speak() } label: {
                VStack(spacing: 2) {
                    Text("\(item.number)")
                        .font(.system(size: Theme.scaled(104, settings: settings), weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Text(item.chineseName)
                        .font(.system(size: Theme.scaled(46, settings: settings), weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.fruit)
                }
            }
            .buttonStyle(PressableButtonStyle(settings: settings))
            .accessibilityHint("播放 \(item.chineseName) 的发音")

            Spacer(minLength: 8)
            SpeakButton(text: item.chineseName, key: key, title: "普通话", style: .prominent)
            Spacer(minLength: 16)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity)
    }

    private func speak() {
        audio.speak(name: item.chineseName, language: .mandarin, key: key)
    }

    @ViewBuilder
    private var quantityView: some View {
        if item.number == 0 {
            VStack(spacing: 10) {
                Text("🍽")
                    .font(.system(size: 52))
                Text("一个也没有")
                    .font(.system(size: Theme.scaled(16, settings: settings), weight: .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
            .frame(minHeight: 150)
        } else {
            let columns = min(item.number, 5)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: columns), spacing: 12) {
                ForEach(0..<item.number, id: \.self) { _ in
                    Text(item.imageItems.first ?? "⭐")
                        .font(.system(size: 42))
                }
            }
            .frame(maxWidth: 330)
            .frame(minHeight: 150)
        }
    }
}

// MARK: - 拼音（声母 / 韵母）

struct PinyinView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var learning: LearningRepository
    let type: PinyinType
    @State private var index = 0

    private var items: [PinyinItem] { learning.pinyins(of: type) }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $index) {
                ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                    PinyinCard(item: item)
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            PageDots(count: items.count, index: index)
                .padding(.bottom, 20)
        }
        .background(Theme.cream.ignoresSafeArea())
        .navigationTitle(type.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// 建立「图片 → 示例词 → 拼音 → 发音」的关系
/// 布局：大图在上，下方拼音字母与示例词左右并排（与自然卡片视觉统一）
struct PinyinCard: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var audio: AudioManager
    let item: PinyinItem

    private var key: String { "pinyin-\(item.id)" }

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 8)

            IllustrationView(identifier: item.image)
                .frame(width: 236, height: 236)
                .growCard(fill: .white.opacity(0.7), radius: 28)

            HStack(spacing: 22) {
                // 左：拼音字母（点击发音）
                Button { speak() } label: {
                    Text(item.symbol)
                        .font(.system(size: Theme.scaled(84, settings: settings), weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.vegetable)
                }
                .buttonStyle(PressableButtonStyle(settings: settings))
                .accessibilityHint("播放 \(item.symbol) 的发音")

                // 分隔线
                Rectangle()
                    .fill(Theme.inkSoft.opacity(0.15))
                    .frame(width: 1, height: 76)

                // 右：示例词 + 读音
                Button { speakWord() } label: {
                    VStack(spacing: 4) {
                        Text(item.exampleWord)
                            .font(.system(size: Theme.scaled(34, settings: settings), weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.ink)
                        Text(item.exampleWordPinyin)
                            .font(.system(size: Theme.scaled(17, settings: settings), weight: .medium))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                .buttonStyle(PressableButtonStyle(settings: settings))
                .accessibilityHint("播放 \(item.exampleWord) 的发音")
            }

            Spacer(minLength: 8)
            SpeakButton(text: item.speechContent, key: key, title: "国", style: .prominent)
            Spacer(minLength: 16)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity)
    }

    private func speak() {
        audio.speak(name: item.speechContent, language: .mandarin, key: key)
    }

    private func speakWord() {
        audio.speak(name: item.exampleWord, language: .mandarin, key: "\(key)-word")
    }
}

// MARK: - 页码指示

struct PageDots: View {
    let count: Int
    let index: Int

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<count, id: \.self) { i in
                Circle()
                    .fill(i == index ? Theme.inkSoft : Theme.inkSoft.opacity(0.25))
                    .frame(width: i == index ? 9 : 7, height: i == index ? 9 : 7)
                    .animation(.easeOut(duration: 0.2), value: index)
            }
        }
        .padding(.vertical, 10)
    }
}
