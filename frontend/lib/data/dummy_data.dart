import '../models/landmark.dart';

final List<Landmark> dummyLandmarks = [
  Landmark(
    id: 'l1',
    name: 'Old Town Gate',
    shortDescription: 'A medieval gate standing since the 14th century.',
    longDescription:
        'The Old Town Gate was built in the 14th century as the main entrance to the city.\nArchitect: Unknown.\nSignificance: Trade and defense.',
    lat: 49.8728,
    lng: 8.6512,
    imageAsset: 'assets/images/old_town_gate.jpg',
  ),
  Landmark(
    id: 'l2',
    name: 'St. Martin Church',
    shortDescription: 'Historic church with a notable clock tower.',
    longDescription:
        'St. Martin Church dates to the 16th century and houses several baroque altarpieces.\nOpening hours: 9:00 - 18:00',
    lat: 49.8700,
    lng: 8.6560,
    imageAsset: 'assets/images/st_martin.jpg',
  ),
  Landmark(
    id: 'l3',
    name: 'Riverside Bridge',
    shortDescription: 'Stone bridge built in the 1800s with scenic views.',
    longDescription:
        'Riverside Bridge was constructed in 1820. Popular spot for photos during sunset.',
    lat: 49.8680,
    lng: 8.6490,
    imageAsset: 'assets/images/riverside_bridge.jpg',
  ),
];
