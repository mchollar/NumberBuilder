import SwiftUI
import UIKit

/// A `UIPickerView` wrapper standing in for SwiftUI's `.pickerStyle(.wheel)`.
///
/// SwiftUI's built-in wheel picker doesn't expose row height, so oversized row content just
/// overflows into neighboring rows instead of the row growing to fit it. Wrapping `UIPickerView`
/// directly gives us `pickerView(_:rowHeightForComponent:)`, so dice can be drawn at whatever
/// size we want with no overlap — same native scroll physics and fade/perspective look, just
/// sized to fit.
struct DiceWheelPicker: UIViewRepresentable {
    @Binding var selection: Int
    var colorScheme: DiceColorScheme = .primary
    var style: DiceRenderStyle = .filledColoredBackground
    /// Which of the three tray positions this is, 0-based -- forwarded to `DiceFaceView` for
    /// `.operatorColors`, which rotates by position. Fixed for the lifetime of one picker
    /// instance (each tray slot gets its own `DiceWheelPicker`), so it's not part of the
    /// appearance-change cache invalidation in `updateUIView`.
    var index: Int = 0
    var rowHeight: CGFloat = 64
    var imageSize: CGFloat = 52
    var columnWidth: CGFloat = 112
    var visibleRows: Int = 3

    private var totalHeight: CGFloat { rowHeight * CGFloat(visibleRows) }

    func makeUIView(context: Context) -> UIPickerView {
        let picker = UIPickerView()
        picker.dataSource = context.coordinator
        picker.delegate = context.coordinator
        picker.selectRow(selection - 1, inComponent: 0, animated: false)
        return picker
    }

    /// Without this, SwiftUI falls back to `UIPickerView`'s own intrinsic/default size (320x216)
    /// for both HStack layout math and the view's real frame -- multiple pickers side by side
    /// then have massively overlapping *real* (hit-testable) bounds despite each rendering
    /// cleanly clipped to its own small visual slot, so touches on one picker can be routed to
    /// a neighbor depending on view stacking order. This is the sanctioned way to tell SwiftUI a
    /// `UIViewRepresentable`'s actual size.
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIPickerView, context: Context) -> CGSize? {
        CGSize(width: columnWidth, height: totalHeight)
    }

    func updateUIView(_ picker: UIPickerView, context: Context) {
        let appearanceChanged = context.coordinator.parent.colorScheme != colorScheme
            || context.coordinator.parent.style != style
        context.coordinator.parent = self
        if appearanceChanged {
            context.coordinator.imageCache.removeAll()
            picker.reloadAllComponents()
        }
        let targetRow = selection - 1
        if picker.selectedRow(inComponent: 0) != targetRow {
            picker.selectRow(targetRow, inComponent: 0, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        var parent: DiceWheelPicker
        /// Rendering `DiceFaceView` to a `UIImage` via `ImageRenderer` isn't free -- cache by die
        /// value (1...6) so scrolling/row-reuse doesn't re-render the same face repeatedly.
        /// Cleared in `updateUIView` whenever `colorScheme`/`style` actually change.
        var imageCache: [Int: UIImage] = [:]

        init(_ parent: DiceWheelPicker) {
            self.parent = parent
        }

        private func image(forValue value: Int) -> UIImage {
            if let cached = imageCache[value] { return cached }
            let renderer = ImageRenderer(content:
                DiceFaceView(value: value, colorScheme: parent.colorScheme, style: parent.style, index: parent.index, tier: nil)
                    .frame(width: parent.imageSize, height: parent.imageSize)
            )
            renderer.scale = UIScreen.main.scale
            let image = renderer.uiImage ?? UIImage()
            imageCache[value] = image
            return image
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { 6 }

        func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
            parent.rowHeight
        }

        func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
            parent.columnWidth
        }

        func pickerView(
            _ pickerView: UIPickerView,
            viewForRow row: Int,
            forComponent component: Int,
            reusing view: UIView?
        ) -> UIView {
            let container: UIView
            let imageView: UIImageView
            if let reused = view, let reusedImageView = reused.subviews.first as? UIImageView {
                container = reused
                imageView = reusedImageView
            } else {
                container = UIView()
                imageView = UIImageView()
                imageView.contentMode = .scaleAspectFit
                imageView.translatesAutoresizingMaskIntoConstraints = false
                container.addSubview(imageView)
                NSLayoutConstraint.activate([
                    imageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                    imageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                    imageView.widthAnchor.constraint(equalToConstant: parent.imageSize),
                    imageView.heightAnchor.constraint(equalToConstant: parent.imageSize)
                ])
            }
            imageView.image = image(forValue: row + 1)
            return container
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            parent.selection = row + 1
        }
    }
}
