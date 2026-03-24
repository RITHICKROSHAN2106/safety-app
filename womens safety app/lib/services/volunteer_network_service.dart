class VolunteerNetworkService {
  Future<List<VolunteerProfile>> findNearbyVolunteers({
    required double latitude,
    required double longitude,
  }) async {
    // Stub dataset that mimics real backend filtering by location.
    await Future<void>.delayed(const Duration(milliseconds: 500));

    return <VolunteerProfile>[
      VolunteerProfile(
        id: 'vol-101',
        name: 'Anita Sharma',
        rating: 4.8,
        distanceKm: 0.9,
        skills: const ['First Aid', 'Escort Assistance'],
        phone: '+91 98765 12345',
      ),
      VolunteerProfile(
        id: 'vol-102',
        name: 'Priya Nair',
        rating: 4.7,
        distanceKm: 1.3,
        skills: const ['Emergency Response', 'Night Patrol'],
        phone: '+91 99887 45678',
      ),
      VolunteerProfile(
        id: 'vol-103',
        name: 'Kavya Iyer',
        rating: 4.6,
        distanceKm: 1.9,
        skills: const ['Legal Support', 'Safe Transit'],
        phone: '+91 97654 33445',
      ),
    ];
  }
}

class VolunteerProfile {
  final String id;
  final String name;
  final double rating;
  final double distanceKm;
  final List<String> skills;
  final String phone;

  VolunteerProfile({
    required this.id,
    required this.name,
    required this.rating,
    required this.distanceKm,
    required this.skills,
    required this.phone,
  });
}
