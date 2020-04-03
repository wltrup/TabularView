import UIKit

/// A protocol defining delegate methods to control a tabular view's data source.
///
public protocol TabularViewDataSource: class {

    /// Returns an array of row identifiers. Each row of data has its
    /// own unique and stable *row identifier*, of type `RowId`. `RowId`
    /// is actually just an `Int` and that's needed because supporting
    /// headers and footers requires the ability to add and subtract
    /// integers from a row identifier.
    ///
    func tabularViewRowIds <RowData: RowDataType, CId: ColumnIdType> (
        _ tabularView: TabularView<RowData, CId>
    ) -> [RowId]

    /// Returns a subclass of `TabularViewCell`. The implementation
    /// should attempt to dequeue a cell, using the tabular view's
    /// `dequeueReusableCell(baseReuseIdentifier: cellKind: columnId: indexPath:)`
    /// method. Note that this is also invoked for header and footer cells,
    /// since they are all "cells". There's no need to verify that the
    /// `indexpath` argument is compatible with the `rowIndex` and `columnId`
    /// arguments. They've already been guaranteed to be compatible by the
    /// time this function is invoked on the delegate. The full collection
    /// of arguments is passed to the delegate simply for convenience, so
    /// the delegate doesn't need to compute an index path from the row index
    /// and column identifier.
    ///
    func tabularViewCell <RowData: RowDataType, CId: ColumnIdType> (
        _ tabularView: TabularView<RowData, CId>,
        cellKind: CellKind,
        rowIndex: RowIndex,
        columnId: CId,
        indexPath: IndexPath
    ) -> TabularViewCell

    /// Returns the data needed to configure a cell, header, or footer.
    ///
    func tabularViewDataForCell <RowData: RowDataType, CId: ColumnIdType> (
        _ tabularView: TabularView<RowData, CId>,
        cellKind: CellKind,
        rowIndex: RowIndex,
        columnId: CId
    ) -> Any?

}
