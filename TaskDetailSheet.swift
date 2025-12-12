import SwiftUI

struct TaskDetailSheet: View {
    let task: Task

    var body: some View {
        VStack(spacing: 14) {
            Capsule().frame(width:40,height:6).foregroundColor(.white.opacity(0.25)).padding(.top,8)

            HStack {
                if let name = task.imageName {
                    let neonColor = NeonColors.color(for: task.difficulty)
                    Image(name)
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .foregroundColor(neonColor)
                        .neonGlow(neonColor)
                        .frame(maxHeight: 260)
                        .padding(.trailing, 6)
                }
                VStack(alignment:.leading) {
                    Text(taskTitle()).font(.headline).foregroundColor(.white)
                    Text(task.title).foregroundColor(.white.opacity(0.9)).padding(.top,4)
                }
            }
            .padding()
            Spacer()
        }
        .background(LinearGradient(colors: [Color("cardBg1"), Color("cardBg2")], startPoint: .top, endPoint: .bottom))
    }

    private func taskTitle() -> String {
        switch task.category {
        case .general: return "Romantic Task"
        case .locations: return "Location"
        case .questions: return "Intimate Q"
        case .extraHot: return "Premium Position"
        case .techniques: return "Technique"
        }
    }
}
