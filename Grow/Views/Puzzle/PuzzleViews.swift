import SwiftUI

// MARK: - 趣味拼图首页

/// 三个难度：入门 4 块 / 进阶 9 块 / 挑战 16 块，逐级解锁
struct PuzzleHomeView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var puzzles: PuzzleRepository
    @EnvironmentObject var progress: ProgressManager
    @State private var appeared = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                header
                ForEach(PuzzleDifficulty.allCases) { difficulty in
                    difficultyCard(difficulty)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.cream.ignoresSafeArea())
        .navigationTitle("趣味拼图")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) { appeared = true }
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            ModuleIconView(module: .puzzle, size: 56)
            Text("趣味拼图")
                .font(.system(size: Theme.scaled(26, settings: settings), weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
            Text("动手拼一拼")
                .font(.system(size: Theme.scaled(14, settings: settings), weight: .medium))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(.top, 8)
        .opacity(appeared ? 1 : 0)
    }

    private func difficultyCard(_ difficulty: PuzzleDifficulty) -> some View {
        let unlocked = progress.isUnlocked(difficulty)
        let total = puzzles.count(in: difficulty)
        let done = progress.completedCount(in: difficulty)

        return Group {
            if unlocked {
                NavigationLink {
                    PuzzleLevelView(difficulty: difficulty)
                } label: {
                    cardContent(difficulty, unlocked: true, done: done, total: total)
                }
                .buttonStyle(PressableButtonStyle(settings: settings))
            } else {
                cardContent(difficulty, unlocked: false, done: done, total: total)
                    .opacity(0.72)
            }
        }
    }

    private func cardContent(_ difficulty: PuzzleDifficulty,
                             unlocked: Bool,
                             done: Int,
                             total: Int) -> some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.55))
                    .frame(width: 76, height: 76)
                if unlocked {
                    PuzzleDifficultyIcon(grid: difficulty.grid,
                                         deep: deepColor(for: difficulty),
                                         size: 44)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.95))
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(difficulty.displayName)
                    .font(.system(size: Theme.scaled(23, settings: settings), weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("\(difficulty.pieceCount) 块 · \(total) 张")
                    .font(.system(size: Theme.scaled(13, settings: settings), weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))

                if unlocked {
                    Text(done > 0 ? "已完成 \(done)/\(total)" : "一起去拼图吧")
                        .font(.system(size: Theme.scaled(12, settings: settings), weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                } else {
                    Text("完成\(difficulty.requiredPrevious?.displayName ?? "")后解锁")
                        .font(.system(size: Theme.scaled(12, settings: settings), weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            Spacer()

            if unlocked {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(20)
        .frame(minHeight: 112 * settings.buttonScaleFactor)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(LinearGradient(colors: colors(for: difficulty),
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .shadow(color: colors(for: difficulty)[0].opacity(0.32), radius: 12, y: 7)
    }

    private func colors(for difficulty: PuzzleDifficulty) -> [Color] {
        switch difficulty {
        case .easy:   return [Theme.vegetable.opacity(0.85), Theme.vegetable.opacity(0.55)]
        case .medium: return [Theme.animal.opacity(0.85), Theme.animal.opacity(0.55)]
        case .hard:   return [Theme.plant.opacity(0.85), Theme.plant.opacity(0.55)]
        }
    }

    /// 拼块深色（与卡片底色同色系、加深对比）
    private func deepColor(for difficulty: PuzzleDifficulty) -> Color {
        switch difficulty {
        case .easy:   return Theme.deepGreen
        case .medium: return Theme.deepBlue
        case .hard:   return Theme.deepLilac
        }
    }
}

// MARK: - 某难度下的拼图列表

struct PuzzleLevelView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var puzzles: PuzzleRepository
    @EnvironmentObject var progress: ProgressManager
    let difficulty: PuzzleDifficulty

    private var items: [PuzzleItem] { puzzles.puzzles(in: difficulty) }

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                Text("\(difficulty.displayName) · \(difficulty.pieceCount) 块")
                    .font(.system(size: Theme.scaled(17, settings: settings), weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 20)

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(items) { item in
                        NavigationLink {
                            PuzzleGameView(item: item)
                        } label: {
                            PuzzleThumbCard(item: item, completed: progress.isCompleted(item.id))
                        }
                        .buttonStyle(PressableButtonStyle(settings: settings))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.cream.ignoresSafeArea())
        .navigationTitle(difficulty.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PuzzleThumbCard: View {
    @EnvironmentObject var settings: SettingsManager
    let item: PuzzleItem
    let completed: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 10) {
                IllustrationView(identifier: item.image)
                    .frame(width: 110, height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                Text(item.title)
                    .font(.system(size: Theme.scaled(17, settings: settings), weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)

                Text("\(item.pieceCount) 块")
                    .font(.system(size: Theme.scaled(12, settings: settings), weight: .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .growCard(fill: .white.opacity(0.8), radius: 26)

            if completed {
                Text("🌟")
                    .font(.system(size: 22))
                    .padding(10)
            }
        }
    }
}

// MARK: - 完成页

/// 不使用金币 / 通关等游戏化机制（§49），只给柔和反馈 + 与自然认知联动
struct PuzzleCompleteView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var content: ContentRepository

    let item: PuzzleItem
    let elapsed: TimeInterval
    let hasNext: Bool
    let onReplay: () -> Void
    let onNext: () -> Void

    @State private var popped = false

    private var natureItem: NatureItem? {
        guard let id = item.sourceNatureItemId else { return nil }
        return content.natureItems.first { $0.id == id }
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 46, weight: .semibold))
                .foregroundStyle(Theme.poemWarm)
                .scaleEffect(popped ? 1.0 : 0.6)
                .opacity(popped ? 1 : 0)

            Text("拼好了！")
                .font(.system(size: Theme.scaled(34, settings: settings), weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)

            IllustrationView(identifier: item.image)
                .frame(width: 150, height: 150)
                .growCard(fill: .white.opacity(0.8), radius: 26)

            if let nature = natureItem {
                VStack(spacing: 4) {
                    Text(nature.nameZh)
                        .font(.system(size: Theme.scaled(26, settings: settings), weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Text(nature.nameEn)
                        .font(.system(size: Theme.scaled(17, settings: settings), weight: .medium))
                        .foregroundStyle(Theme.inkSoft)
                }

                // 复用 Phase 1 三语发音组件
                LanguageButtonsRow(name: nature.nameZh, nameEn: nature.nameEn, itemKey: "puzzle-\(item.id)")

                NavigationLink {
                    NatureDetailView(item: nature)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 15, weight: .semibold))
                        Text("认识一下")
                            .font(.system(size: Theme.scaled(16, settings: settings), weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(Theme.vegetable)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .frame(minHeight: 48 * settings.buttonScaleFactor)
                    .background(Capsule().fill(Theme.vegetable.opacity(0.14)))
                }
                .buttonStyle(PressableButtonStyle(settings: settings))
            } else {
                Text(item.title)
                    .font(.system(size: Theme.scaled(26, settings: settings), weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
            }

            Spacer()

            HStack(spacing: 14) {
                Button {
                    onReplay()
                } label: {
                    actionButton(title: "再玩一次", filled: false)
                }
                .buttonStyle(PressableButtonStyle(settings: settings))

                if hasNext {
                    Button {
                        onNext()
                    } label: {
                        actionButton(title: "下一张", filled: true)
                    }
                    .buttonStyle(PressableButtonStyle(settings: settings))
                }
            }
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity)
        .background(Theme.cream.ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { popped = true }
        }
    }

    private func actionButton(title: String, filled: Bool) -> some View {
        Text(title)
            .font(.system(size: Theme.scaled(17, settings: settings), weight: .bold, design: .rounded))
            .foregroundStyle(filled ? .white : Theme.ink)
            .padding(.horizontal, 26)
            .padding(.vertical, 15)
            .frame(minWidth: 120, minHeight: 52 * settings.buttonScaleFactor)
            .background(
                Capsule().fill(filled ? Theme.vegetable : Theme.creamDeep)
            )
            .overlay(
                Capsule().strokeBorder(filled ? Color.clear : Theme.inkSoft.opacity(0.18), lineWidth: 1.5)
            )
    }
}
