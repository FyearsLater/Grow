import SwiftUI

/// 自然对象详情：大图 + 三语发音 + 折叠简介（按年龄模式显示不同内容）+ 玩一玩入口
struct NatureDetailView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var audio: AudioManager
    @EnvironmentObject var router: Router
    let item: NatureItem

    @State private var showMore = false

    private var descriptionKey: String { "\(item.id)-desc" }
    private var descriptionText: String {
        settings.prefersLongDescription ? item.descriptionLong : item.descriptionShort
    }

    var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // 主图（占页面约 50%）
                    IllustrationView(identifier: item.illustration)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 40)
                        .padding(.top, 8)

                    // 名称（与卡片页统一：收藏按钮在名称旁）
                    VStack(spacing: 4) {
                        HStack(spacing: 10) {
                            Text(item.nameZh)
                                .font(.system(size: Theme.scaled(38, settings: settings), weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.ink)
                            FavoriteButton(kind: .nature, id: item.id)
                        }
                        Text(item.nameEn)
                            .font(.system(size: Theme.scaled(20, settings: settings), weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.inkSoft)
                    }

                    // 三语发音（读完后自动继续朗读介绍）
                    LanguageButtonsRow(
                        name: item.nameZh,
                        nameEn: item.nameEn,
                        itemKey: "\(item.id)-detail",
                        onFinished: { speakDescription() }
                    )

                    // 简介折叠卡片
                    descriptionCard

                    // 玩一玩（Phase 5：跨 Tab 直达游戏）
                    playSection

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationTitle(item.nameZh)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // 记录最近学习
            UserLibrary.shared.recordNatureVisit(item.id)
        }
        .onDisappear {
            audio.stop()
        }
    }

    private func speakDescription() {
        audio.speak(name: descriptionText, language: settings.defaultLanguage, key: descriptionKey)
    }

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("了解更多")
                    .font(.system(size: Theme.scaled(16, settings: settings), weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                if audio.playingKey == descriptionKey {
                    WaveIndicator(active: true, color: Theme.categoryColor(item.category))
                }
                Spacer()
            }

            Text(descriptionText)
                .font(.system(size: Theme.scaled(17, settings: settings), weight: .medium))
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(6)
                .opacity(showMore ? 1 : (settings.prefersLongDescription ? 0.85 : 1))

            if settings.prefersLongDescription {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showMore.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(showMore ? "收起" : "展开")
                        Image(systemName: showMore ? "chevron.up" : "chevron.down")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.categoryColor(item.category))
                    .frame(minHeight: 44)
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .growCard(fill: .white.opacity(0.7))
    }

    // MARK: - 玩一玩（拼一拼 / 找相同 / 找朋友，跨 Tab 跳转游戏中心）

    private var playSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("玩一玩")
                .font(.system(size: Theme.scaled(16, settings: settings), weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)

            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
            LazyVGrid(columns: columns, spacing: 12) {
                playButton(GameModule.puzzle, title: "拼一拼") {
                    router.openNatureGame(natureId: item.id, game: .puzzle)
                }
                playButton(GameModule.findSame, title: "找相同") {
                    router.openNatureGame(natureId: item.id, game: .findSame)
                }
                playButton(GameModule.matching, title: "找朋友") {
                    router.openNatureGame(natureId: item.id, game: .matching)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .growCard(fill: .white.opacity(0.7))
    }

    private func playButton(_ module: GameModule, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                GameModuleIcon(module: module, size: 32)
                Text(title)
                    .font(.system(size: Theme.scaled(15, settings: settings), weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 76 * settings.buttonScaleFactor)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(module.tint.opacity(0.35))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(module.tint.opacity(0.6), lineWidth: 1)
            )
        }
        .buttonStyle(PressableButtonStyle(settings: settings))
        .accessibilityHint("去玩\(title)")
    }
}
