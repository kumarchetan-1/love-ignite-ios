import Foundation

struct TasksData {
    // We now separate the logic:
    // 1. generateGridTasks(count: 200) -> for the main grid
    // 2. generateDailyTasks() -> for the top 5 distinct tasks
    
    static func generateTasks(count: Int = 200) -> [Challenge] {
        // --- 1. Master Content Pools ---
        let romanticTasks = [
            "Cook a meal together from scratch.", "Write a love letter to each other.",
            "Plan a dream vacation.", "Recreate your first date.",
            "Give each other a 15-minute massage.", "Watch the sunrise or sunset together.",
            "Have a technology-free evening.", "Create a couple's bucket list.",
            "Dance to 'your song' in the living room.", "Go for a long walk holding hands.",
            "Leave a surprise note in a pocket/purse.", "Share your favorite childhood memory.",
            "Make a photo album or collage.", "Have a picnic (indoor or outdoor).",
            "Read a book to each other.", "Draw or paint each other's portrait.",
            "Bake a dessert together.", "Take a bubble bath together.",
            "Stargaze and find constellations.", "Compliment 5 things about each other.",
            "Plan a surprise date night.", "Visit a place you've never been.",
            "Learn a new skill together.", "Share a secret you've never told anyone.",
            "Write down 3 goals for your future.", "Make a blanket fort and watch a movie.",
            "Feed each other chocolate or fruit.", "Go to a museum or art gallery.",
            "Exercise or do yoga together.", "Plant a tree or flowers together.",
            "Have breakfast in bed.", "Write a poem for your partner.",
            "Create a custom cocktail/mocktail.", "Play a board game or card game.",
            "Do a puzzle together.", "Volunteer together for a day.",
            "Go wine or cheese tasting.", "Recreate a favorite movie scene.",
            "Have a pillow fight.", "Take a nap together.",
            "Visit a local market.", "Go bowling or mini-golfing.",
            "Sing karaoke together.", "Make a time capsule.",
            "Go for a drive with no destination.", "Watch home movies or old videos.",
            "Make homemade pizza.", "Whisper something sweet in public.",
            "Hold eye contact for 2 minutes.", "Kiss in the rain (or shower).",
            "Build a piece of furniture together.", "Have a video game night.",
            "Go to a comedy club.", "Plan a staycation.",
            "Go fruit picking.", "Take a pottery class.",
            "Go to a jazz club.", "Rent a tandem bike.",
            "Go for a night swim.", "Write a song together.",
            "Blind taste test with food.", "Go to an aquarium.",
            "Have a fondue night.", "Go camping in backyard.",
            "Write a seasonal bucket list.", "Go to a drive-in movie.",
            "Make a scrapbook.", "Go to trivia night.",
            "Spa day at home.", "Visit botanical garden."
        ] // Approx 70 items

        let locationTasks = [
            "Kiss in an elevator.", "Make out in a parked car.",
            "Hold hands in a cinema.", "Quick kiss at a red light.",
            "Flirt at a grocery store.", "Whisper in a library.",
            "Cuddle on a park bench.", "Hold hands under dinner table.",
            "Sneak a kiss in a fitting room.", "Hug tight at a train station.",
            "Touch feet under a desk.", "Share a drink with two straws.",
            "Kiss on a bridge.", "Lean on each other on a bus.",
            "Selfie in a mirror.", "Slow dance in kitchen.",
            "Carry partner across room.", "Sit on partner's lap.",
            "Walk in rain without umbrella.", "Kiss at top of hill.",
            "Kiss on Ferris wheel.", "Hold hands skating.",
            "Kiss under streetlamp.", "Cuddle by fireplace.",
            "Kiss in photo booth.", "Hold hands in museum.",
            "Kiss on a boat.", "Cuddle in hammock.",
            "Kiss in snow.", "Hold hands at concert.",
            "Kiss on balcony.", "Cuddle in tent.",
            "Kiss in pool.", "Hold hands on plane.",
            "Kiss at midnight.", "Cuddle on rooftop.",
            "Kiss in garden.", "Hold hands on rollercoaster.",
            "Kiss in vineyard.", "Cuddle on beach."
        ] // 40 items
        
        let questionTasks = [
            "Favorite memory of us?", "Biggest turn-on?",
            "Dream date?", "Us in 5 years?",
            "Love about my body?", "Most romantic thing I've done?",
            "Favorite way to be touched?", "Fantasy to share?",
            "Song that reminds you of me?", "Go anywhere now?",
            "Favorite feature of mine?", "First fell for me?",
            "Makes you feel loved?", "New thing to try in bed?",
            "Perfect Sunday?", "Habit you adore?",
            "Laugh hardest?", "Best gift ever?",
            "Favorite smell on me?", "Movie character like me?",
            "Love language?", "Secret talent?",
            "Biggest fear?", "Proudest accomplishment?",
            "Favorite childhood tradition?", "Favorite way to relax?",
            "Want to learn?", "Favorite book?",
            "Favorite movie?", "Favorite food?",
            "Dream job?", "Favorite travel destination?",
            "Favorite season?", "Favorite holiday?",
            "Favorite animal?", "Favorite color?",
            "Favorite flower?", "Favorite scent?",
            "Favorite dessert?", "Favorite drink?"
        ] // 40 items

        let intimateTasks = [
            "Blindfold and feed partner.", "Sensual hand massage.",
            "Whisper naughty secret.", "Strip card game.",
            "Share untold fantasy.", "5 mins just kissing.",
            "Trace words on back.", "Shower by candlelight.",
            "Foot massage with oil.", "Roleplay meeting at bar.",
            "Wear something partner loves.", "Risky text from other room.",
            "Feather/ice on skin.", "Describe what you want.",
            "Eye contact during intimacy.", "Explore new zone.",
            "Read erotic story.", "Temperature play.",
            "Scalp massage.", "Sleep naked.",
            "Blindfold touch guessing game."
        ] // 21 items

        // 2. Pools for mix & match
        // We want every level to have a MIX of tasks + positions.
        // Positions are restricted by difficulty as requested: "Only use respective kamasutra positions as well"
        // But text tasks should be mixed? "every level should have mix of tasks not just questions..."
        
        // Let's pool all TEXT tasks together and assign them random difficulties or evenly distribute them?
        // User said: "every level should have mix of tasks"
        // User also said: "Only use respective kamasutra positions... easy position shouldn't be in other category"
        
        // Strategy:
        // 1. Assign positions strictly to their level.
        // 2. Mix all text tasks into one big pool.
        // 3. Distribute text tasks evenly across the 4 levels to ensure variety in each level.
        
        var allTextTasks: [(title: String, cat: TaskCategory)] = []
        allTextTasks.append(contentsOf: romanticTasks.map { ($0, .general) })
        allTextTasks.append(contentsOf: locationTasks.map { ($0, .locations) })
        allTextTasks.append(contentsOf: questionTasks.map { ($0, .questions) })
        allTextTasks.append(contentsOf: intimateTasks.map { ($0, .techniques) })
        allTextTasks.shuffle()
        
        // Prepare buckets
        var easyTasks: [(title: String, cat: TaskCategory, diff: Difficulty, img: String?, locked: Bool)] = []
        var mediumTasks: [(title: String, cat: TaskCategory, diff: Difficulty, img: String?, locked: Bool)] = []
        var hardTasks: [(title: String, cat: TaskCategory, diff: Difficulty, img: String?, locked: Bool)] = []
        var extremeTasks: [(title: String, cat: TaskCategory, diff: Difficulty, img: String?, locked: Bool)] = []
        
        // A. Distribute Positions (Strict Difficulty)
        let easyPosRange = 1...17
        let medPosRange = 18...34
        let hardPosRange = 35...51
        let extremePosRange = 52...69
        
        // Decide 20 unlocked positions globally
        var unlockedIndices = Set<Int>()
        while unlockedIndices.count < 20 {
            unlockedIndices.insert(Int.random(in: 1...69))
        }
        
        for i in 1...69 {
            let img = String(format: "ks_%02d_pose", i)
            let isLocked = !unlockedIndices.contains(i)
            let taskTitle = "Try this position."
            
            if easyPosRange.contains(i) {
                easyTasks.append((title: taskTitle, cat: .extraHot, diff: .easy, img: img, locked: isLocked))
            } else if medPosRange.contains(i) {
                mediumTasks.append((title: taskTitle, cat: .extraHot, diff: .medium, img: img, locked: isLocked))
            } else if hardPosRange.contains(i) {
                hardTasks.append((title: taskTitle, cat: .extraHot, diff: .hard, img: img, locked: isLocked))
            } else if extremePosRange.contains(i) {
                extremeTasks.append((title: taskTitle, cat: .extraHot, diff: .extreme, img: img, locked: isLocked))
            }
        }
        
        // B. Fill remainder of each bucket (target 50) with Mixed Text Tasks
        let targetPerCategory = 50
        
        func fillBucket(bucket: inout [(title: String, cat: TaskCategory, diff: Difficulty, img: String?, locked: Bool)], difficulty: Difficulty) {
            while bucket.count < targetPerCategory {
                if let task = allTextTasks.popLast() {
                    bucket.append((title: task.title, cat: task.cat, diff: difficulty, img: nil, locked: false))
                } else {
                    break // Ran out of tasks
                }
            }
        }
        
        fillBucket(bucket: &easyTasks, difficulty: .easy)
        fillBucket(bucket: &mediumTasks, difficulty: .medium)
        fillBucket(bucket: &hardTasks, difficulty: .hard)
        fillBucket(bucket: &extremeTasks, difficulty: .extreme)
        
        // Shuffle within buckets so positions aren't all at the top
        easyTasks.shuffle()
        mediumTasks.shuffle()
        hardTasks.shuffle()
        extremeTasks.shuffle()
        
        // Combine in order
        let allSorted = easyTasks + mediumTasks + hardTasks + extremeTasks
        
        var finalTasks: [Challenge] = []
        for (index, item) in allSorted.enumerated() {
            let id = "task_\(index)"
            // Use index + 1 for counting 1..200
            let number = index + 1
            
            finalTasks.append(Challenge(
                id: id,
                number: number, // Counts from 1 to 200
                title: item.title,
                category: item.cat,
                difficulty: item.diff,
                hint: nil,
                imageName: item.img,
                isLocked: item.locked
            ))
        }
        
        return finalTasks
    }
    
    // --- New: Tasks of the Day (5 Distinct, Indoor, Intimate) ---
    static func generateDailyTasks() -> [Challenge] {
        let dailyPool = [
            "Build a cozy pillow fort and read together.",
            "Share a slow dance in the kitchen to jazz.",
            "Give each other a 5-minute foot rub.",
            "Cook a new pasta recipe together.",
            "Write down 3 things you love about each other.",
            "Play a board game with loser giving a massage.",
            "Take a warm bubble bath with candles.",
            "Do a puzzle while listening to an audiobook.",
            "Make homemade hot chocolate/cocktails.",
            "Stargaze from the window/balcony."
        ]
        
        // Pick 5 random unique
        let selected = dailyPool.shuffled().prefix(5)
        
        var tasks: [Challenge] = []
        for (i, txt) in selected.enumerated() {
            tasks.append(Challenge(
                id: "daily_\(i)",
                number: i + 1,
                title: txt,
                category: .general,
                difficulty: .medium, // Just a placeholder
                hint: "Daily Special",
                imageName: nil,
                isLocked: false
            ))
        }
        return tasks
    }
}
