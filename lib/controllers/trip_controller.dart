import '../models/trip.dart';
import '../data/trip_data.dart';

class TripController {
  List<Trip> getTrips() {
    return trips;
  }

  void addTrip(Trip trip) {
    trips.add(trip);
  }
};