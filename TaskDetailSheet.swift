import SwiftUI

struct TaskDetailSheet: View {
    let task: Challenge
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // 1. Full-screen aesthetic background
            LinearGradient(
                colors: [Color("bg1"), Color("bg2")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Decorative background elements
            GeometryReader { proxy in
                Circle()
                    .fill(NeonColors.color(for: task.difficulty).opacity(0.15))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: -50, y: -100)
                
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .blur(radius: 50)
                    .position(x: proxy.size.width, y: proxy.size.height * 0.6)
            }
            .ignoresSafeArea()

            // 2. Main Content
            VStack(spacing: 24) {
                // Custom Drag Indicator
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        
                        // Icon / Image Section
                        if let name = task.imageName {
                            // KAMASUTRA / IMAGE MODE
                            let neonColor = NeonColors.color(for: task.difficulty)
                            
                            ZStack {
                                Circle()
                                    .fill(neonColor.opacity(0.1))
                                    .frame(width: 280, height: 280)
                                    .blur(radius: 20)
                                
                                Image(name)
                                    .resizable()
                                    .renderingMode(.template)
                                    .scaledToFit()
                                    .frame(maxWidth: 260, maxHeight: 260)
                                    .foregroundColor(neonColor)
                                    .neonGlow(neonColor)
                                    .shadow(color: neonColor.opacity(0.5), radius: 10, x: 0, y: 0)
                            }
                            .padding(.top, 20)
                        } else {
                            // TEXT / ICON MODE
                            let neonColor = NeonColors.color(for: task.difficulty)
                            
                            ZStack {
                                Circle()
                                    .fill(neonColor.opacity(0.1))
                                    .frame(width: 120, height: 120)
                                    .blur(radius: 20)

                                Image(systemName: iconForCategory(task.category))
                                    .font(.system(size: 60))
                                    .foregroundColor(neonColor)
                                    .neonGlow(neonColor)
                            }
                            .padding(.top, 40)
                        }
                        
                        // Text Content Section
                        VStack(spacing: 16) {
                            Text(taskCategoryTitle().uppercased())
                                .font(.caption)
                                .fontWeight(.bold)
                                .tracking(2)
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                            
                            Text(task.title)
                                .font(.system(size: 28, weight: .semibold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                                .padding(.horizontal, 20)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            if let hint = task.hint {
                                Text(hint)
                                    .font(.subheadline)
                                    .italic()
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.top, 8)
                            }
                        }
                        
                        // Action / Difficulty Info
                        HStack(spacing: 20) {
                            DifficultyBadge(difficulty: task.difficulty)
                        }
                        .padding(.top, 10)
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden) // We drew our own custom one for better styling
    }

    private func taskCategoryTitle() -> String {
        switch task.category {
        case .general: return "Romantic Task"
        case .locations: return "Location Challenge"
        case .questions: return "Deep Question"
        case .extraHot: return "Kamasutra Position"
        case .techniques: return "Technique"
        }
    }
    
    private func iconForCategory(_ category: TaskCategory) -> String {
        switch category {
        case .general: return "heart.fill"
        case .locations: return "map.fill"
        case .questions: return "quote.bubble.fill"
        case .techniques: return "sparkles"
        case .extraHot: return "flame.fill"
        }
    }
}

struct DifficultyBadge: View {
    let difficulty: Difficulty
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(NeonColors.color(for: difficulty))
                .frame(width: 8, height: 8)
                .neonGlow(NeonColors.color(for: difficulty))
            
            Text(difficulty.rawValue.capitalized)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
    }
}
