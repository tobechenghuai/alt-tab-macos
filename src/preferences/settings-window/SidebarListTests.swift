import XCTest
import Cocoa

final class SidebarListTests: XCTestCase {
    func testReusingRowKeepsViewCountStable() {
        let row = SidebarListRow()
        row.setContent("Shortcut 2", "App Icons")
        let count = descendantViews(row).count
        for index in 3...9 {
            row.setContent("Shortcut \(index)", "Titles")
        }
        XCTAssertEqual(descendantViews(row).count, count)
        XCTAssertEqual(row.toolTip, "Shortcut 9\nTitles")
    }

    func testReusingRowClearsPreviousSummaryFromTooltip() {
        let row = SidebarListRow()
        row.setContent("Shortcut 2", "App Icons")
        row.setContent("Shortcut 3", "")
        XCTAssertEqual(row.toolTip, "Shortcut 3")
    }

    private func descendantViews(_ view: NSView) -> [NSView] {
        view.subviews + view.subviews.flatMap { descendantViews($0) }
    }
}
