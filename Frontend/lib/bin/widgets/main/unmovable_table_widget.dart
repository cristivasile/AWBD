// ignore: file_names
import 'package:flutter/material.dart';
import 'package:restaurant_management_app/bin/constants.dart' as constants;
import 'package:restaurant_management_app/bin/services/auth_service.dart';
import 'package:restaurant_management_app/bin/services/order_service.dart'
    as orders;
import 'package:restaurant_management_app/bin/services/order_service.dart';
import 'package:restaurant_management_app/bin/services/reservation_service.dart'
    as reservations;
import 'package:restaurant_management_app/bin/models/order_model.dart';
import 'package:restaurant_management_app/bin/models/reservation_model.dart';
import 'package:restaurant_management_app/bin/services/reservation_service.dart';
import 'package:restaurant_management_app/bin/widgets/common/dialog.dart';
import 'package:restaurant_management_app/main.dart';

import '../../constants.dart';
import '../../utilities/globals.dart';
import 'orders_widget.dart';

/// Movable table object
///
class UnmovableTableWidget extends StatefulWidget {
  final String imagePath; //the corresponding table's image path
  final int _imageWidth; // width of the displayed image
  final int imageHeight; // height of the displayed image
  final int tableSize;
  final String id;
  final int floor;
  final bool hasOrder;
  final bool hasReservation;
  final Offset
      position; // position relative to the top left corner of the container
  final void Function() callback;
  UnmovableTableWidget({
    Key? key,
    required this.tableSize,
    required this.position,
    required this.id,
    required this.floor,
    required this.callback,
    required this.hasOrder,
    required this.hasReservation,
  })  : imagePath = getBaseImagePath(tableSize),
        _imageWidth = getImageSize(tableSize)[0],
        imageHeight = getImageSize(tableSize)[1],
        super(key: key);

  @override
  State<UnmovableTableWidget> createState() => _UnmovableTableWidgetState();
}

class _UnmovableTableWidgetState extends State<UnmovableTableWidget> {
  static String selectedId = "";
  late Offset _position;
  late double _scale;
  late OrderModel? _order;
  late ReservationModel? _reservation;
  late bool _hasReservation;
  late bool _hasOrder;

  @override
  void initState() {
    super.initState();
    _position = widget.position;

    _order = null;
    _reservation = null;
    _hasOrder = widget.hasOrder;
    _hasReservation = widget.hasReservation;
  }

  Future<void> fetchReservation() async {
    try {
      var upcomingReservation =
          await ReservationService.getCurrentReservationByTableId(widget.id);
      //has a reservation in the next 3 hours
      setState(() {
        _reservation = upcomingReservation;
      });
    } on Exception {
      return;
    }
  }

  Future<void> fetchOrder() async {
    try {
      var order = await OrderService.getOrderByTableId(widget.id);
      setState(() {
        _order = order;
      });
    } on Exception {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    _scale = Globals.getGlobals().tableImagesScale;
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: SizedBox(
        width: widget._imageWidth.toDouble() * _scale,
        height: widget.imageHeight.toDouble() * _scale,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Image(
              //set the image accordingly
              image: AssetImage(getImagePath()),
              width: widget._imageWidth.toDouble() * _scale,
              height: widget.imageHeight.toDouble() * _scale,
            ),
            Text(
              widget.id,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18 * _scale,
                  fontWeight: FontWeight.bold),
            ),
            GestureDetector(onTap: () async {
              if (AuthService.canSeeStaffFunctions) {
                await fetchOrder();
                await fetchReservation();

                setState(() {
                  if (selectedId == "") {
                    selectedId = widget.id;

                    showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return StatefulBuilder(builder: (context, setState) {
                            return AlertDialog(
                                title: Text('Table ${widget.id} info',
                                    style: const TextStyle(color: mainColor)),
                                content: SizedBox(
                                  height: 300,
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Text(getReservationText()),
                                        (AuthService.canSeeStaffFunctions
                                            ? Column(
                                                children: [
                                                  Text(getOrderText()),
                                                  SizedBox(
                                                    height: 200,
                                                    width: 300,
                                                    child: ListView.builder(
                                                      controller:
                                                          ScrollController(),
                                                      itemBuilder:
                                                          (BuildContext context,
                                                              int index) {
                                                        return DialogListItem(
                                                          name: _order!
                                                              .products[index]
                                                              .name,
                                                          category: _order!
                                                              .products[index]
                                                              .category,
                                                          quantity: _order!
                                                                  .quantities[
                                                              index],
                                                        );
                                                      },
                                                      itemCount: _order != null
                                                          ? _order!
                                                              .products.length
                                                          : 0,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Container()),
                                      ]),
                                ),
                                actions: [
                                  (_hasOrder
                                      ? TextButton(
                                          child: const Text('Finish order'),
                                          style: TextButton.styleFrom(
                                              foregroundColor: mainColor),
                                          onPressed: () {
                                            setState(() {
                                              removeOrder();
                                            });
                                          })
                                      : Container()),
                                  (_hasReservation
                                      ? TextButton(
                                          child:
                                              const Text('Clear reservation'),
                                          style: TextButton.styleFrom(
                                              foregroundColor: mainColor),
                                          onPressed: () {
                                            setState(() {
                                              removeReservation();
                                            });
                                          })
                                      : Container()),
                                  TextButton(
                                      child: const Text('Close'),
                                      style: TextButton.styleFrom(
                                          foregroundColor: mainColor),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        selectedId = "";
                                        widget.callback();
                                      })
                                ]);
                          });
                        });
                  } else if (selectedId == widget.id) {
                    selectedId = "";
                  }
                  widget.callback();
                });
              }
            }),
          ],
        ),
      ),
    );
  }

  void removeOrder() async {
    try {
      await orders.OrderService.removeOrderByTableId(_order!.tableId);
      _order = null;
      _hasOrder = false;
      selectedId = "";
      Navigator.of(context).pop();
      widget.callback();
    } on Exception {
      showMessageBox(NavigationService.navigatorKey.currentContext!,
          'Failed to remove order!');
      return;
    }
  }

  void removeReservation() async {
    try {
      await reservations.ReservationService.removeReservationById(
          _reservation!.reservationId);

      _reservation = null;
      _hasReservation = false;
      selectedId = "";
      Navigator.of(context).pop();
      widget.callback();
    } on Exception {
      showMessageBox(NavigationService.navigatorKey.currentContext!,
          'Failed to remove reservation!');
      return;
    }
  }

  String getImagePath() {
    if (widget.id == selectedId) {
      return widget.imagePath + "_feedback.png";
    } else if (_hasOrder && _hasReservation) {
      return widget.imagePath + "_reserved_ordered.png";
    } else if (_hasOrder) {
      return widget.imagePath + "_ordered.png";
    } else if (_hasReservation) {
      return widget.imagePath + "_reserved.png";
    } else {
      return widget.imagePath + ".png";
    }
  }

  String getReservationText() {
    if (_reservation == null) {
      return 'The table is not reserved in the next $reservationDurationHours hours.';
    } else {
      return 'The table is reserved by ${_reservation!.name} from ${_reservation!.dateTime.hour}:${_reservation!.dateTime.minute} until ${_reservation!.dateTime.hour + 3}:${_reservation!.dateTime.minute}';
    }
  }

  String getOrderText() {
    if (_order == null) {
      return "There is no current order";
    } else {
      return "Order details:";
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
