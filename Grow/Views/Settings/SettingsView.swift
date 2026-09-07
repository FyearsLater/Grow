import SwiftUI

/// 设置页：显示设置为儿童可调；声音/速度等关键设置需要家长长按 3 秒验证
struct SettingsView: View {
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("设置")
                        .font(.system(size: Theme.scaled(30, settings: settings), weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                        .padding(.top, 8)

                    displaySection
                    ageSection
                    parentSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
    }

    // MARK: - 显示设置（儿童可调）

    private var displaySection: some View {
        settingsCard("显示") {
            pickerRow("页面缩放", value: $settings.pageScale)
            pickerRow("字体大小", value: $settings.fontSize)
            pickerRow("按钮大小", value: $settings.buttonSize)
        }
    }

    private var ageSection: some View {
        settingsCard("年龄模式") {
            pickerRow("适合年龄", value: $settings.ageMode)
            Text("2–3 岁显示更少文字，4–6 岁增加拼音和更多知识")
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkSoft.opacity(0.8))
        }
    }

    // MARK: - 声音与朗读（已关闭家长验证，直接可调）

    private var parentSection: some View {
        settingsCard("朗读与声音") {
            VStack(spacing: 16) {
                // 语音包状态（缺包时对应语言无法标准发声）
                voicePackStatus

                // 默认发音语言
                VStack(alignment: .leading, spacing: 8) {
                    Text("默认发音")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Picker("默认发音", selection: $settings.defaultLanguage) {
                        ForEach(SpeechLanguage.allCases) { lang in
                            Text("\(lang.symbol) \(lang.displayName)").tag(lang)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // 古诗词朗读语言
                VStack(alignment: .leading, spacing: 8) {
                    Text("古诗词朗读语言")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Picker("古诗词朗读语言", selection: $settings.poemLanguage) {
                        ForEach([SpeechLanguage.mandarin, .cantonese]) { lang in
                            Text("\(lang.symbol) \(lang.fullName)").tag(lang)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // 古诗词朗读音色
                VStack(alignment: .leading, spacing: 8) {
                    Text("古诗词朗读音色")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Picker("古诗词朗读音色", selection: $settings.poemVoice) {
                        ForEach(PoemVoiceRole.allCases) { role in
                            Text("\(role.icon) \(role.displayName)").tag(role)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // 古诗词句间停顿
                VStack(alignment: .leading, spacing: 8) {
                    Text("古诗词句间停顿")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Picker("古诗词句间停顿", selection: $settings.poemPause) {
                        Text("短").tag(0.35)
                        Text("适中").tag(0.55)
                        Text("长").tag(0.90)
                    }
                    .pickerStyle(.segmented)
                }

                // 朗读速度
                VStack(alignment: .leading, spacing: 8) {
                    Text("朗读速度")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Picker("朗读速度", selection: $settings.speechSpeed) {
                        Text("0.75x").tag(0.75)
                        Text("1.0x").tag(1.0)
                        Text("1.25x").tag(1.25)
                    }
                    .pickerStyle(.segmented)
                }

                // 音效与动画
                Toggle("按钮音效", isOn: $settings.buttonSoundOn)
                    .tint(Theme.vegetable)
                Toggle("动画效果", isOn: $settings.animationOn)
                    .tint(Theme.vegetable)
                Toggle("减少动画", isOn: $settings.reduceMotion)
                    .tint(Theme.vegetable)
                Toggle("拼图辅助", isOn: $settings.puzzleAssist)
                    .tint(Theme.vegetable)

                // 开发日志入口
                NavigationLink {
                    DevLogView()
                } label: {
                    HStack {
                        Label("开发日志", systemImage: "list.bullet.clipboard.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text("v\(DevLog.all.first?.version ?? "")")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.inkSoft)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.inkSoft.opacity(0.6))
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: - 语音包状态

    /// 列出每种语言的系统语音包安装情况；缺失时给出去系统设置下载的引导。
    private var voicePackStatus: some View {
        let missing = SpeechLanguage.allCases.filter { !AudioManager.hasExactVoice(for: $0) }

        return VStack(alignment: .leading, spacing: 10) {
            Text("语音包状态")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.ink)

            ForEach(SpeechLanguage.allCases) { lang in
                HStack {
                    Text("\(lang.fullName)（\(lang.displayName)）")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.inkSoft)
                    Spacer()
                    if AudioManager.hasExactVoice(for: lang) {
                        Label("已安装", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.vegetable)
                    } else {
                        Label("未安装 · 回退发声", systemImage: "exclamationmark.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.poemWarm)
                    }
                }
            }

            if !missing.isEmpty {
                Text("未安装时点击该语言按钮会用相近语音代替发声（不是标准发音）。安装方法：iPhone 设置 → 辅助功能 → 朗读内容 → 声音，下载对应语音，如「中文（香港）」。")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.inkSoft.opacity(0.8))
                    .lineSpacing(3)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.cream))
    }

    // MARK: - 通用小组件

    private func settingsCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: Theme.scaled(17, settings: settings), weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .growCard(fill: .white.opacity(0.7))
    }

    private func pickerRow(_ label: String, value: Binding<SizeLevel>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Picker(label, selection: value) {
                ForEach(SizeLevel.allCases) { level in
                    Text(level.displayName).tag(level)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func pickerRow(_ label: String, value: Binding<AgeMode>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Picker(label, selection: value) {
                ForEach(AgeMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: - 家长验证卡片（长按 3 秒）

struct ParentGateCard<Content: View>: View {
    let content: Content
    @State private var unlocked = false
    @State private var progress: CGFloat = 0
    @State private var holdTimer: Timer?

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("家长设置", systemImage: "person.badge.key.fill")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Spacer()
            }

            if unlocked {
                content
            } else {
                VStack(spacing: 10) {
                    Text("长按下方按钮 3 秒进入")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.inkSoft)
                    ZStack {
                        Capsule().fill(Theme.creamDeep)
                        GeometryReader { geo in
                            Capsule()
                                .fill(Theme.poemWarm.opacity(0.85))
                                .frame(width: geo.size.width * progress)
                        }
                        Text("家长长按进入")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(progress > 0.5 ? .white : Theme.inkSoft)
                    }
                    .frame(height: 52)
                    .contentShape(Capsule())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in startHold() }
                            .onEnded { _ in cancelHold() }
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .growCard(fill: .white.opacity(0.7))
    }

    // MARK: - 长按进度

    private func startHold() {
        guard holdTimer == nil, !unlocked else { return }
        withAnimation(.linear(duration: 0.1)) { progress = 0.02 }
        holdTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            progress = min(progress + 0.01, 1.0)
            if progress >= 1.0 {
                unlocked = true
                stopTimer()
            }
        }
    }

    private func cancelHold() {
        stopTimer()
        if !unlocked {
            withAnimation(.easeOut(duration: 0.25)) { progress = 0 }
        }
    }

    private func stopTimer() {
        holdTimer?.invalidate()
        holdTimer = nil
    }
}
