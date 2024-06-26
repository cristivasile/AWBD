import 'package:flutter/material.dart';
import 'package:restaurant_management_app/bin/constants.dart';
import 'package:restaurant_management_app/bin/utilities/globals.dart';
import 'package:restaurant_management_app/bin/services/table_service.dart';
import 'package:restaurant_management_app/bin/models/table_model.dart';
import 'package:restaurant_management_app/bin/utilities/table_utils.dart';
import 'package:restaurant_management_app/bin/widgets/common/dialog.dart';
import 'package:restaurant_management_app/bin/widgets/main/table_widget.dart';
import 'package:restaurant_management_app/main.dart';

import '../../utilities/capacity_list.dart';
import '../common/custom_button.dart';

/// Floor plan builder
class FloorPlan extends StatefulWidget {
  const FloorPlan(Key? key) : super(key: key);

  @override
  State<FloorPlan> createState() => _FloorPlanState();
}

const double buttonRowRatio = 1 / 8;
const double floorSectionRatio = 1 - buttonRowRatio;
const double buttonSize = 45;

class _FloorPlanState extends State<FloorPlan> {
  late BoxConstraints _tablesBoxConstraints;
  int _currentFloor = 0;
  String _addDropdownValue = '2';
  String _removeDropdownValue = 'none';
  List<MovableTableWidget> _tableWidgets = [];
  List<TableModel> _tableModelList =
      []; //required for the first initialization of _tableWidgets
  List<String> _tableIds = ['none'];
  List<int> _floorCapacities = [-1];
  bool _read = false;
  bool _firstBuild = true;
  int _currentSeats = 0;

  @override
  void initState() {
    super.initState();
    loadTablesAsync();
  }

  void loadTablesAsync() async {
    try {
      _tableModelList = await TableService.getTables();
    } on Exception {
      showMessageBox(NavigationService.navigatorKey.currentContext!,
          'Failed to fetch tables!');
      return;
    }

    _floorCapacities = CapacityList.getCapacityList();
    if (mounted) {
      setState(() {
        _read = true;

        if (_tableModelList.isNotEmpty) {
          //dropdown must have at least one value, only update if tables exist
          _tableIds = _tableModelList.map((e) => e.id).toList();
          _tableIds.sort();
          _removeDropdownValue = _tableIds[0];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _currentSeats = getCurrentSeatNumber();
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        // for background color
        color: accent1Color,
        child: Column(
          children: [
            SizedBox(
              // top container
              width: constraints.maxWidth,
              height: constraints.maxHeight * buttonRowRatio,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Container is necessary for grouping
                  // ignore: avoid_unnecessary_containers
                  Column(
                    // <Group> +/- controls
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        // <Group> Floor controls
                        children: [
                          const Text("Current floor: "),
                          TextButton(
                            onPressed: () => decrementFloor(),
                            child: const Text("-",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            style: TextButton.styleFrom(
                                foregroundColor: mainColor),
                          ),
                          Text("$_currentFloor"),
                          TextButton(
                            onPressed: () => incrementFloor(),
                            child: const Text("+",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            style: TextButton.styleFrom(
                                foregroundColor: mainColor),
                          ),
                        ],
                      ),
                      Row(
                        // <Group> Seat capacity controls
                        children: [
                          const Text("Floor capacity: "),
                          TextButton(
                            onPressed: () => decrementCapacity(),
                            child: const Text("-",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            style: TextButton.styleFrom(
                                foregroundColor: mainColor),
                          ),
                          Text(
                              "$_currentSeats / ${(_floorCapacities[_currentFloor] == -1) ? "∞" : _floorCapacities[_currentFloor]}"),
                          TextButton(
                            onPressed: () => incrementCapacity(),
                            child: const Text("+",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            style: TextButton.styleFrom(
                                foregroundColor: mainColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Container is necessary for grouping
                  // ignore: avoid_unnecessary_containers
                  Container(
                    // <Add Table> GROUP
                    child: Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          child: DropdownButton<String>(
                            //table size selector
                            value: _addDropdownValue,
                            icon: const Icon(Icons.arrow_downward),
                            elevation: 16,
                            style: const TextStyle(color: Colors.black),
                            underline: Container(
                              height: 2,
                              color: mainColor,
                            ),
                            onChanged: (String? newValue) {
                              setState(() {
                                _addDropdownValue = newValue!;
                              });
                            },
                            items: ['2', '3', '4', '6', '8']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                        //add table button
                        CustomButton(
                            size: buttonSize,
                            icon: const Icon(Icons.add),
                            color: mainColor,
                            onPressed: () => addTable()),
                      ],
                    ),
                  ),
                  // Container is necessary for grouping
                  // ignore: avoid_unnecessary_containers
                  Container(
                    // <Delete Table> GROUP
                    child: Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          child: DropdownButton<String>(
                            //table size selector
                            value: _removeDropdownValue,
                            icon: const Icon(Icons.arrow_downward),
                            elevation: 16,
                            style: const TextStyle(color: Colors.black),
                            underline: Container(
                              height: 2,
                              color: mainColor,
                            ),
                            onChanged: (String? newValue) {
                              setState(() {
                                _removeDropdownValue = newValue!;
                              });
                            },
                            items: _tableIds
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                        //delete table button
                        CustomButton(
                          size: buttonSize,
                          icon: const Icon(Icons.delete),
                          color: mainColor,
                          onPressed: () async => {await deleteTable()},
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                          child: CustomButton(
                            size: buttonSize,
                            icon: const Icon(Icons.zoom_in),
                            color: mainColor,
                            onPressed: () => {zoomIn()},
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: 10.0)),
                      Container(
                          child: CustomButton(
                            size: buttonSize,
                            icon: const Icon(Icons.zoom_out),
                            color: mainColor,
                            onPressed: () => {zoomOut()},
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: 10.0))
                    ],
                  ),
                ],
              ),
            ),
            // Container for the displayed tables
            Container(
              // for floor color and margin
              color: accent2Color,
              margin: const EdgeInsets.all(floorMargin),
              child: SizedBox(
                // defines fixed size for child Stack that would be infinite.
                width: constraints.maxWidth - (floorMargin * 2), // - margin * 2
                height: (constraints.maxHeight * floorSectionRatio) -
                    (floorMargin * 2), // - margin * 2
                child: LayoutBuilder(builder: (context, childConstraints) {
                  _tablesBoxConstraints = childConstraints;

                  if (_read && _firstBuild) {
                    // load tables from TableList
                    _firstBuild = false;
                    _tableWidgets =
                        getWidgetsFromTables(_tableModelList, childConstraints);
                  }

                  return Stack(
                    children: _tableWidgets
                        .where((element) => element.floor == _currentFloor)
                        .toList(), //filter only tables on the current floor
                  );
                }),
              ),
            ),
          ],
        ),
      );
    });
  }

  Future<void> addTable() async {
    UniqueKey key = UniqueKey();
    int tableSize = int.parse(_addDropdownValue);
    int capacity = _floorCapacities[_currentFloor];
    if (capacity == -1 || tableSize + _currentSeats <= capacity) {
      MovableTableWidget newTableWidget = MovableTableWidget(
        key:
            key, //tables must have a key, otherwise states can jump over to another object
        constraints: _tablesBoxConstraints,
        tableSize: int.parse(_addDropdownValue),
        position: Offset.zero,
        floor: _currentFloor,
        id: generateTableId(
            tableSize: int.parse(_addDropdownValue),
            tableWidgets: _tableWidgets),
        hasOrder: false,
        hasReservation: false,
      );

      try {
        await TableService.addTable(getTableModelFromWidget(newTableWidget));
      } on Exception catch (e) {
        showMessageBox(NavigationService.navigatorKey.currentContext!,
            'Failed to add table: $e');
        return;
      }

      setState(() {
        _tableWidgets.add(newTableWidget);
        if (_tableIds[0] == 'none') {
          // if list is empty -> only happens when adding the first table
          _tableIds = [];
        }

        _tableIds.add(newTableWidget.id);
        _tableIds.sort();
        _removeDropdownValue = _tableIds[0];
      });
    } else {
      showMessageBox(NavigationService.navigatorKey.currentContext!,
          "Cannot add a new table because the seat limit would be exceeded!");
    }
  }

  Future<void> deleteTable() async {
    final String id = _removeDropdownValue;
    if (id != 'none') {
      //check that a table is selected
      
      try {
        await TableService.removeTableById(id);
      } on Exception catch (e) {
        showMessageBox(NavigationService.navigatorKey.currentContext!,
            'Failed to add table: $e');
        return;
      }

      setState(() {
        _tableWidgets.removeWhere((element) => element.id == id);
        _tableIds.removeWhere((element) => element == id);

        if (_tableIds.isEmpty) {
          //check if list is empty because it will cause an exception
          _tableIds.add('none');
        }

        _removeDropdownValue = _tableIds[0];
      });
    }
  }

  void incrementFloor() {
    if (_currentFloor < maxFloors) {
      setState(() {
        _currentFloor += 1;
      });
    }
  }

  void decrementFloor() {
    if (_currentFloor > 0) {
      setState(() {
        _currentFloor -= 1;
      });
    }
  }

  void incrementCapacity() {
    setState(() {
      if (_floorCapacities[_currentFloor] == -1) {
        _floorCapacities[_currentFloor] = _currentSeats;
      } else {
        _floorCapacities[_currentFloor] += 1;
      }
    });
  }

  void decrementCapacity() {
    setState(() {
      if (_floorCapacities[_currentFloor] == _currentSeats) {
        _floorCapacities[_currentFloor] = -1;
      } else if (_floorCapacities[_currentFloor] != -1) {
        _floorCapacities[_currentFloor] -= 1;
      }
    });
  }

  int getCurrentSeatNumber() {
    int result = 0;

    for (var table
        in _tableModelList.where((element) => element.floor == _currentFloor)) {
      result += table.tableSize;
    }

    return result;
  }

  void zoomIn() {
    int index = getZoomIndex();
    Globals.getGlobals().tableImagesScale = zoomFactors[
        index == zoomFactors.length - 1 ? zoomFactors.length - 1 : index + 1];
    setState(() {
      _firstBuild = true; //rebuild children widgets
    });
    saveGlobalObject();
  }

  void zoomOut() {
    int index = getZoomIndex();
    Globals.getGlobals().tableImagesScale =
        zoomFactors[index == 0 ? 0 : index - 1];
    setState(() {
      _firstBuild = true; //rebuild children widgets
    });
    saveGlobalObject();
  }
}
