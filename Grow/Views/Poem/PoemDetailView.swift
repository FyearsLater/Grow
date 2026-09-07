import SwiftUI

/// 古诗详情：沉浸式阅读 —— 插画 + 原文/拼音切换 + 整首朗读 + 逐句点读 + 注释 + 儿童理解
struct PoemDetailView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var audio: AudioManager
    let poemId: String

    @State private var pinyinMode = false
    @State private var showAnnotations = true

    private var poem: Poem? { ContentRepository.shared.poem(id: poemId) }

    var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()
            if let poem {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // 顶部横幅插图（压缩高度，保证正文首屏可见）
                        IllustrationBanner(identifier: poem.illustration)

                        // 诗名 + 作者（紧凑单行）
                        HStack(alignment: .firstTextBaseline) {
                            Text("《\(poem.title)》")
                                .font(.system(size: Theme.scaled(24, settings: settings), weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            Text("\(poem.dynasty) · \(poem.author)")
                                .font(.system(size: Theme.scaled(14, settings: settings), weight: .medium))
                                .foregroundStyle(Theme.inkSoft)
                        }

                        // 整首朗读 + 拼音切换
                        HStack(spacing: 14) {
                            playAllButton(poem)
                            pinyinToggle
                        }

                        // 正文（可点读）
                        poemBody(poem)

                        // 注释
                        annotationsCard(poem)

                        // 儿童理解
                        kidSummaryCard(poem)

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 22)
                }
            } else {
                Text("内容未找到")
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .navigationTitle(poem?.title ?? "古诗")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                FavoriteButton(kind: .poem, id: poemId)
            }
        }
        .onAppear {
            UserLibrary.shared.recordPoemVisit(poemId)
        }
        .onDisappear {
            audio.stop()
        }
    }

    // MARK: - 整首朗读

    private func playAllButton(_ poem: Poem) -> some View {
        let playing = audio.playingKey == "poem-\(poem.id)"
        return Button {
            if playing { audio.stop() } else { audio.speakPoem(poem) }
        } label: {
            HStack(spacing: 8) {
                if playing {
                    WaveIndicator(active: true, color: .white)
                } else {
                    Image(systemName: "play.fill")
                }
                Text(playing ? "朗读中" : "播放整首")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 26)
            .padding(.vertical, 14)
            .frame(minHeight: 48 * settings.buttonScaleFactor)
            .background(Capsule().fill(Theme.poemAccent))
            .shadow(color: Theme.poemAccent.opacity(0.35), radius: 8, y: 4)
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: - 拼音模式

    private var pinyinToggle: some View {
        Button {
            withAnimation(.spring(response: 0.3)) { pinyinMode.toggle() }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "textformat")
                Text(pinyinMode ? "原文" : "拼音")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(Theme.poemWarm)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(minHeight: 48 * settings.buttonScaleFactor)
            .background(Capsule().fill(Theme.poemWarm.opacity(0.15)))
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: - 正文（点击某一句只朗读这一句）

    private func poemBody(_ poem: Poem) -> some View {
        VStack(spacing: 0) {
            ForEach(poem.lines) { line in
                PoemLineRow(
                    line: line,
                    isSpeaking: audio.playingKey == "poem-\(poem.id)"
                        ? audio.speakingLineIndex == line.order
                        : audio.playingKey == "line-\(poem.id)-\(line.order)",
                    showPinyin: pinyinMode,
                    settings: settings
                )
                .onTapGesture {
                    audio.speakPoemLine(line.text, key: "line-\(poem.id)-\(line.order)")
                }
            }
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .growCard(fill: Theme.poemPaper)
    }

    // MARK: - 注释

    private func annotationsCard(_ poem: Poem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("字词小注")
                .font(.system(size: Theme.scaled(16, settings: settings), weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
            ForEach(poem.annotations) { note in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(note.target)
                        .font(.system(size: Theme.scaled(16, settings: settings), weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.poemAccent)
                    Text(note.explanation)
                        .font(.system(size: Theme.scaled(15, settings: settings), weight: .medium))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .growCard(fill: .white.opacity(0.7))
    }

    // MARK: - 儿童理解

    private func kidSummaryCard(_ poem: Poem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("小朋友可以这样理解", systemImage: "eyes")
                .font(.system(size: Theme.scaled(16, settings: settings), weight: .bold, design: .rounded))
                .foregroundStyle(Theme.poemWarm)
            Text(poem.kidSummary)
                .font(.system(size: Theme.scaled(16, settings: settings), weight: .medium))
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .growCard(fill: Theme.poemWarm.opacity(0.10))
    }
}

/// 单句：朗读中轻微放大 + 高亮
struct PoemLineRow: View {
    let line: PoemLine
    let isSpeaking: Bool
    let showPinyin: Bool
    let settings: SettingsManager

    var body: some View {
        VStack(spacing: 4) {
            if showPinyin {
                Text(line.pinyin)
                    .font(.system(size: Theme.scaled(12, settings: settings), weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.poemWarm.opacity(0.9))
            }
            HStack(spacing: 10) {
                Text(line.text)
                    .font(.system(size: Theme.scaled(22, settings: settings), weight: .semibold, design: .serif))
                    .foregroundStyle(isSpeaking ? Theme.poemAccent : Theme.ink)
                if isSpeaking {
                    WaveIndicator(active: true, color: Theme.poemAccent)
                }
            }
        }
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity)
        .scaleEffect(isSpeaking ? 1.04 : 1.0)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isSpeaking ? Theme.poemAccent.opacity(0.10) : .clear)
        )
        .animation(.spring(response: 0.3), value: isSpeaking)
        .contentShape(Rectangle())
    }
}
