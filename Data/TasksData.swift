import Foundation

/// Content for the Love Ignite card grid.
/// Love Ignite helps couples with modern dating problems: communication, mismatched
/// expectations, conflict, texting anxiety, date ideas and regular check-ins.
/// Levels: easy = Spark, medium = Connect, hard = Deepen, extreme = Grow.
struct TasksData {

    static func generateTasks(
        count: Int = 0,
        existingLocks: [String: Bool]? = nil
    ) -> (tasks: [Challenge], locks: [String: Bool]) {

        // Date ideas (category .general)
        let dateIdeas = [
            "Cook a new recipe together from scratch.", "Write each other a short letter and swap.",
            "Plan a dream trip on a shared map.", "Recreate your first date.",
            "Watch the sunset together, phones away.", "Have a tech-free evening.",
            "Make a couple's bucket list of 10 things.", "Dance to 'your song' in the living room.",
            "Take a long walk with no destination.", "Share your favourite childhood memory.",
            "Make a photo collage of your year.", "Have an indoor picnic.",
            "Read the first chapter of a book to each other.", "Draw each other's portrait in 5 minutes.",
            "Bake a dessert together.", "Stargaze and find three constellations.",
            "Plan a surprise date for next weekend.", "Visit a place neither of you has been.",
            "Learn a new skill together from a video.", "Build a blanket fort and watch a movie.",
            "Go to a museum or art gallery.", "Do a workout or yoga session together.",
            "Plant something and look after it together.", "Make breakfast for each other.",
            "Invent a signature mocktail.", "Play a board game or card game.",
            "Do a jigsaw puzzle together.", "Volunteer together for an afternoon.",
            "Have a homemade pizza night.", "Take a pottery or painting class.",
            "Go to a trivia night as a team.", "Have a spa evening at home.",
            "Make a time capsule to open in a year.", "Have a karaoke night.",
            "Try a cuisine neither of you has eaten.", "Make a playlist for each other."
        ]

        // Out & About (category .locations)
        let outAndAbout = [
            "Hold hands on a walk through a park.", "Take a goofy selfie in a crowd.",
            "Find a quiet bench and share one wish for the future.", "Visit a local market and pick ingredients for dinner.",
            "Go bowling or mini-golfing.", "Ride a tandem bike or rent bikes together.",
            "Visit a botanical garden.", "Go fruit picking.",
            "Try a new café and order for each other.", "Go to a live music night.",
            "Take a day trip to a nearby town.", "Watch a street performer and tip them together.",
            "Go to a comedy show.", "Explore a bookshop and buy each other a book.",
            "Have a picnic in a new spot.", "Go to an aquarium or zoo.",
            "Introduce your partner proudly to someone new.", "Cheer for each other at a game.",
            "Let them choose the restaurant and enjoy it fully.", "Go on a sunrise walk.",
            "Try a dance class together.", "Go to a farmers' market and cook what you find.",
            "Take photos of each other at a favourite spot.", "Find the best street food in your city."
        ]

        // Talk prompts for modern dating (category .questions)
        let talkPrompts = [
            "How often do you like to text during the day?",
            "What does a 'good morning' text mean to you?",
            "When I don't reply quickly, what goes through your mind?",
            "What's one thing about dating apps you're glad we left behind?",
            "How do you like to be comforted after a hard day?",
            "What's your ideal balance of time together and time apart?",
            "What does commitment look like to you this year?",
            "What's one small thing I do that makes you feel loved?",
            "How do you prefer to plan dates: spontaneous or scheduled?",
            "What's a money habit you'd like us to talk about?",
            "How do you feel about sharing our relationship on social media?",
            "Which of my friends do you want to know better?",
            "What's a dealbreaker you've learned from past relationships?",
            "What's one goal you'd love my support with?",
            "How do you know when you need space?",
            "What's your favourite memory of us so far?",
            "Where do you see us in five years?",
            "What's your love language, and has it changed?",
            "What family tradition do you want to keep?",
            "What helps you feel safe bringing up a problem?",
            "What's a compliment you'd love to hear more often?",
            "How should we handle holidays with both families?",
            "What does a perfect lazy Sunday look like?",
            "What's something new you'd like us to try together?"
        ]

        // Relationship skills: communication, conflict, expectations, check-ins (category .techniques)
        let skills = [
            "Do a 10-minute weekly check-in: one high, one low, one wish.",
            "Try the speaker-listener exercise: repeat back what you heard before replying.",
            "Swap 'you always' for 'I feel ... when ...' in your next disagreement.",
            "Agree on a pause word that means 'let's take 20 minutes and come back'.",
            "Write down three expectations you have for weekends, then compare lists.",
            "Each take the love-languages quiz and share your top two.",
            "Plan one act of service in your partner's love language this week.",
            "Talk about texting: how fast, how often, and what 'seen' means to each of you.",
            "Share one thing that makes you anxious in dating and how your partner can help.",
            "Make a repair plan: what each of you needs after an argument.",
            "List three things you appreciate about your partner, out loud.",
            "Set one shared goal for this month and a small first step.",
            "Agree on how you'll split plans, chores or costs for the next date.",
            "Describe your ideal week together, then find the overlap.",
            "Practice a phone-free dinner and notice how the talk changes.",
            "Revisit a past disagreement and say what you learned from it.",
            "Share your boundaries around friends, exes and social media.",
            "Talk about what 'exclusive' and 'serious' mean to each of you.",
            "End the day by naming one thing your partner did well.",
            "Write a couple's mission statement in three sentences.",
            "Plan a monthly relationship check-in on your calendars.",
            "Ask: 'What's one thing I could do to make this week easier for you?'",
            "Share a worry and only listen — no fixing for 5 minutes.",
            "Agree on how you'll make big decisions together."
        ]

        // 36 questions to build closeness (category .loveQnA)
        let loveQnA36 = [
            "Given the choice of anyone in the world, whom would you want as a dinner guest?",
            "Would you like to be famous? In what way?",
            "Before making a phone call, do you ever rehearse what you're going to say? Why?",
            "What would be a perfect day for you?",
            "When did you last sing to yourself? To someone else?",
            "If you could live to 90 with either the mind or body of a 30-year-old for the last 60 years, which would you choose?",
            "Name three things you and your partner appear to have in common.",
            "For what in your life do you feel most grateful?",
            "If you could change anything about the way you were raised, what would it be?",
            "Take four minutes and tell your partner your life story in as much detail as possible.",
            "If you could wake up tomorrow having gained one quality or ability, what would it be?",
            "If a crystal ball could tell you the truth about anything, what would you want to know?",
            "Is there something you've dreamed of doing for a long time? Why haven't you done it?",
            "What is the greatest accomplishment of your life?",
            "What do you value most in a friendship?",
            "What is your most treasured memory?",
            "If you knew you had one year left, would you change how you're living now? Why?",
            "What does friendship mean to you?",
            "What roles do love and affection play in your life?",
            "Take turns sharing five positive characteristics of your partner.",
            "How close and warm is your family?",
            "Make three true \"we\" statements each.",
            "Complete this sentence: \"I wish I had someone with whom I could share...\"",
            "What would be important for your partner to know if you became close friends?",
            "Tell your partner what you like about them; be honest.",
            "Share an embarrassing moment in your life.",
            "When did you last cry in front of another person? By yourself?",
            "What, if anything, is too serious to be joked about?",
            "What would you most regret not having told someone? Why haven't you told them yet?",
            "Your home catches fire. After saving loved ones and pets, what one item would you save? Why?",
            "Share a personal problem and ask your partner how they might handle it.",
            "What is your favourite way to spend a weekend together?"
        ]

        var pool: [(String, TaskCategory)] = []
        pool += dateIdeas.map { ($0, .general) }
        pool += outAndAbout.map { ($0, .locations) }
        pool += talkPrompts.map { ($0, .questions) }
        pool += skills.map { ($0, .techniques) }
        pool += loveQnA36.map { ($0, .loveQnA) }
        pool.shuffle()

        let levels: [Difficulty] = [.easy, .medium, .hard, .extreme]
        let perLevel = Int((Double(pool.count) / Double(levels.count)).rounded(.up))

        var finalTasks: [Challenge] = []
        for (index, item) in pool.enumerated() {
            let level = levels[min(index / perLevel, levels.count - 1)]
            finalTasks.append(Challenge(
                id: "task_\(index)",
                number: index + 1,
                title: item.0,
                category: item.1,
                difficulty: level,
                hint: nil,
                imageName: nil,
                isLocked: false
            ))
        }
        return (finalTasks, [:])
    }

    /// Five daily connection prompts.
    static func generateDailyTasks() -> [Challenge] {
        let dailyPool = [
            "Send a 'thinking of you' message with no emoji, just words.",
            "Do a 5-minute check-in: how are you really today?",
            "Cook something simple together.",
            "Write down 3 things you love about each other.",
            "Plan your next date in under 10 minutes.",
            "Ask one question from the Talk deck over dinner.",
            "Go for a 15-minute walk, phones in pockets.",
            "Share one thing you're looking forward to this week.",
            "Thank your partner for something small they did.",
            "Make hot chocolate and talk about your week."
        ]
        return dailyPool.shuffled().prefix(5).enumerated().map { i, txt in
            Challenge(id: "daily_\(i)", number: i + 1, title: txt, category: .general,
                      difficulty: .medium, hint: "Daily Spark", imageName: nil, isLocked: false)
        }
    }
}
