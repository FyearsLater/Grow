import SwiftUI

/// 开发日志页：按时间倒序列出历次迭代的修改与优化。
struct DevLogView: View {
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("开发日志")
                        .font(.system(size: Theme.scaled(30, settings: settings), weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                        .padding(.top, 8)

                    Text("记录 Grow 的每一次更新与优化")
                        .font(.system(size: Theme.scaled(14, settings: settings), weight: .medium))
                        .foregroundStyle(Theme.inkSoft)

                    ForEach(DevLog.all) { entry in
                        entryCard(entry)
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("开发日志")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func entryCard(_ entry: DevLogEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("v\(entry.version)")
                    .font(.system(size: Theme.scaled(18, settings: settings), weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.poemAccent)
                Text(entry.date)
                    .font(.system(size: Theme.scaled(13, settings: settings), weight: .medium))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                if entry.isCurrent {
                    Text("当前")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Theme.vegetable))
                }
            }

            Text(entry.title)
                .font(.system(size: Theme.scaled(16, settings: settings), weight: .semibold))
                .foregroundStyle(Theme.ink)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(entry.changes.enumerated()), id: \.offset) { _, change in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundStyle(Theme.poemWarm)
                            .font(.system(size: Theme.scaled(15, settings: settings), weight: .bold))
                        Text(change)
                            .font(.system(size: Theme.scaled(14, settings: settings), weight: .medium))
                            .foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .growCard(fill: .white.opacity(0.75))
    }
}
