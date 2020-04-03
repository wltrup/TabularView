import UIKit

// MARK: - SortOrder

/// An enumeration to define the sort order in a sort request.
///
public enum SortOrder {
    case ascending
    case descending
}

// MARK: - TabularViewSortDelegate

/// Classes conforming to this protocol (typically, a view controller) use this delegate
/// function to perform the requested sort action. They can do it synchronously in the
/// main thread or asynchronously in a background thread. Either way, they should invoke
/// the completion handler when the sort action is completed. The completion handler need
/// *not* be invoked in the main thread.
///
public protocol TabularViewSortDelegate: class {

    func sortRequested <CId: ColumnIdType>
        (for columnId: CId, sortOrder: SortOrder, completion: () -> Void)

}

// MARK: - SortState

/// An enumeration to define a column's sort state.
///
public enum SortState {
    case sortedAscending
    case sortedDescending
    case unknown
}
