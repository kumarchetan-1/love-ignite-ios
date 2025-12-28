import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var vm: PosterViewModel
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            LinearGradient(colors: ThemePalette.backgroundColors(for: scheme), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Modern Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Trophies")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(ThemePalette.primaryText(for: scheme))
                        
                        Text("\(vm.achievements.filter { $0.unlocked }.count) of \(vm.achievements.count) Collected")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(ThemePalette.secondaryText(for: scheme).opacity(0.8))
                    }
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 48, height: 44)
                            .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 20)
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(vm.achievements) { achievement in
                            AchievementRow(achievement: achievement)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100) // Padding for tab bar
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
                          LinearGradient(colors: [scheme == .dark ? .white.opacity(0.15) : .black.opacity(0.05), scheme == .dark ? .white.opacity(0.05) : .black.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 50, height: 50)
                    .shadow(color: achievement.unlocked ? .orange.opacity(0.4) : .clear, radius: 8, x: 0, y: 4)
                
                Image(systemName: achievement.unlocked ? "trophy.fill" : "lock.fill")
                    .font(.system(size: 20))
                    .foregroundColor(achievement.unlocked ? .white : (scheme == .dark ? .white.opacity(0.4) : .black.opacity(0.2)))
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
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(scheme == .light ? Color.white : Color.white.opacity(0.06))
                .shadow(color: scheme == .light ? Color.pink.opacity(0.08) : Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(achievement.unlocked ? Color.yellow.opacity(0.4) : ThemePalette.primaryText(for: scheme).opacity(0.1), lineWidth: 1)
        )
    }
}
