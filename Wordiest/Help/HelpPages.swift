struct HelpPage: Identifiable, Equatable {
    var id: String { title }
    var title: String
    var html: String
}

enum HelpPages {
    static let pages: [HelpPage] = [
        HelpPage(
            title: "Playing",
            html: """
            <b>Playing Wordiest</b> <br><br> Drag letters from the bottom to <b>form two words</b> in the rows at the top.<br><br>
            Letters are worth points, the value in the lower right. <br><br> Some letters have bonuses. For example, <b>3L</b> <b>triples</b> a letter value, and <b>2W</b> <b>doubles</b> overall word score. <br><br> Combine bonuses for giant scores! <br><br>Press <b>reset</b> to clear, press and hold clears only non-words.
            """
        ),
        HelpPage(
            title: "Scoring",
            html: """
            <b>Score and Rating</b> <br><br> The graph shows scores and ratings from players given the same letters. <br><br> You are <b>always</b> in the center. <br><br> <b>Touch</b> to see submitted words.<br><br>
            <b>Wordiest</b> shows your score and the percent of players you beat that game. <br><br> Your <b>rating</b> is a moving average slowly tracking that percentile. It grows toward new higher values or falls toward new lower ones. Check <b>leaderboards</b> to compete with friends!
            """
        ),
        HelpPage(
            title: "History",
            html: """
            <b>History</b> <br><br> History lists your past matches showing submitted words, points, and rating change. <br><br> Press and hold an entry to delete it. <br><br> The graph shows your rating over time. <br><br> Abnormal rating changes are drawn in red, such as a cloud storage rating update when moving between devices or after sign-in, or when joining adjacent entries after deleting an entry. There may also be rare cases when saving a match result failed.
            """
        ),
        HelpPage(
            title: "Sharing",
            html: """
            <b>Wordiest</b> uses <b>Google Play</b> <br> <br><b>&#149; Leaderboards</b>: Compete with friends or the world for the best scores and ratings. <br> <br><b>&#149; Achievements</b>: Challenge yourself to accomplish special feats. <br> <br><b>&#149; Cloud Store</b>: Sign in on any device to pick up where you left off.<br><br>
            Sign in with Google to share and compete with friends!
            """
        ),
    ]
}
