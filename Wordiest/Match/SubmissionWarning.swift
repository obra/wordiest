enum SubmissionWarning {
    static func message(validWordCount: Int) -> String? {
        switch validWordCount {
        case 0:
            return "Submit no words?"
        case 1:
            return "Submit only one word?"
        case 2:
            return "Submit these words?"
        default:
            return nil
        }
    }
}

