enum WindowCapturePolicy {
    static func allowsCapture(inBackground: Bool, switcherActive: Bool) -> Bool {
        switcherActive || inBackground
    }
}
