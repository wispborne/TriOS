import 'package:flutter/material.dart';
import 'package:trios/thirdparty/flutter_tags/tags.dart';

/// Used by [ItemTags.onPressed].
typedef OnPressedCallback = void Function(Item i);

/// Used by [ItemTags.OnLongPressed].
typedef OnLongPressedCallback = void Function(Item i);

/// Used by [ItemTags.removeButton.onRemoved].
typedef OnRemovedCallback = bool Function();

/// combines icon text or image
enum ItemTagsCombine {
  onlyText,
  onlyIcon,
  onlyImage,
  imageOrIconOrText,
  withTextBefore,
  withTextAfter,
}

class ItemTags extends StatefulWidget {
  const ItemTags({
    required this.index,
    required this.title,
    this.textScaleFactor,
    this.active = true,
    this.pressEnabled = true,
    this.customData,
    this.textStyle = const TextStyle(fontSize: 14),
    this.alignment = MainAxisAlignment.center,
    this.combine = ItemTagsCombine.imageOrIconOrText,
    this.icon,
    this.image,
    this.removeButton,
    this.borderRadius,
    this.border,
    this.padding = const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
    this.elevation = 5,
    this.singleItem = false,
    this.textOverflow = TextOverflow.fade,
    this.textColor = Colors.black,
    this.textActiveColor = Colors.white,
    this.color = Colors.white,
    this.activeColor = Colors.blueGrey,
    this.highlightColor,
    this.splashColor,
    this.colorShowDuplicate = Colors.red,
    this.mouseCursor = SystemMouseCursors.basic,
    this.onPressed,
    this.onLongPressed,
    super.key,
  });

  /// Id of [ItemTags] - required
  final int index;

  /// Title of [ItemTags] - required
  final String title;

  /// Scale Factor of [ItemTags] - double
  final double? textScaleFactor;

  /// Initial bool value
  final bool active;

  /// Initial bool value
  final bool pressEnabled;

  /// Possibility to add any custom value in customData field, you can retrieve this later. A good example: store an id from Firestore document.
  final dynamic customData;

  /// ItemTagsCombine (text,icon,textIcon,textImage) of [ItemTags]
  final ItemTagsCombine combine;

  /// Icon of [ItemTags]
  final ItemTagsIcon? icon;

  /// Image of [ItemTags]
  final ItemTagsImage? image;

  /// Custom Remove Button of [ItemTags]
  final ItemTagsRemoveButton? removeButton;

  /// TextStyle of the [ItemTags]
  final TextStyle textStyle;

  /// TextStyle of the [ItemTags]
  final MainAxisAlignment alignment;

  /// border-radius of [ItemTags]
  final BorderRadius? borderRadius;

  /// custom border-side of [ItemTags]
  final BoxBorder? border;

  /// padding of the [ItemTags]
  final EdgeInsets padding;

  /// BoxShadow of the [ItemTags]
  final double elevation;

  /// when you want only one tag selected. same radio-button
  final bool singleItem;

  /// type of text overflow within the [ItemTags]
  final TextOverflow textOverflow;

  /// text color of the [ItemTags]
  final Color textColor;

  /// color of the [ItemTags] text activated
  final Color textActiveColor;

  /// background color [ItemTags]
  final Color color;

  /// background color [ItemTags] activated
  final Color activeColor;

  /// highlight Color [ItemTags]
  final Color? highlightColor;

  /// Splash color [ItemTags]
  final Color? splashColor;

  /// Color show duplicate [ItemTags]
  final Color colorShowDuplicate;

  /// mouse cursor of the [ItemTags]
  final MouseCursor? mouseCursor;

  /// callback
  final OnPressedCallback? onPressed;

  /// callback
  final OnLongPressedCallback? onLongPressed;

  @override
  State<ItemTags> createState() => _ItemTagsState();
}

class _ItemTagsState extends State<ItemTags> {
  final double _initBorderRadius = 50;

  DataListInherited? _dataListInherited;
  DataList? _dataList;

  void _setDataList() {
    // Get List<DataList> from Tags widget
    _dataListInherited = DataListInherited.of(context);
    final list = _dataListInherited!.list!;

    // Ensure there is a real DataList at widget.index (no null fillers)
    if (widget.index >= list.length) {
      // Insert a new entry at the end to reach this index
      list.add(
        DataList(
          title: widget.title,
          index: widget.index,
          active: widget.singleItem ? false : widget.active,
          customData: widget.customData,
        ),
      );
    } else {
      // Replace slot if it doesn't match the current widget
      if (list[widget.index].title != widget.title) {
        list[widget.index] = DataList(
          title: widget.title,
          index: widget.index,
          active: widget.singleItem ? false : widget.active,
          customData: widget.customData,
        );

        // If upstream removed elements and indices shifted, prune trailing items
        if (list.length > widget.index + 1) {
          list.removeRange(widget.index + 1, list.length);
        }
      }
    }

    // removes items that have been orphaned
    if (_dataListInherited!.itemCount == widget.index + 1 &&
        list.length > _dataListInherited!.itemCount!) {
      list.removeRange(widget.index + 1, list.length);
    }

    // update Listener
    if (_dataList != null) _dataList!.removeListener(_didValueChange);

    _dataList = list[widget.index];
    _dataList!.addListener(_didValueChange);
  }

  _didValueChange() => setState(() {});

  @override
  void dispose() {
    _dataList!.removeListener(_didValueChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _setDataList();

    final double fontSize = widget.textStyle.fontSize!;

    Color color = _dataList!.active ? widget.activeColor : widget.color;

    if (_dataList!.showDuplicate) color = widget.colorShowDuplicate;

    return Material(
      color: color,
      borderRadius:
          widget.borderRadius ?? BorderRadius.circular(_initBorderRadius),
      elevation: widget.elevation,
      //shadowColor: _dataList.highlights? Colors.red : Colors.blue,
      child: InkWell(
        mouseCursor: widget.mouseCursor,
        borderRadius:
            widget.borderRadius ?? BorderRadius.circular(_initBorderRadius),
        highlightColor: widget.pressEnabled
            ? widget.highlightColor
            : Colors.transparent,
        splashColor: widget.pressEnabled
            ? widget.splashColor
            : Colors.transparent,
        onTap: widget.pressEnabled
            ? () {
                if (widget.singleItem) {
                  _singleItem(_dataListInherited!, _dataList);
                  _dataList!.active = true;
                } else {
                  _dataList!.active = !_dataList!.active;
                }

                if (widget.onPressed != null) {
                  widget.onPressed!(
                    Item(
                      index: widget.index,
                      title: _dataList!.title,
                      active: _dataList!.active,
                      customData: widget.customData,
                    ),
                  );
                }
              }
            : null,
        onLongPress: widget.onLongPressed != null
            ? () => widget.onLongPressed!(
                Item(
                  index: widget.index,
                  title: _dataList!.title,
                  active: _dataList!.active,
                  customData: widget.customData,
                ),
              )
            : null,
        child: Container(
          decoration: BoxDecoration(
            border:
                widget.border ??
                Border.all(color: widget.activeColor, width: 0.5),
            borderRadius:
                widget.borderRadius ?? BorderRadius.circular(_initBorderRadius),
          ),
          padding: widget.padding * (fontSize / 14),
          child: _combine,
        ),
      ),
    );
  }

  Widget get _combine {
    if (widget.image != null) {
      assert(
        (widget.image!.image != null && widget.image!.child == null) ||
            (widget.image!.child != null && widget.image!.image == null),
      );
    }
    final Widget text = Text(
      widget.title,
      softWrap: false,
      textAlign: _textAlignment,
      overflow: widget.textOverflow,
      textScaler: TextScaler.linear(widget.textScaleFactor ?? 1),
      style: _textStyle,
    );
    final Widget icon = widget.icon != null
        ? Container(
            padding:
                widget.icon!.padding ??
                (widget.combine == ItemTagsCombine.onlyIcon ||
                        widget.combine == ItemTagsCombine.imageOrIconOrText
                    ? null
                    : widget.combine == ItemTagsCombine.withTextAfter
                    ? EdgeInsets.only(right: 5)
                    : EdgeInsets.only(left: 5)),
            child: Icon(
              widget.icon!.icon,
              color: _textStyle.color,
              size: _textStyle.fontSize! * 1.2,
            ),
          )
        : text;
    final Widget image = widget.image != null
        ? Container(
            padding:
                widget.image!.padding ??
                (widget.combine == ItemTagsCombine.onlyImage ||
                        widget.combine == ItemTagsCombine.imageOrIconOrText
                    ? null
                    : widget.combine == ItemTagsCombine.withTextAfter
                    ? EdgeInsets.only(right: 5)
                    : EdgeInsets.only(left: 5)),
            child:
                widget.image!.child ??
                CircleAvatar(
                  radius:
                      widget.image!.radius * (widget.textStyle.fontSize! / 14),
                  backgroundColor: Colors.transparent,
                  backgroundImage: widget.image!.image,
                ),
          )
        : text;

    final List list = [];

    switch (widget.combine) {
      case ItemTagsCombine.onlyText:
        list.add(text);
        break;
      case ItemTagsCombine.onlyIcon:
        list.add(icon);
        break;
      case ItemTagsCombine.onlyImage:
        list.add(image);
        break;
      case ItemTagsCombine.imageOrIconOrText:
        list.add((image != text ? image : icon));
        break;
      case ItemTagsCombine.withTextBefore:
        list.add(text);
        if (image != text) {
          list.add(image);
        } else if (icon != text) {
          list.add(icon);
        }
        break;
      case ItemTagsCombine.withTextAfter:
        if (image != text) {
          list.add(image);
        } else if (icon != text) {
          list.add(icon);
        }
        list.add(text);
    }

    final Widget row = Row(
      mainAxisAlignment: widget.alignment,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(list.length, (i) {
        if (i == 0 && list.length > 1) {
          return Flexible(
            flex: widget.combine == ItemTagsCombine.withTextAfter ? 0 : 1,
            child: list[i],
          );
        }
        return Flexible(
          flex:
              widget.combine == ItemTagsCombine.withTextAfter ||
                  list.length == 1
              ? 1
              : 0,
          child: list[i],
        );
      }),
    );

    if (widget.removeButton != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Flexible(
            fit: _dataListInherited!.symmetry! ? FlexFit.tight : FlexFit.loose,
            flex: 2,
            child: row,
          ),
          Flexible(
            flex: 0,
            child: FittedBox(
              alignment: Alignment.centerRight,
              fit: BoxFit.fill,
              child: GestureDetector(
                child: Container(
                  margin:
                      widget.removeButton!.margin ?? EdgeInsets.only(left: 5),
                  padding:
                      (widget.removeButton!.padding ?? EdgeInsets.all(2)) *
                      (widget.textStyle.fontSize! / 14),
                  decoration: BoxDecoration(
                    color: widget.removeButton!.backgroundColor ?? Colors.black,
                    borderRadius:
                        widget.removeButton!.borderRadius ??
                        BorderRadius.circular(_initBorderRadius),
                  ),
                  child:
                      widget.removeButton!.padding as Widget? ??
                      Icon(
                        Icons.clear,
                        color: widget.removeButton!.color ?? Colors.white,
                        size:
                            (widget.removeButton!.size ?? 12) *
                            (widget.textStyle.fontSize! / 14),
                      ),
                ),
                onTap: () {
                  if (widget.removeButton!.onRemoved != null) {
                    if (widget.removeButton!.onRemoved!()) {
                      _dataListInherited!.list!.removeAt(widget.index);
                    }
                  }
                },
              ),
            ),
          ),
        ],
      );
    }

    return row;
  }

  ///Text Alignment
  TextAlign? get _textAlignment {
    switch (widget.alignment) {
      case MainAxisAlignment.spaceBetween:
      case MainAxisAlignment.start:
        return TextAlign.start;
      case MainAxisAlignment.end:
        return TextAlign.end;
      case MainAxisAlignment.spaceAround:
      case MainAxisAlignment.spaceEvenly:
      case MainAxisAlignment.center:
        return TextAlign.center;
    }
  }

  ///TextStyle
  TextStyle get _textStyle {
    return widget.textStyle.apply(
      color: _dataList!.active ? widget.textActiveColor : widget.textColor,
    );
  }

  /// Single item selection
  void _singleItem(DataListInherited dataSetIn, DataList? dataSet) {
    dataSetIn.list!
        .whereType<DataList>()
        .where((tg) => tg.active)
        .where((tg2) => tg2 != dataSet)
        .forEach((tg) => tg.active = false);
  }
}

///callback
class Item {
  Item({this.index, this.title, this.active, this.customData});

  final int? index;
  final String? title;
  final bool? active;
  final dynamic customData;

  @override
  String toString() {
    return "id:$index, title: $title, active: $active, customData: $customData";
  }
}

/// ItemTag Image
class ItemTagsImage {
  ItemTagsImage({this.radius = 8, this.padding, this.image, this.child});

  final double radius;
  final EdgeInsets? padding;
  final ImageProvider? image;
  final Widget? child;
}

/// ItemTag Icon
class ItemTagsIcon {
  ItemTagsIcon({this.padding, required this.icon});

  final EdgeInsets? padding;
  final IconData icon;
}

/// ItemTag RemoveButton
class ItemTagsRemoveButton {
  ItemTagsRemoveButton({
    this.icon,
    this.size,
    this.backgroundColor,
    this.color,
    this.borderRadius,
    this.padding,
    this.margin,
    this.onRemoved,
  });

  final IconData? icon;
  final double? size;
  final Color? backgroundColor;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  /// callback
  final OnRemovedCallback? onRemoved;
}
