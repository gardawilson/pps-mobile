import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';

class AppSearchDropdown<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final String Function(T)? itemAsString;
  final bool enabled;
  final bool showSearchBox;
  final String? searchHint;
  final bool isExpanded;

  // ⬇️ tambahkan ini
  final bool Function(T, T)? compareFn;
  final bool Function(T, String)? filterFn;

  const AppSearchDropdown({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.itemAsString,
    this.hint,
    this.enabled = true,
    this.showSearchBox = true,
    this.searchHint = 'Cari...',
    this.isExpanded = true,
    // ⬇️ baru
    this.compareFn,
    this.filterFn,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IgnorePointer(
      ignoring: !enabled,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? Colors.grey.shade400 : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),

        child: DropdownSearch<T>(
          items: items,
          selectedItem: value,
          enabled: enabled,

          // ⬇️ forward props baru
          compareFn: compareFn,
          filterFn: filterFn,

          itemAsString: itemAsString,

          dropdownButtonProps: const DropdownButtonProps(
            icon: Icon(Icons.arrow_drop_down, color: Colors.grey),
            alignment: Alignment.center,
          ),

          dropdownBuilder: (context, selectedItem) {
            final displayText = selectedItem == null
                ? (hint ?? 'Pilih item')
                : (itemAsString?.call(selectedItem) ?? selectedItem.toString());

            return Center(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  displayText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: selectedItem == null
                        ? Colors.grey.shade600
                        : Colors.black87,
                    height: 1.2,
                  ),
                ),
              ),
            );
          },

          popupProps: PopupProps.menu(
            fit: FlexFit.loose,
            showSearchBox: showSearchBox,
            searchDelay: Duration.zero, // responsif saat mengetik
            constraints: const BoxConstraints(maxHeight: 500),
            menuProps: MenuProps(
              backgroundColor: Colors.white,
              elevation: 3,
              borderRadius: BorderRadius.circular(8),
            ),
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: searchHint,
                prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                isDense: true,
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade400, width: 1.2),
                ),
              ),
            ),
          ),

          dropdownDecoratorProps: const DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
