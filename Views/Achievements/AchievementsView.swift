import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var vm: PosterViewModel
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            // Background is now handled by the parent view for iPad detail
            // but for iPhone it still needs its own or a clear background
            if UIDevice.current.userInterfaceIdiom != .pad {
                LinearGradient(colors: ThemePalette.backgroundColors(for: self.scheme), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                // Modern Header
                let isIPad = UIDevice.current.userInterfaceIdiom == .pad
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your Trophies")
                            .font(.system(size: isIPad ? 48 : 34, weight: .black, design: .rounded))
                            .foregroundColor(ThemePalette.primaryText(for: self.scheme))
                        
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.yellow)
                            Text("\(vm.achievements.filter { $0.unlocked }.count) of \(vm.achievements.count) Collected")
                                .font(.system(size: isIPad ? 20 : 16, weight: .bold, design: .rounded))
                                .foregroundColor(ThemePalette.secondaryText(for: self.scheme))
                        }
                    }
                    Spacer()
                    
                    // Stats Circle
                    ZStack {
                        Circle()
                            .stroke(Color.yellow.opacity(0.2), lineWidth: 4)
                            .frame(width: isIPad ? 80 : 60, height: isIPad ? 80 : 60)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(vm.achievements.filter { $0.unlocked }.count) / CGFloat(max(1, vm.achievements.count)))
                            .stroke(
                                LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: isIPad ? 80 : 60, height: isIPad ? 80 : 60)
                            .rotationEffect(.degrees(-90))
                        
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: isIPad ? 32 : 24))
                            .shadow(color: .yellow.opacity(0.3), radius: 5)
                    }
                }
                .padding(.horizontal, isIPad ? 40 : 24)
                .padding(.top, isIPad ? 60 : 85)
                .padding(.bottom, 24)
                
                ScrollView {
                    let columns = [
                        GridItem(.adaptive(minimum: isIPad ? 300 : 320), spacing: 16)
                    ]
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(vm.achievements) { achievement in
                            AchievementRow(achievement: achievement)
                        }
                    }
                    .padding(.horizontal, isIPad ? 40 : 20)
                    .padding(.bottom, 120)
                }
            }
        }
    }
}

struct AchievementRow: View {
    let achievement: Achievement
    @Environment(\.colorScheme) private var scheme
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // Icon Container with Glassmorphism
            ZStack {
                Circle()
                    .fill(achievement.unlocked ? 
                          LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing) :
                          LinearGradient(colors: [scheme == .dark ? .white.opacity(0.1) : .black.opacity(0.05), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 56, height: 56)
                    .shadow(color: achievement.unlocked ? .orange.opacity(0.4) : .clear, radius: 10, x: 0, y: 5)
                
                if achievement.unlocked {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(scheme == .dark ? .white.opacity(0.3) : .black.opacity(0.2))
                }
            }
            
            // Text Content
            VStack(alignment: .leading, spacing: 8) {
                Text(achievement.title)
                    .font(.system(size: isIPad ? 24 : 18, weight: .bold, design: .rounded))
                    .foregroundColor(achievement.unlocked ? ThemePalette.primaryText(for: self.scheme) : ThemePalette.primaryText(for: self.scheme).opacity(0.6))
                
                HStack(spacing: 6) {
                    if achievement.unlocked {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                            .font(isIPad ? .body : .caption)
                        Text("Unlocked")
                            .font(.system(size: isIPad ? 16 : 13, weight: .heavy, design: .rounded))
                            .foregroundColor(.green.opacity(0.8))
                    } else {
                        Image(systemName: "circle.dotted")
                            .foregroundColor(ThemePalette.secondaryText(for: self.scheme))
                            .font(isIPad ? .body : .caption)
                        Text("Locked")
                            .font(.system(size: isIPad ? 16 : 13, weight: .semibold, design: .rounded))
                            .foregroundColor(ThemePalette.secondaryText(for: self.scheme))
                    }
                }
            }
            
            Spacer()
            
            if achievement.unlocked {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(ThemePalette.secondaryText(for: self.scheme).opacity(0.3))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(self.scheme == .dark ? Color.white.opacity(0.05) : Color.white)
                .shadow(color: self.scheme == .dark ? .black.opacity(0.2) : Color.pink.opacity(0.06), radius: 15, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: achievement.unlocked ? 
                            [.yellow.opacity(0.5), .clear] : 
                            [ThemePalette.primaryText(for: self.scheme).opacity(0.1), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }
}
