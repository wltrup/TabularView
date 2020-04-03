import UIKit

// MARK: - ItemId

/// The type for unique and stable *item* identifiers. Items are the contents of
/// individual cells in a tabular view, and each one has a unique and stable
/// identifier, regardless of the cell in which it is displayed at a given time.
///
public typealias ItemId = Int

// MARK: - RowId

/// The type for unique and stable *row* identifiers. A row is a collection
/// of data, organised in *columns*. Each row has its own unique and stable
/// identifier, which is semantically distinct from a row index. A row index
/// is the index of a particular cell in a tabular view. A row identifier is
/// the identifier of a particular row content, which can be displayed in a
/// different collection of row cells at different times. Same row identifier,
/// different row indices at different times.
///
public typealias RowId = Int

// MARK: - RowIndex

/// A row index is the index of a particular cell in a tabular view, and is
/// semantically distinct from a row identifier. See above for a detailed
/// explanation of the distinction.
///
public typealias RowIndex = Int

// MARK: - RowDataType

/// The type of the data displayed in a single row of a tabular view,
/// containing different fields for different columns.
///
public protocol RowDataType: Identifiable, Hashable where ID == RowId {}

// MARK: - Hashable conformance

extension RowDataType {

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

}

// MARK: - ItemViewKind

/// A type to enumerate the different kinds of cells. Header and footer
/// cells, in a tabular view, are not necessarily distinct from a regular
/// cell.
///
public enum CellKind {
    case cell
    case header
    case footer
}

// MARK: - ColumnIdType

/// A type to represent column identifiers.
///
public protocol ColumnIdType: RawRepresentable, Hashable, CaseIterable
where RawValue == Int {}

// MARK: - ColumnWidthsSizingMode

/// A type to enumerate the different strategies available for determining
/// column widths.
///
public enum ColumnWidthsSizingMode: Int {

    /// The package automatically sizes columns so that they
    /// all have the same width.
    ///
    case equalWidths

    /// The client code determines the width of each column,
    /// as a fraction of the tabular view's width, through the
    /// tabular view's layout delegate.
    ///
    case customWidths

    /// The package automatically sizes columns so that each
    /// column is wide enough (or wider) to fit the widest
    /// content among the *currently visible* rows of data,
    /// if possible. If that's not possible, then the columns
    /// are given equal widths. This mode requires a full pass
    /// over only the data that is currently visible.
    ///
    case autoSizedToFitVisibleContent

    /// The package automatically sizes columns so that each
    /// column is wide enough (or wider) to fit the widest
    /// content among *all* rows of data, if possible. If
    /// that's not possible, then the columns are given equal
    /// widths. This mode requires a full pass over *all* data,
    /// currently visible or not, and may take a considerable
    /// amount of time to complete, for large data sets.
    ///
    case autoSizedToFitAllContent

}
