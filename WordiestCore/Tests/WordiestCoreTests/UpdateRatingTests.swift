import XCTest
@testable import WordiestCore

final class UpdateRatingTests: XCTestCase {
    func testCeilTenths() {
        XCTAssertEqual(UpdateRating.ceilTenths(12.30), 12.3)
        XCTAssertEqual(UpdateRating.ceilTenths(12.31), 12.4)
        XCTAssertEqual(UpdateRating.ceilTenths(0.01), 0.1)
    }

    func testUpdateComputesPercentileAndNewRating() {
        var update = UpdateRating(rating: 50.0, ratingDeviation: 0.0)

        let samples: [UpdateRating.ScoreRating] = [
            .init(score: 10, rating: 60.0, wordsEncoding: nil),
            .init(score: 30, rating: 60.0, wordsEncoding: nil),
        ]
        update.update(playerScore: 20, opponents: samples)

        XCTAssertEqual(update.percentile, 50.0)
        XCTAssertEqual(update.newRating, 50.0)
    }
}

