import SwiftUI

/// 自然对象详情：大图 + 三语发音 + 折叠简介（按年龄模式显示不同内容）
struct NatureDetailView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var audio: AudioManager
    let item: NatureItem

    @State private var showMore = false

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

                    // 名称
                    VStack(spacing: 4) {
                        Text(item.nameZh)
                            .font(.system(size: Theme.scaled(38, settings: settings), weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.ink)
                        Text(item.nameEn)
                            .font(.system(size: Theme.scaled(20, settings: settings), weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.inkSoft)
                    }

                    // 三语发音
                    LanguageButtonsRow(name: item.nameZh, nameEn: item.nameEn, itemKey: "\(item.id)-detail")

                    // 简介折叠卡片
                    descriptionCard

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationTitle(item.nameZh)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                FavoriteButton(kind: .nature, id: item.id)
            }
        }
        .onAppear {
            // 记录最近学习
            UserLibrary.shared.recordNatureVisit(item.id)
        }
        .onDisappear {
            audio.stop()
        }
    }

    private var descriptionCard: some View {
        let text = settings.prefersLongDescription ? item.descriptionLong : item.descriptionShort

        return VStack(alignment: .leading, spacing: 12) {
            Text("了解更多")
                .font(.system(size: Theme.scaled(16, settings: settings), weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)

            Text(text)
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
}
