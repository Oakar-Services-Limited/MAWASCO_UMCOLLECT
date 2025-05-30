class GridIcons {
  List<String> getImagePaths() {
    return [
      'assets/images/leaks.png',
      'assets/images/burst.png',
      'assets/images/supplyfail.png',
      'assets/images/illegalconnection.png',
      'assets/images/vandalism.png',
      'assets/images/other.png',
    ];
  }

  List<String> getIncidences() {
    return [
      'Leakage',
      'Sewer Burst',
      'Supply Fail',
      'Illegal Connection',
      'Vandalism',
      'Other',
    ];
  }

  List<String> getWaterNetworkImages() {
    return [
      'assets/images/customer-meter.png',
      'assets/images/water-pipe.png',
      'assets/images/water-tank.png',
      'assets/images/valve.png',
      'assets/images/master-meter.png',
      'assets/images/washout.png',
    ];
  }

  List<String> getWaterNetworkTitles() {
    return [
      'Customer Meters',
      'Water Pipes',
      'Water Tanks',
      'Valves',
      'Master Meters',
      'Washouts',
    ];
  }

  List<String> getSewerNetworkImages() {
    return [
      'assets/images/sewer.png',
      'assets/images/manhole.png',
      // 'assets/images/pump.png',
      // 'assets/images/filter.png',
      // 'assets/images/sewerchamber.png',
    ];
  }

  List<String> getSewerNetworkTitles() {
    return [
      'Sewer Lines',
      'Manholes',
      // 'Pumping Stations',
      // 'Grit Chambers',
      // 'Sewer Treatment'
    ];
  }

  List<String> getNewProjectImages() {
    return [
      'assets/images/points.png',
      // 'assets/images/sewerchamber.png',
      'assets/images/lines.png',
      // 'assets/images/sewer.png',
    ];
  }

  List<String> getNewProjectTitles() {
    return [
      'Project (Points)',
      // 'New Sanitation Connections',
      'Project (Lines)',
      // 'Customer Lines'
    ];
  }
}
