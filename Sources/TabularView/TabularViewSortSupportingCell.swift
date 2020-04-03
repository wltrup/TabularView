import UIKit

/// Subclass this class to provide cells capable of requesting their
/// columns to be sorted. These sort-supporting cells are typically
/// header cells, not regular cells or footer cells, but there's nothing
/// preventing these other cells from supporting sorting as well.
///
open class TabularViewSortSupportingCell <ColId: ColumnIdType> : TabularViewCell {

    public private(set) var columnId: ColId?
    public private(set) var sortState: SortState = .unknown

    /// Subclasses *must* call `super.configure(cellKind: rowIndex: columnId: data:)`
    /// (ie, this implementation) somewhere in their implementation of their own version
    /// of this method. They can also use their implementation of this method to update
    /// the cell's appearance based on its sort state.
    ///
    override open func configure <CId: ColumnIdType>
        (cellKind: CellKind, rowIndex: RowIndex, columnId: CId, data: Any?) {
        self.columnId = columnId as? ColId
        self.sortState = internalSortDelegate?.sortState(for: columnId) ?? .unknown
    }

    /// Subclasses invoke this method to request a sort action to be performed on the
    /// current column. There's no need to maintain any sorting state in a subclass,
    /// since this class takes care of it.
    ///
    public func requestSort() {
        guard let columnId = self.columnId else { return }
        internalSortDelegate?.sortRequested(for: columnId)
    }

    /// A delegate used internally to support sorting.
    ///
    internal weak var internalSortDelegate: InternalSortDelegate?

}
