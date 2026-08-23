/// Hardcoded catalog of sports offered in the academy setup, grouped by
/// category. The add-sport picker is built from this list instead of a
/// free-text field.
const Map<String, List<String>> kSportCatalog = {
  'Team Sports': [
    'Football (Soccer)',
    'Cricket',
    'Basketball',
    'Volleyball',
    'Hockey (Field)',
    'Hockey (Ice)',
    'Baseball',
    'Rugby',
    'Handball',
    'Kabaddi',
    'Kho-Kho',
  ],
  'Racket Sports': [
    'Badminton',
    'Tennis',
    'Table Tennis',
    'Squash',
  ],
  'Combat / Martial Arts': [
    'Boxing',
    'Wrestling',
    'Judo',
    'Karate',
    'Taekwondo',
    'MMA',
    'Kickboxing',
    'Fencing',
  ],
  'Athletics / Track & Field': [
    'Sprinting',
    'Long Distance Running',
    'High Jump',
    'Long Jump',
    'Shot Put',
    'Javelin Throw',
    'Discus Throw',
    'Hurdles',
    'Decathlon',
  ],
  'Aquatic': [
    'Swimming',
    'Diving',
    'Water Polo',
    'Synchronized Swimming',
  ],
  'Gymnastics & Dance': [
    'Artistic Gymnastics',
    'Rhythmic Gymnastics',
    'Yoga',
    'Aerobics',
    'Cheerleading',
  ],
  'Precision / Aim Sports': [
    'Archery',
    'Shooting',
    'Snooker / Billiards',
    'Golf',
    'Darts',
  ],
  'Cycling & Motorsports': [
    'Cycling',
    'BMX',
  ],
  'Winter Sports': [
    'Skiing',
    'Ice Skating',
    'Snowboarding',
  ],
  'Other Popular': [
    'Skating (Roller)',
    'Skateboarding',
    'Surfing',
    'Rock Climbing',
    'Rowing',
    'Horse Riding / Equestrian',
    'Weightlifting',
    'Powerlifting',
    'CrossFit',
  ],
};

final Set<String> kAllSports = kSportCatalog.values
    .expand((sports) => sports)
    .toSet();
