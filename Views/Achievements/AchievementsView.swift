import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var vm: PosterViewModel
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            // Dark aesthetic background
            LinearGradient(colors: ThemePalette.backgroundColors(for: scheme), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                Text("Your Trophies")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(ThemePalette.primaryText(for: scheme))
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(vm.achievements) { achievement in
                            AchievementRow(achievement: achievement)
                        }
                    }
                    .padding(20)
                }
            }
        }
    }
}

struct AchievementRow: View {
    let achievement: Achievement
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon Container
            ZStack {
                Circle()
                    .fill(achievement.unlocked ? 
                          LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing) :
                          LinearGradient(colors: [ThemePalette.primaryText(for: scheme).opacity(0.15), ThemePalette.primaryText(for: scheme).opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 50, height: 50)
                    .shadow(color: achievement.unlocked ? .orange.opacity(0.5) : .clear, radius: 8, x: 0, y: 4)
                
                Image(systemName: achievement.unlocked ? "trophy.fill" : "lock.fill")
                    .font(.system(size: 20))
                    .foregroundColor(achievement.unlocked ? .white : ThemePalette.secondaryText(for: scheme))
            }
            
            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(achievement.unlocked ? ThemePalette.primaryText(for: scheme) : ThemePalette.secondaryText(for: scheme))
                
                Text(achievement.unlocked ? "Unlocked" : "Locked")
                    .font(.caption)
                    .foregroundColor(achievement.unlocked ? .yellow : ThemePalette.secondaryText(for: scheme))
            }
            
            Spacer()
            
            if achievement.unlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 20))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(scheme == .light ? Color.white.opacity(0.9) : Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(achievement.unlocked ? Color.yellow.opacity(0.3) : ThemePalette.primaryText(for: scheme).opacity(0.1), lineWidth: 1)
        )
    }
}
