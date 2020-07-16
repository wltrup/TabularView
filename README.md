# TabularView
![](https://img.shields.io/badge/platforms-iOS/iPadOS%2013%20-red)
[![Xcode](https://img.shields.io/badge/Xcode-11-blueviolet.svg)](https://developer.apple.com/xcode)
[![Swift](https://img.shields.io/badge/Swift-5.2-orange.svg)](https://swift.org)
![GitHub tag (latest SemVer)](https://img.shields.io/github/v/tag/wltrup/TabularView)
![GitHub](https://img.shields.io/github/license/wltrup/TabularView/LICENSE)

## What

**TabularView** is a Swift package for iOS/iPadOS (13.0 and above) to display tabular data in a view, in a manner similar to how `UICollectionView` can display unidimensional data in a grid.

The package supports multiple columns, each with their own optional header and optional footer, indexed by an enumeration type, that *you* define, rather than an integer, so your code is clearer about which column or columns it refers to. There's also built-in support for sorting rows by a selected column.

The design philosophy is inspired heavily by how `UICollectionView` works. There are separate data source and delegate protocols (in fact, *two* delegate protocols, one for layout and another for sorting), and the data source is managed using the new (as of 2019) `UICollectionView` [*Diffable Data Source*](https://developer.apple.com/documentation/uikit/uicollectionviewdiffabledatasource) API.

However, one feature that I could not figure out a way to implement, using the APIs out of the box, is *pinned* headers and footers. You see, in this first release of [*Compositional Layout*](https://developer.apple.com/documentation/uikit/uicollectionviewcompositionallayout), headers and footers (collectively known as *boundary supplementary items*) can only be added to *sections* and, additionally, sections aren't composable: you can have groups of items which themselves can be groups but you can't have sections containing other sections.

Therefore, the only way to have per-column headers and footers in a multi-column situation is to have a *header row* and a *footer row*, where a *row* is a group of items. But that means those headers and footers can't be pinned, unless I implemented my own collection view layout subclass, which I wasn't prepared to do at this time.

It also means that each item in a header or footer will be treated just like any other item. As far as the collection view is concerned, there are no headers or footers at all, but only regular cell items. This is why I didn't bother to differentiate between `UICollectionViewCell` and `UICollectionReusableView`. In `TabularView`, data cells, header cells, and footer cells are all instances of `UICollectionViewCell`, though they can be instances of *different* subclasses of `UICollectionViewCell` so that header and footer cells can look and behave differently from data item cells.

But if header and footer cells are just regular cell items, does the data source have to jump through extra hoops to account for them? No. `TabularView` internally adds an extra row of "data items" for a header and another for a footer, if the client code wants to have a header or footer. As far as the data source is concerned, the number of rows *is* what it is expected to be.

And speaking of sections, the current version of `TabularVIew` only supports a single section. It's not too difficult to add support for multiple sections and I'll get to it soon, so stay tuned.

## Demo app

I have a related GitHub project for a [demo app](https://github.com/wltrup/TabularViewDemo) showing how to use this package.

There are some video screen captures illustrating

- [how to show and hide headers and footers](https://github.com/wltrup/TabularViewDemo/blob/master/TabularView_hiding_HFs.mov)
- [how to change the gap between columns](https://github.com/wltrup/TabularViewDemo/blob/master/TabularView_inter_cols_gap.mov)
- [how to change individual column widths](https://github.com/wltrup/TabularViewDemo/blob/master/TabularView_col_widths.mov)
- [how to sort data by selecting a column](https://github.com/wltrup/TabularViewDemo/blob/master/TabularView_sorting.mov)
- [scrolling performance](https://github.com/wltrup/TabularViewDemo/blob/master/TabularView_scrolling_perf.mov)

but they're too large to display inline, so here's a screenshot of the demo app instead:

<p align="center">
<img src="/TabularView.png" alt="A screen shot of the demo app for the TabularView package" width="417">
</p>


## Installation

**TabularView** is provided only as a Swift Package Manager package, because I'm moving away from CocoaPods and Carthage, and can be easily installed directly from Xcode.

## Change-log

A [list of changes](./CHANGELOG.md) is available.

## Author

Wagner Truppel, trupwl@gmail.com

## License

**TabularView** is available under the MIT license. See the [LICENSE](./LICENSE) file for more info.
