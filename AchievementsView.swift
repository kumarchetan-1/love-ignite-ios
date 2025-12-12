import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var vm: PosterViewModel

    var body: some View {
        NavigationView {
            List {
                ForEach(vm.achievements) { a in
                    HStack {
                        Image(systemName: a.unlocked ? "checkmark.seal.fill" : "seal")
                            .foregroundColor(a.unlocked ? .yellow : .gray)
                        Text(a.title)
                        Spacer()
                        if a.unlocked { Text("Unlocked").font(.caption).foregroundColor(.green) }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Achievements")
        }
    }
}