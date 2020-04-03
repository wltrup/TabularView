import UIKit

// MARK: - TabularViewCell

/// Subclass this class to provide cells for the tabular view.
/// Note that, unlike in a typical collection view, header and footer
/// cells in a tabular view are *also* `UICollectionViewCell` instances.
///
open class TabularViewCell: UICollectionViewCell {

    public static let baseReuseIdentifier = "TabularViewCell"

    /// Subclasses must override this method, and should *not* invoke
    /// its `super` implementation, as the default implementation causes
    /// a fatal error.
    ///
    open func configure <CId: ColumnIdType> (
        cellKind: CellKind, rowIndex: RowIndex, columnId: CId, data: Any?) {
        fatalError("This method must be implemented in a subclass")
    }

    /// Subclasses must override this method, and should *not* invoke
    /// its `super` implementation, as the default implementation causes
    /// a fatal error.
    ///
    open func widthOfRenderedContent <CId: ColumnIdType> (
        cellKind: CellKind, rowIndex: RowIndex, columnId: CId, data: Any?) -> CGFloat {
        fatalError("This method must be implemented in a subclass")
    }

}
