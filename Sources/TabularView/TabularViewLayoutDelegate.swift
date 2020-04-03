import UIKit

/// A protocol defining delegate methods to control a tabular view's layout.
///
public protocol TabularViewLayoutDelegate: class {

    /// Returns the dimensional width of a particular column. This function is
    /// only invoked when the tabular view's `columnWidthsSizingMode` property
    /// has the value `.customWidths`, and is invoked for *every* column.
    ///
    func tabularViewColumnWidthDimension <RowData: RowDataType, CId: ColumnIdType> (
        _ tabularView: TabularView<RowData, CId>,
        columnId: CId
    ) -> NSCollectionLayoutDimension

}
