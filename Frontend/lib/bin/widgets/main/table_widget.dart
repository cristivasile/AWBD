// ignore: file_names
import 'package:flutter/material.dart';
import 'package:restaurant_management_app/bin/constants.dart' as constants;
import 'package:restaurant_management_app/bin/services/order_service.dart';
import 'package:restaurant_management_app/bin/services/reservation_service.dart';

import '../../utilities/globals.dart';
import '../../services/table_service.dart';

/// Movable table object
///
class MovableTableWidget extends StatefulWidget {
  final BoxConstraints constraints; //widget constraints received as parameter
  final String imagePath; //the corresponding table's image path
  final int imageWidth; // width of the displayed image
  final int imageHeight; // height of the displayed image
  final int tableSize;
  final bool hasOrder; 
  final bool hasReservation;
  final String id;
  final int floor;
  final Offset
      position; // position relative to the top left corner of the container

  MovableTableWidget({
    Key? key,
    required this.constraints,
    required this.tableSize,
    required this.position,
    required this.id,
    required this.floor,
    required this.hasOrder,
    required this.hasReservation,
  })  : imagePath = getBaseImagePath(tableSize),
        imageWidth = getImageSize(tableSize)[0],
        imageHeight = getImageSize(tableSize)[1],
        super(key: key);

  @override
  State<MovableTableWidget> createState() => _MovableTableWidgetState();
}

class _MovableTableWidgetState extends State<MovableTableWidget> {
  late Offset _position;
  late double _scale;
  late int _gridStep;
  late bool _hasOrder = false;
  late bool _hasReservation = false;

  @override
  void initState() {
    super.initState();
    _position = widget.position;
    fetchOrder();
    fetchReservation();
  }

  void fetchReservation() async {
    try {
      var upcomingReservation = await ReservationService.getCurrentReservationByTableId(widget.id);
      //has a reservation in the next 3 hours
      setState(() {
        _hasReservation = upcomingReservation != null;
      });
    } on Exception {
      return;
    }
  }

  void fetchOrder() async {
    try {
      var order = await OrderService.getOrderByTableId(widget.id);
      setState(() {
        _hasOrder = order != null;
      });
    } on Exception {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    _scale = Globals.getGlobals().tableImagesScale;
    _gridStep = Globals.getGlobals().floorGridStep;
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: Draggable(
        // image displayed under the mouse while dragging
        feedback: Image(
            image: AssetImage(widget.imagePath + "_feedback" + ".png"),
            width: widget.imageWidth.toDouble() * _scale,
            height: widget.imageHeight.toDouble() * _scale),
        // image displayed normally
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Image(
              image: AssetImage(getImagePath()),
              width: widget.imageWidth.toDouble() * _scale,
              height: widget.imageHeight.toDouble() * _scale,
            ),
            Text(
              widget.id,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18 * _scale,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        //image displayed at the table position while moving it
        childWhenDragging: Image(
            image: AssetImage(getImagePath()),
            width: widget.imageWidth.toDouble() * _scale,
            height: widget.imageHeight.toDouble() * _scale),
        onDragEnd: (DraggableDetails details) {
          setState(() {
            final adjustmenty = MediaQuery.of(context).size.height -
                widget.constraints.maxHeight -
                constants.floorMargin;
            final adjustmentx = MediaQuery.of(context).size.width -
                widget.constraints.maxWidth -
                constants.floorMargin;
            // details.offset is relative to the window instead of the container
            // => without this the item would be placed too low because of the app bar
            // + margin of the container

            //check if the position is inside the container: right, left, top, bottom
            if (details.offset.dx + widget.imageWidth <
                    MediaQuery.of(context).size.width &&
                details.offset.dx > 0 + adjustmentx &&
                details.offset.dy > 0 + adjustmenty &&
                details.offset.dy + widget.imageHeight + constants.floorMargin <
                    MediaQuery.of(context).size.height) {
              double xOffset =
                  (details.offset.dx - adjustmentx).toInt() % _gridStep <
                          _gridStep / 2
                      ? ((details.offset.dx - adjustmentx) / _gridStep)
                              .truncateToDouble() *
                          _gridStep
                      : (((details.offset.dx - adjustmentx) / _gridStep)
                                  .truncateToDouble() +
                              1) *
                          _gridStep;
              double yOffset =
                  (details.offset.dy - adjustmenty).toInt() % _gridStep < 15 / 2
                      ? ((details.offset.dy - adjustmenty) / _gridStep)
                              .truncateToDouble() *
                          _gridStep
                      : (((details.offset.dy - adjustmenty) / _gridStep)
                                  .truncateToDouble() +
                              1) *
                          _gridStep;

              _position = Offset(xOffset, yOffset);

              TableService.editTablePosition(widget.id, xOffset, yOffset);
            }
          });
        },
      ),
    );
  }

  String getImagePath() {
    if (_hasOrder && _hasReservation) {
      return widget.imagePath + "_reserved_ordered.png";
    } else if (_hasOrder) {
      return widget.imagePath + "_ordered.png";
    } else if (_hasReservation) {
      return widget.imagePath + "_reserved.png";
    } else {
      return widget.imagePath + ".png";
    }
  }
}

/// Receives a table size and returns the path to the corresponding image
///
/// @param tableSize: size of the table
/// @note image paths are without extension
String getBaseImagePath(int tableSize) {
  switch (tableSize) {
    case 2:
      return constants.AssetPaths.small2.value;
    case 3:
      return constants.AssetPaths.small3.value;
    case 4:
      return constants.AssetPaths.small4.value;
    case 6:
      return constants.AssetPaths.large6.value;
    case 8:
      return constants.AssetPaths.large8.value;
  }

  throw Exception("Invalid table size!");
}

/// Receives a table size and returns a list containing the required dimensions
///
///@param tableSize: the size of the table
///@returns List<int> containing [0] = width and [1] = height
List<int> getImageSize(int tableSize) {
  const List<int> smallTable = [constants.smallTblWidth, constants.tblHeight];
  const List<int> largeTable = [constants.largeTblWidth, constants.tblHeight];

  switch (tableSize) {
    case 2:
      return smallTable;
    case 3:
      return smallTable;
    case 4:
      return smallTable;
    case 6:
      return largeTable;
    case 8:
      return largeTable;
  }

  throw Exception("Invalid table size!");
}
