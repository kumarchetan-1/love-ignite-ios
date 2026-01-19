import SwiftUI

struct TaskDetailSheet: View {
    let task: Challenge
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var scheme
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private func displayTitle() -> String {
        // If extraHot and has an imageName, derive a stylish name from the asset name:
        // Expected pattern (renamed): ks_34_aphrodite or ks_54_dragon_pose
        // Fallback still works for legacy ks_34_pose.
        if task.category == .extraHot, let name = task.imageName {
            let tokens = name
                .replacingOccurrences(of: "-", with: "_")
                .components(separatedBy: "_")
                .filter { !$0.isEmpty }
            
            var words: [String] = []
            var poseNumber: String?
            
            for t in tokens {
                if t.lowercased() == "ks" || t.lowercased() == "pose" {
                    continue
                }
                // number?
                if Int(t) != nil {
                    poseNumber = t
                    continue
                }
                words.append(t.capitalized)
            }
            
            if !words.isEmpty {
                return "Try " + words.joined(separator: " ")
            } else if let n = poseNumber {
                return "Try Pose \(n)"
            }
        }
        return task.title
    }

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
                    VStack(spacing: isIPad ? 48 : 32) {
                        
                        // Icon / Image Section
                        if let name = task.imageName {
                            // KAMASUTRA / IMAGE MODE
                            let neonColor = NeonColors.color(for: task.difficulty)
                            
                            ZStack {
                                Circle()
                                    .fill(neonColor.opacity(0.1))
                                    .frame(width: isIPad ? 400 : 280, height: isIPad ? 400 : 280)
                                    .blur(radius: 20)
                                
                                Image(name)
                                    .resizable()
                                    .renderingMode(.template)
                                    .scaledToFit()
                                    .frame(maxWidth: isIPad ? 360 : 260, maxHeight: isIPad ? 360 : 260)
                                    .foregroundColor(neonColor)
                                    .neonGlow(neonColor)
                                    .shadow(color: neonColor.opacity(0.5), radius: 15, x: 0, y: 0)
                            }
                            .padding(.top, 20)
                        } else {
                            // TEXT / ICON MODE
                            let neonColor = NeonColors.color(for: task.difficulty)
                            
                            ZStack {
                                Circle()
                                    .fill(neonColor.opacity(0.1))
                                    .frame(width: isIPad ? 180 : 120, height: isIPad ? 180 : 120)
                                    .blur(radius: 20)

                                Image(systemName: iconForCategory(task.category))
                                    .font(.system(size: isIPad ? 90 : 60))
                                    .foregroundColor(neonColor)
                                    .neonGlow(neonColor)
                            }
                            .padding(.top, 40)
                        }
                        
                        // Text Content Section
                        VStack(spacing: isIPad ? 24 : 16) {
                            Text(taskCategoryTitle().uppercased())
                                .font(.system(size: isIPad ? 16 : 12, weight: .bold, design: .rounded))
                                .tracking(2)
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                            
                            Text(displayTitle())
                                .font(.system(size: isIPad ? 42 : 28, weight: .black, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                                .padding(.horizontal, isIPad ? 60 : 20)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            if let hint = task.hint {
                                Text(hint)
                                    .font(.system(size: isIPad ? 20 : 16, weight: .medium, design: .rounded))
                                    .italic()
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.top, 8)
                            }
                        }
                        
                        // Action / Difficulty Info
                        HStack(spacing: 20) {
                            DifficultyBadge(difficulty: task.difficulty)
                                .scaleEffect(isIPad ? 1.3 : 1.0)
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
        case .loveQnA: return "Love Questions"
        }
    }
    
    private func iconForCategory(_ category: TaskCategory) -> String {
        switch category {
        case .general: return "heart.fill"
        case .locations: return "map.fill"
        case .questions: return "quote.bubble.fill"
        case .techniques: return "sparkles"
        case .extraHot: return "flame.fill"
        case .loveQnA: return "questionmark.bubble.fill"
        }
    }
}

struct DifficultyBadge: View {
    let difficulty: Difficulty
    
    private func formattedPoseName(from imageName: String) -> String {
        // Strip prefix like "ks_34_pose" and convert to a styled name
        let trimmed = imageName
            .replacingOccurrences(of: "ks_", with: "")
            .replacingOccurrences(of: "_pose", with: "")
            .replacingOccurrences(of: "_", with: " ")
        let number = trimmed.trimmingCharacters(in: .whitespaces)
        return "Pose \(number)"
    }
    
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
