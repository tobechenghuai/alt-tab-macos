enum CliAccessPolicy {
    static let enableArgument = "--enable-cli"

    static func isEnabled(arguments: [String]) -> Bool {
        arguments.dropFirst().contains(enableArgument)
    }
}
