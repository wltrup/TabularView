import UIKit

/// A class to display data in a tabular fashion, like good ol' spreadsheets,
/// with built-in support for displaying headers and/or footers, as well as
/// sorting columns.
///
/// The generic `RowData` type represents the type of the data that appears
/// in a single row of the tabular view, and must conform to the `RowDataType`
/// protocol.
///
/// The generic `CId` type represents a *column identifier*, and must conform
/// to the `ColumnIdType` protocol.
///
/// A tabular view uses one data source and two delegates, one for its layout
/// and the other to support column-sorting. In order to support sorting, at
/// least one cell in a column that can be sorted should be defined by a
/// subclass of `TabularViewSortSupportingCell`.
///
open class TabularView <RowData: RowDataType, CId: ColumnIdType> : UIView {

    public var dataSource: TabularViewDataSource? { didSet { dataSourceChanged() } }
    public var layoutDelegate: TabularViewLayoutDelegate? { didSet { layoutDelegateChanged() } }
    public var sortDelegate: TabularViewSortDelegate?

    /// Whether or not the tabular view should support *headers*. Changes
    /// to the value of this property do *not* take effect immediately but,
    /// rather, are scheduled to take effect in the next available run of
    /// the main run-loop. The default value is `false`, that is, headers
    /// are not available. Note that setting this property to `true` will
    /// cause `TabularView` to attempt to dequeue header cells, so make sure
    /// to register a header cell class for them.
    ///
    public var hasHeaders: Bool = false {
        didSet { setNeedsDataReload() }
    }

    /// Whether or not header cells are hidden. Changes to the value of this
    /// property do *not* take effect immediately but, rather, are scheduled
    /// to take effect in the next available run of the main run-loop. The
    /// default value is `false`, that is, headers are visible, if existing.
    ///
    public var headersAreHidden: Bool = false {
        didSet { setNeedsDataReload() }
    }

    /// Whether or not the tabular view should support *footers*. Changes
    /// to the value of this property do *not* take effect immediately but,
    /// rather, are scheduled to take effect in the next available run of
    /// the main run-loop. The default value is `false`, that is, footers
    /// are not available. Note that setting this property to `true` will
    /// cause `TabularView` to attempt to dequeue footer cells, so make sure
    /// to register a footer cell class for them.
    ///
    public var hasFooters: Bool = false {
        didSet { setNeedsDataReload() }
    }

    /// Whether or not footer cells are hidden. Changes to the value of this
    /// property do *not* take effect immediately but, rather, are scheduled
    /// to take effect in the next available run of the main run-loop. The
    /// default value is `false`, that is, footers are visible, if existing.
    ///
    public var footersAreHidden: Bool = false {
        didSet { setNeedsDataReload() }
    }

    /// The strategy to use for determining column widths. Changes to the
    /// value of this property do *not* take effect immediately but, rather,
    /// are scheduled to take effect in the next available run of the main
    /// run-loop. The default value is `.equalWidths`.
    ///
    public var columnWidthsSizingMode: ColumnWidthsSizingMode = .equalWidths {
        didSet { setNeedsLayoutUpdate() }
    }

    /// The horizontal gap, in `points`, between adjacent columns. Changes to
    /// the value of this property do *not* take effect immediately but, rather,
    /// are scheduled to take effect in the next available run of the main
    /// run-loop. The default value is `0`.
    ///
    public var interColumnGap: CGFloat = 0 {
        didSet { setNeedsLayoutUpdate() }
    }

    /// A dictionary mapping column identifiers to the sort state of their
    /// corresponding columns of data. This is entirely maintained by the
    /// tabular view but is publicly readable.
    ///
    public private(set) var sortStates: [CId: SortState] = [:]

    /// `TabularView`'s designated initialiser.
    ///
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private var collectionViewDataSource: UICollectionViewDiffableDataSource<RowId, ItemId>!
    private var collectionView: UICollectionView!

    private var countOfReloadRequests = 0
    private var countOfLayoutUpdateRequests = 0

}

extension TabularView {

    /// Schedules a data reload for the next available pass of the main run-loop.
    /// Essentially, this allows coalescing of many data reload requests so that
    /// only one request is fullfilled, at the end of a sequence. This method is
    /// thread-safe, so it can be invoked from any thread.
    ///
    public func setNeedsDataReload(animatingDifferences: Bool = true) {

        if Thread.isMainThread == false {
            DispatchQueue.main.async { [weak self] in self?.setNeedsDataReload() }
            return
        }

        countOfReloadRequests += 1
        DispatchQueue.main.async { [weak self] in
            self?.reloadData(animatingDifferences: animatingDifferences)
        }

    }

    /// This method can be invoked to force an immediate data reload, optionally
    /// in an animating fashion. The default is to reload the data *with* animation.
    ///
    public func reloadDataNow(animatingDifferences: Bool = true) {

        let rowIds = dataSource?.tabularViewRowIds(self) ?? []
        var customRowIds: [RowId] = []

        if hasVisibleHeaders {
            let minRowId = rowIds.min() ?? 0
            let headerRowId = minRowId - 1
            customRowIds += [headerRowId]
        }
        customRowIds += rowIds
        if hasVisibleFooters {
            let maxRowId = rowIds.max() ?? 0
            let footerRowId = maxRowId + 1
            customRowIds += [footerRowId]
        }

        let numCols = CId.allCases.count
        var snapshot = NSDiffableDataSourceSnapshot<RowId, ItemId>()
        for rowId in customRowIds {
            snapshot.appendSections([rowId])
            snapshot.appendItems(
                CId.allCases.map { numCols * rowId + $0.rawValue }
            )
        }

        collectionViewDataSource?.apply(
            snapshot, animatingDifferences: animatingDifferences)

    }

    /// Schedules a layout update for the next available pass of the main run-loop.
    /// Essentially, this allows coalescing of many layout update requests so that
    /// only one request is fullfilled, at the end of a sequence. This method is
    /// thread-safe, so it can be invoked from any thread.
    ///
    public func setNeedsLayoutUpdate() {

        if Thread.isMainThread == false {
            DispatchQueue.main.async { [weak self] in self?.setNeedsLayoutUpdate() }
            return
        }

        countOfLayoutUpdateRequests += 1
        DispatchQueue.main.async { [weak self] in self?.updateLayout() }

    }

    /// This method can be invoked to force an immediate layout update.
    ///
    public func updateLayoutNow() {
        layoutDelegateChanged()
    }

}

extension TabularView {

    /// Use this method to register the class of a reusable cell, for a
    /// particular base reuse identifier, cell kind, and tabular view column.
    /// The actual reuse identifier is built from the base identifier by
    /// combining it with the cell kind and column identifier. That way, a
    /// single class can provide variations that depend on the cell kind
    /// and the cell's column, if needed. If all columns should share the
    /// same cell class, then pass `nil` to the `columnId` parameter.
    /// Likewise, if all cell kinds should share the same cell class, pass
    /// `nil` to the `cellKind` parameter. A cell class that is reused by
    /// *all* cells in the tabular view is, therefore, registered by invoking
    /// this function with `nil` passed for both parameters. Its reuse identifier
    /// is then just the base identifier passed in.
    ///
    public func register(
        cellClass: AnyClass?,
        baseReuseIdentifier: String,
        cellKind: CellKind?,
        columnId: CId?
    ) {

        let reuseId = reuseIdentifier(
            baseReuseIdentifier: baseReuseIdentifier,
            cellKind: cellKind,
            columnId: columnId
        )
        collectionView.register(cellClass, forCellWithReuseIdentifier: reuseId)

    }

    /// Use this method to dequeue a reusable cell, for a particular position in
    /// the tabular view. See `register(cellClass: baseReuseIdentifier: cellKind: columnId:)`
    /// for details on the meaning and use of `baseReuseIdentifier`.
    ///
    public func dequeueReusableCell(
        baseReuseIdentifier: String,
        cellKind: CellKind?,
        columnId: CId?,
        indexPath: IndexPath
    ) -> TabularViewCell? {

        let reuseId = reuseIdentifier(
            baseReuseIdentifier: baseReuseIdentifier,
            cellKind: cellKind,
            columnId: columnId
        )
        return collectionView.dequeueReusableCell(
            withReuseIdentifier: reuseId, for: indexPath) as? TabularViewCell

    }

}

// MARK: - Internal API

extension TabularView: InternalSortDelegate {

    func sortState<ColId>(for columnId: ColId) -> SortState where ColId : ColumnIdType {
        guard let columnId = columnId as? CId else { return .unknown }
        return sortStates[columnId] ?? .unknown
    }

    func sortRequested <ColId: ColumnIdType> (for columnId: ColId) {

        guard
            let sortDelegate = sortDelegate,
            let columnId = columnId as? CId
            else { return }

        let sortState = sortStates[columnId] ?? .unknown
        CId.allCases.forEach { columnId in sortStates[columnId] = .unknown }

        let sortOrder: SortOrder
        switch sortState {
        case .sortedAscending:
            sortOrder = .descending
            sortStates[columnId] = .sortedDescending
        case .sortedDescending, .unknown:
            sortOrder = .ascending
            sortStates[columnId] = .sortedAscending
        }

        sortDelegate.sortRequested(for: columnId, sortOrder: sortOrder) {
            setNeedsDataReload(animatingDifferences: false)
        }

    }

}

// MARK: - Private API

private extension TabularView {

    func setup() {

        let layout = makeCollectionViewLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = self.backgroundColor

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: self.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])

    }

    func layoutDelegateChanged() {
        let layout = makeCollectionViewLayout()
        collectionView.collectionViewLayout = layout
    }

    func makeCollectionViewLayout() -> UICollectionViewLayout {

        let numberOfColumns = CId.allCases.count
        let cgfNumberOfColumns = CGFloat(numberOfColumns)

        let gwd = NSCollectionLayoutDimension.fractionalWidth(1.0)
        let ghd = NSCollectionLayoutDimension.estimated(44)
        let groupSize = NSCollectionLayoutSize(widthDimension: gwd, heightDimension: ghd)
        let group: NSCollectionLayoutGroup

        switch columnWidthsSizingMode {
        case .equalWidths:
            let iwd = NSCollectionLayoutDimension.fractionalWidth(1.0)
            let ihd = NSCollectionLayoutDimension.fractionalHeight(1.0)
            let itemSize = NSCollectionLayoutSize(widthDimension: iwd, heightDimension: ihd)
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitem: item,
                count: numberOfColumns
            )

        case .customWidths:
            var widthDimensions: [CId: NSCollectionLayoutDimension] = [:]
            for columnId in CId.allCases {
                widthDimensions[columnId] = layoutDelegate?
                    .tabularViewColumnWidthDimension(self, columnId: columnId)
                    ?? .fractionalWidth(1.0 / cgfNumberOfColumns)
            }
            let items = variableColumnWidthItems(widthDimensions: widthDimensions)
            group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: items)

        case .autoSizedToFitVisibleContent:
            let indexPaths = collectionView.indexPathsForVisibleItems
            let maxFractionalContentWidths = maximumFractionalContentWidths(for: indexPaths)
            let items = variableColumnWidthItems(widthDimensions: maxFractionalContentWidths)
            group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: items)

        case .autoSizedToFitAllContent:
            let numberOfRows = collectionView.numberOfSections // yes, rows *are* sections...
            let numberOfItems = numberOfRows * numberOfColumns
            var indexPaths: [IndexPath] = Array(
                repeating: IndexPath(item: 0, section: 0),
                count: numberOfItems
            )
            var index = 0
            for rowIndex in (0 ..< numberOfRows) {
                for columnId in CId.allCases {
                    indexPaths[index] = IndexPath(item: columnId.rawValue, section: rowIndex)
                    index += 1
                }
            }
            let maxFractionalContentWidths = maximumFractionalContentWidths(for: indexPaths)
            let items = variableColumnWidthItems(widthDimensions: maxFractionalContentWidths)
            group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: items)

        }

        group.interItemSpacing = .fixed(interColumnGap)

        let section = NSCollectionLayoutSection(group: group)
        return UICollectionViewCompositionalLayout(section: section)

    }

    func dataSourceChanged() {

        guard let dataSource = dataSource else {
            collectionViewDataSource = nil
            collectionView.dataSource = nil
            collectionView.reloadData()
            return
        }

        collectionViewDataSource = .init(collectionView: collectionView) {
            [weak self] collectionView, indexPath, itemId in

            guard let self = self else { return nil }

            let (cellKind, rowIndex, columnId) = self.cellKindRowIndexColumnId(for: indexPath)

            let cell = dataSource.tabularViewCell(
                self,
                cellKind: cellKind,
                rowIndex: rowIndex,
                columnId: columnId,
                indexPath: indexPath
            )

            if let sortCapableCell = cell as? TabularViewSortSupportingCell<CId> {
                sortCapableCell.internalSortDelegate = self
            }

            let data = dataSource.tabularViewDataForCell(
                self,
                cellKind: cellKind,
                rowIndex: (self.hasVisibleHeaders ? rowIndex - 1 : rowIndex),
                columnId: columnId
            )

            cell.configure(cellKind: cellKind, rowIndex: rowIndex, columnId: columnId, data: data)
            return cell

        }

        setNeedsDataReload()

    }

    var hasVisibleHeaders: Bool {
        hasHeaders && (headersAreHidden == false)
    }

    var hasVisibleFooters: Bool {
        hasFooters && (footersAreHidden == false)
    }

    func cellKindRowIndexColumnId(for indexPath: IndexPath) -> (CellKind, RowIndex, CId) {

        let rowIndex = indexPath.section // yes, each index path section is a row...
        // ... and each index path row is a column identifier
        guard let columnId = CId(rawValue: indexPath.row) else {
            fatalError(
                "indexPath.row (\(indexPath.row) is not a column identifier"
            )
        }

        let numberOfRows = collectionView.numberOfSections // yes, rows *are* sections...

        let isHeader = (hasVisibleHeaders && (rowIndex == 0))
        let isFooter = (hasVisibleFooters && (rowIndex == numberOfRows-1))
        let cellKind: CellKind = (isHeader ? .header : (isFooter ? .footer : .cell))

        return (cellKind, rowIndex, columnId)

    }

    func maximumFractionalContentWidths(
        for indexPaths: [IndexPath]
    ) -> [CId: NSCollectionLayoutDimension] {

        let numberOfColumns = CId.allCases.count
        let cgfNumberOfColumns = CGFloat(numberOfColumns)

        let hasVisibleHeaders = self.hasVisibleHeaders

        var maxContentWidths: [CId: CGFloat] = [:]
        for indexPath in indexPaths {
            let (cellKind, rowIndex, columnId) = cellKindRowIndexColumnId(for: indexPath)
            let actualRowIndex = (hasVisibleHeaders ? rowIndex - 1 : rowIndex)
            let data = dataSource?.tabularViewDataForCell(
                self,
                cellKind: cellKind,
                rowIndex: actualRowIndex,
                columnId: columnId
            ) ?? nil
            let cell = collectionView.cellForItem(at: indexPath) as? TabularViewCell
            let contentWidth = cell?.widthOfRenderedContent(
                cellKind: cellKind,
                rowIndex: actualRowIndex,
                columnId: columnId,
                data: data
            ) ?? (bounds.size.width / cgfNumberOfColumns)
            maxContentWidths[columnId] = max(contentWidth, maxContentWidths[columnId] ?? 0)
        }

        let totalMaxWidth = maxContentWidths.values.reduce(0, +)
        return maxContentWidths.mapValues { .fractionalWidth($0 / totalMaxWidth) }

    }

    func variableColumnWidthItems(
        widthDimensions: [CId: NSCollectionLayoutDimension]
    ) -> [NSCollectionLayoutItem] {

        let numberOfColumns = CId.allCases.count
        let cgfNumberOfColumns = CGFloat(numberOfColumns)

        var availableWidth = bounds.width - (cgfNumberOfColumns - 1) * interColumnGap
        let widthUsedByNonFractional = widthDimensions.values.map { iwd -> CGFloat in
            if iwd.isAbsolute || iwd.isEstimated {
                return iwd.dimension
            } else if iwd.isFractionalWidth {
                return 0
            } else {
                fatalError(".fractionalHeight is not supported by TabularView")
            }
        }.reduce(0, +)
        availableWidth -= widthUsedByNonFractional
        if availableWidth <= 0 {
            fatalError("Not enough available horizontal space")
        }

        let correctionFactor = availableWidth / bounds.width

        var items: [NSCollectionLayoutItem] = []
        for columnId in CId.allCases {
            let wd = widthDimensions[columnId] ?? .fractionalWidth(1.0 / cgfNumberOfColumns)
            let iwd: NSCollectionLayoutDimension
            if wd.isAbsolute || wd.isEstimated {
                iwd = wd
            } else if wd.isFractionalWidth {
                iwd = .fractionalWidth(wd.dimension * correctionFactor)
            } else {
                fatalError(".fractionalHeight is not supported by TabularView")
            }
            let ihd = NSCollectionLayoutDimension.fractionalHeight(1.0)
            let itemSize = NSCollectionLayoutSize(widthDimension: iwd, heightDimension: ihd)
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            items += [item]
        }

        return items

    }

    func reuseIdentifier(
        baseReuseIdentifier: String,
        cellKind: CellKind?,
        columnId: CId?
    ) -> String {

        let kindStr = (cellKind == nil ? "" : " \(cellKind!)")
        let columnIdStr = (columnId == nil ? "" : " c\(columnId!.rawValue)")
        let reuseId = baseReuseIdentifier + kindStr + columnIdStr

        return reuseId

    }

    func reloadData(animatingDifferences: Bool = true) {

        countOfReloadRequests -= 1
        guard countOfReloadRequests == 0 else { return }

        reloadDataNow(animatingDifferences: animatingDifferences)

    }

    func updateLayout() {

        countOfLayoutUpdateRequests -= 1
        guard countOfLayoutUpdateRequests == 0 else { return }

        updateLayoutNow()

    }

}
