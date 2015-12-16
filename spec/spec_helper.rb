require 'metar_taf'

METAR_EXPECTATIONS = {

  'METAR EFJY 171950Z AUTO CCA 27006KT 220V310 9999 R36/1000V2400FT/U +BLSN VCSH FEW012 SCT015 BKN060 13/12 Q1006' =>

  { type: 'METAR',
    station: 'EFJY',
    time: '2013-12-17T19:50:38.219Z',
    auto: true,
    correction: 'A',
    wind:   { speed: 6,
              direction: 270,
              variable: true,
              variation: { min: 220, max: 310 },
              unit: 'KT' },
    cavok: false,
    visibility: { distance: 9999, units: 'meters' },
    runway_visual_range: {runway: '36', direction: nil, minIndicator: nil, minValue: '1000', maxIndicator: nil, maxValue: '2400', unit: 'FT', trend: 'U'},
    weather: nil,
    clouds:   [{ abbreviation: 'FEW',
                 meaning: 'few',
                 altitude: 1200,
                 cumulonimbus: false },
               { abbreviation: 'SCT',
                 meaning: 'scattered',
                 altitude: 1500,
                 cumulonimbus: false },
               { abbreviation: 'BKN',
                 meaning: 'broken',
                 altitude: 6000,
                 cumulonimbus: false }]
},

  'SPECI EGGW 151750Z 14012KPH 6000 RA BKN003 OVC004 10/10 Q1014' =>

  { type: 'SPECI',
    station: 'EGGW',
    time: '2015-12-15T17:50:56.562Z',
    auto: false,
    correction: false,
    wind:   { speed: 12, direction: 140, variable: false, variation: nil, unit: 'KPH' },
    cavok: false,
    visibility: { distance: 6000, units: 'meters' },
    weather: [{ abbreviation: 'RA', meaning: 'rain' }],
    clouds:   [{ abbreviation: 'BKN',
                 meaning: 'broken',
                 altitude: 300,
                 cumulonimbus: false },
               { abbreviation: 'OVC',
                 meaning: 'overcast',
                 altitude: 400,
                 cumulonimbus: false }],
    temperature: 10,
    dewpoint: 10,
    altimeter_hpa: 1014
  },

  'EHLW 151755Z AUTO 11011KT 060V150 4000 BR BKN048 06/05 Q1023 GRN 12010KT 4500 BR BKN040' =>

  { type: 'METAR',
    station: 'EHLW',
    time: '2015-12-15T17:55:07.529Z',
    auto: true,
    correction: false,
    wind:   { speed: 11,
              direction: 110,
              variable: true,
              variation: { min: 60, max: 150 },
              unit: 'KT' },
    cavok: false,
    visibility: { distance: 4000, units: 'meters' },
    weather: [{ abbreviation: 'BR', meaning: 'mist' }],
    clouds:   [{ abbreviation: 'BKN',
                 meaning: 'broken',
                 altitude: 4800,
                 cumulonimbus: false }],
    temperature: 6,
    dewpoint: 5,
    altimeter_hpa: 1023
  },

  'CYSB 231400Z 30006KT 20SM FEW180 M30/M34 A3038 RMK CI1 CI TR SLP333' =>

  { type: 'METAR',
    station: 'CYSB',
    time: '2015-12-23T14:00:40.586Z',
    auto: false,
    correction: false,
    wind:   { speed: 6, direction: 300, variable: false, variation: nil, unit: 'KT' },
    cavok: false,
    visibility: { distance: 20, units: 'SM' },
    weather: nil,
    clouds:   [{ abbreviation: 'FEW',
                 meaning: 'few',
                 altitude: 18_000,
                 cumulonimbus: false }],
    temperature: -30,
    dewpoint: -34,
    altimeter_in_hg: 30.38
  },

  'KBIL 162256Z VRB17G27KT 3/4SM FEW070 SCT085 BKN110 M02/M02 A2961 RMK AO2 PK WND 29027/2250 WSHFT 2241 SLP205 70033 T10171022 11006 21017 53016' =>

  {
    type: 'METAR',
    station: 'KBIL',
    time: '2015-12-16T22:56:49.441Z',
    auto: false,
    correction: false,
    wind:   { speed: 17, gust: 27, direction: nil, variable: true, variation: nil, unit: 'KT' },
    cavok: false,
    visibility: { distance: 3 / 4, units: 'SM' },
    weather: nil,
    clouds:   [{ abbreviation: 'FEW',
                 meaning: 'few',
                 altitude: 7000,
                 cumulonimbus: false },
               { abbreviation: 'SCT',
                 meaning: 'scattered',
                 altitude: 8500,
                 cumulonimbus: false },
               { abbreviation: 'BKN',
                 meaning: 'broken',
                 altitude: 11_000,
                 cumulonimbus: false }],
    temperature: -2,
    dewpoint: -2,
    altimeter_in_hg: 29.61 }

}
