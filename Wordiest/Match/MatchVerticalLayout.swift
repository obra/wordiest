import CoreGraphics

enum MatchVerticalLayout {
    struct Centers: Equatable {
        var word1: CGFloat
        var word2: CGFloat
        var bank1: CGFloat
        var bank2: CGFloat
    }

    // Mirrors Android `MergedMatch.doLayout` vertical arrangement:
    // - bank2 sits above the bottom inset by `spacer`
    // - bank1 sits above bank2 by `spacer`
    // - the remaining space above bank1 is divided into 3 equal gaps:
    //   scoreArea + gap + word1 + gap + word2 + gap + bank1
    static func centers(
        containerHeight: CGFloat,
        topInset: CGFloat,
        bottomInset: CGFloat,
        spacer: CGFloat,
        scoreAreaHeight: CGFloat,
        word1Height: CGFloat,
        word2Height: CGFloat,
        bank1Height: CGFloat,
        bank2Height: CGFloat
    ) -> Centers {
        let top = max(0, containerHeight - topInset)
        let bottom = max(0, bottomInset)

        let bank2Bottom = bottom + spacer
        let bank2Top = bank2Bottom + bank2Height

        let bank1Bottom = bank2Top + spacer
        let bank1Top = bank1Bottom + bank1Height

        let availableAboveBank1 = max(0, top - bank1Top)
        let gap = max(0, (availableAboveBank1 - scoreAreaHeight - word1Height - word2Height) / 3.0)

        let word2Bottom = bank1Top + gap
        let word2Top = word2Bottom + word2Height

        let word1Bottom = word2Top + gap

        return Centers(
            word1: word1Bottom + (word1Height / 2.0),
            word2: word2Bottom + (word2Height / 2.0),
            bank1: bank1Bottom + (bank1Height / 2.0),
            bank2: bank2Bottom + (bank2Height / 2.0)
        )
    }
}

