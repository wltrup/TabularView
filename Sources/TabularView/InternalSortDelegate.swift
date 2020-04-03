import UIKit

// MARK: - InternalSortDelegate

/// A protocol used internally to support sorting.
///
protocol InternalSortDelegate: class {

    /// When a `TabularViewSortSupportingCell` is configured, it asks its
    /// sort delegate (the tabular view it belongs to) for its (the cell's)
    /// column's current sort state (`.sortedAscending`, `.sortedDescending`,
    /// or `.unknown`) by invoking this function on the sort delegate.
    ///
    func sortState <ColId: ColumnIdType> (for columnId: ColId) -> SortState

    /// When a subclass of `TabularViewSortSupportingCell` wants to have its
    /// column sorted, it invokes `requestSort()` on itself. Its implementation
    /// (provided by `TabularViewSortSupportingCell` itself), in turn, invokes
    /// this function on the cell's sort delegate (the tabular view it belongs to),
    /// which then knows how to forward the request to *its* sort delegate
    /// (typically a view controller), which then performs the sort action. This
    /// delegation chain allows for loose coupling.
    ///
    func sortRequested <ColId: ColumnIdType> (for columnId: ColId)

}
