// for DateTime formating:
import 'package:intl/intl.dart';

extension DateTimeExtension on DateTime {
  // Originally found on Stackoverflow. Thank to x23b5. This extension helps
  // to set up DateTime values that are rounded to the nearest hour, which is
  // helpful for recommending time ssuch as start times for appointments.
  //
  // Example Usage:
  //
  // DateTime roundedDateTime = DateTime.now().roundDown(delta: Duration(hour: 1));
  // print(roundedDateTime);
  //
  // If the real time was: "2021-12-29 11:13:50.723"
  // It would print: "2021-12-29 11:00:00.000"
  //

  DateTime roundDown({Duration delta = const Duration(hours: 1)}) {
    return DateTime.fromMillisecondsSinceEpoch(
        millisecondsSinceEpoch - millisecondsSinceEpoch % delta.inMilliseconds);
  }

  String asFriendlyTimeString() {
    final DateFormat formatter = DateFormat('h:mm a');
    final String formattedTime = formatter.format(this);
    return formattedTime;
  }

  String asFriendlyDateString() {
    final DateFormat formatter = DateFormat('EEEE, MMMM d');
    final String formattedDate = formatter.format(this);
    return formattedDate;
  }

  String asFilenameString() {
    final DateFormat dateFormatter = DateFormat('yyyy-MM-dd');
    final DateFormat timeFormatter = DateFormat('H-mm-ss');
    final String formattedDate = dateFormatter.format(this);
    final String formattedTime = timeFormatter.format(this);
    return formattedDate + ' at ' + formattedTime;
  }

  String asShortDisplayString() {
    final timePortion = asFriendlyTimeString();
    final DateFormat dateFormatter = DateFormat('M/d/yyyy');
    final String formattedDate = dateFormatter.format(this);
    return formattedDate + ' at ' + timePortion;
  }
}
