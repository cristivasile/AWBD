// ignore: file_names
import 'package:flutter/material.dart';
import 'package:restaurant_management_app/bin/widgets/main/unmovable_table_widget.dart';
import '../models/table_model.dart' as table_model;
import '../models/table_model.dart';

/// Returns a list of MovableTable from a list of tables
///
/// @param tables: a list of tables
/// @param constraints: a MovableTable needs the BoxConstraints from where it is created
List<UnmovableTableWidget> getWidgetsFromTables(
    List<table_model.TableModel> tables, void Function() fun) {
  List<UnmovableTableWidget> result = [];

  for (table_model.TableModel table in tables) {
    UniqueKey key = UniqueKey();
    result.add(UnmovableTableWidget(
      key: key, //assigns new unique key to prevent states from jumping over
      tableSize: table.tableSize,
      position: Offset(table.xOffset, table.yOffset),
      id: table.id,
      floor: table.floor,
      callback: fun,
      hasOrder: table.hasOrder,
      hasReservation: table.hasReservation,
    ));
  }

  return result;
}

/// Generates unique ID for a table. Must receive either a list of tables or list of tableWidgets.
///
/// @param(optional) tables = a list of tables
/// @param(optional)
String generateTableId(
    {List<TableModel>? tables,
    List<UnmovableTableWidget>? tableWidgets,
    required int tableSize}) {
  /// Returns corresponding table letter, given a size
  ///
  String getTableLetterFromSize() {
    switch (tableSize) {
      case 2:
        return 'A';
      case 3:
        return 'B';
      case 4:
        return 'C';
      case 6:
        return 'D';
      case 8:
        return 'E';
    }
    throw Exception("Invalid table size!");
  }

  if (tables != null && tableWidgets != null) {
    throw Exception("Invalid parameters provided!");
  }

  var filteredTableIds = [];

  if (tables != null) {
    filteredTableIds = tables.where((x) => x.tableSize == tableSize).map((x) {
      return x.id;
    }).toList(); // get tables of same size and select only ids
  } else if (tableWidgets != null) {
    filteredTableIds =
        tableWidgets.where((x) => x.tableSize == tableSize).map((x) {
      return x.id;
    }).toList(); // get tables of same size and select only ids
  } else {
    throw Exception("Both list parameters were null!");
  }

  var frequency = [
    for (var i = 0; i < filteredTableIds.length; i++) false
  ]; // generate frequency vector

  for (var id in filteredTableIds) {
    var tableIndex = int.parse(id.substring(1));

    if (tableIndex - 1 < filteredTableIds.length) {
      frequency[tableIndex - 1] = true; // indexing starts from 0, subtract
    }
  }
  //search
  for (var i = 0; i < frequency.length; i++) {
    if (frequency[i] == false) {
      return "${getTableLetterFromSize()}${i + 1}";
    } //indexing starts from 0;
  }

  // no unused index was found, return length + 1
  return "${getTableLetterFromSize()}${frequency.length + 1}";
}

TableModel getTableModelFromWidget(UnmovableTableWidget widget) {
  return TableModel(
      id: widget.id,
      xOffset: widget.position.dx,
      yOffset: widget.position.dy,
      tableSize: widget.tableSize,
      floor: widget.floor,
      hasOrder: widget.hasOrder,
      hasReservation: widget.hasReservation,);
}
