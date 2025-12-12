import Foundation

struct TasksData {
    static func generateTasks(count: Int = 169) -> [Task] {
        var tasks: [Task] = []

        // sample text templates (you can expand)
        let starters = [
            "Recreate your first date photo",
            "Cook a meal together from scratch",
            "Write a love letter and read it aloud",
            "Plan a surprise picnic",
            "Create a signature couple's cocktail",
            "Dance together in the living room",
            "Take a scenic sunset walk",
            "Watch each other's favorite childhood movie",
            "Share a secret you've never told anyone",
            "Give each other a 10-minute massage"
        ]

        let romanticTemplates = [
            "Set up a candlelit dinner and dress up",
            "Hide small notes around the house with compliments",
            "Make a playlist of songs that describe your relationship",
            "Do a digital detox together for an evening",
            "Have a themed movie marathon (choose a city/place)",
            "Write down 5 things you appreciate about each other",
            "Recreate a favorite shared memory in detail",
            "Take turns asking each other deep questions",
            "Create a joint bucket list for the next year",
            "Spend the day exploring a nearby town"
        ]

        let spicyExtras = [
            "Try a playful roleplay scene",
            "Give each other a flirty dare",
            "Share an intimate fantasy (mutual consent)",
            "Slow dance without music for 2 minutes",
            "Blindfold and feed each other a dessert"
        ]

        // Build list of available extraHot image asset names (ks_01_pose ... ks_69_pose)
        var kamaAssets: [String] = (1...69).map { i in String(format: "ks_%02d_pose", i) }
        kamaAssets.shuffle() // randomize; will assign uniquely

        var nextKamaIndex = 0

        for i in 0..<count {
            let id = "task_\(i)"
            let title: String
            if i < starters.count {
                title = starters[i]
            } else if i < starters.count + romanticTemplates.count {
                title = romanticTemplates[(i - starters.count) % romanticTemplates.count]
            } else if i % 13 == 0 {
                title = spicyExtras[i % spicyExtras.count]
            } else {
                // combine to generate variety
                let a = romanticTemplates[i % romanticTemplates.count]
                let b = starters[i % starters.count]
                title = "\(a) — then \(b.lowercased())"
            }

            // Choose category
            let cat: TaskCategory
            if i % 11 == 0 {
                cat = .extraHot
            } else if i % 7 == 0 {
                cat = .locations
            } else if i % 5 == 0 {
                cat = .questions
            } else {
                cat = .general
            }

            // difficulty distribution (4 levels)
            let diff: Difficulty
            switch i % 4 {
            case 0: diff = .easy
            case 1: diff = .medium
            case 2: diff = .hard
            default: diff = .extreme
            }

            // assign image ONLY for extraHot and take from the non-repeating pool:
            var imageName: String? = nil
            if cat == .extraHot {
                if nextKamaIndex < kamaAssets.count {
                    imageName = kamaAssets[nextKamaIndex]
                    nextKamaIndex += 1
                } else {
                    // fallback (shouldn't happen) - wrap around
                    imageName = kamaAssets[nextKamaIndex % kamaAssets.count]
                    nextKamaIndex += 1
                }
            }

            tasks.append(Task(id: id, title: title, category: cat, difficulty: diff, hint: nil, imageName: imageName))
        }

        return tasks
    }
}
