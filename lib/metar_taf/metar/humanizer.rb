# Metar parser based on this spec : http://meteocentre.com/doc/metar.html
module Metar
  class Humanizer
    attr_reader :raw, :parsed, :readable
    def initialize(raw)
      parser = Metar::Parser.new(raw)
      parser.process
      @parsed = parser.parsed
    end

    { raw: 'METAR EFJY 171950Z AUTO CCA 27006KT 220V310 9999 R36/1000V2400FT/U +BLSN VCSH FEW012 SCT015 BKN060 13/12 Q1006 REFZRA WS RWY36',
    parsed:
      { type: 'METAR',
        station: 'EFJY',
        time: Time.strptime('171950+0000', '%d%H%M%z'),
        auto: true,
        correction: 'A',
        wind:   { speed: 6,
                  direction: 270,
                  variable: true,
                  variation: { min: 220, max: 310 },
                  unit: 'KT' },
        cavok: false,
        visibility: { distance: 9999.0, unit: 'meters' },
        runway_visual_range: { runway: '36', direction: nil, minIndicator: nil, minValue: '1000', maxIndicator: nil, maxValue: '2400', unit: 'FT', trend: 'U' },
        weather: ['heavy intensity blowing snow', 'in the vicinity showers'],
        clouds:   [{ type: 'few',
                     altitude: 1200,
                     cumulonimbus: false,
                     towering_cumulus: false },
                   { type: 'scattered',
                     altitude: 1500,
                     cumulonimbus: false,
                     towering_cumulus: false },
                   { type: 'broken',
                     altitude: 6000,
                     cumulonimbus: false,
                     towering_cumulus: false }],
        recent_weather: 'Freezing Rain',
        temperature: { temperature: 13, dewpoint: 12 },
        windshear: 'runway 36',
        altimeter: { hpa: 1006 },
        non_standard: nil
    },
    readable: ''
  }

    def read
      str =  "#{station}" + (auto ? ' (autostation)' : '') + '. '
      str += 'CORRECTED report. ' if correction == true
      str += "Correction ##{correction}. " if correction && correction != true
      str += parsed[:time].strftime('%b %e, %H:%M UTC') + '. '
      str += read_wind
      str += 'Clear sky. ' if cavok
      str += "Visibility #{visibility[:distance]} #{visibility[:unit]}. " if visibility
      str += "Temperature #{temperature[:temperature]} degrees, Dew point #{temperature[:dewpoint]} degrees. "
      str += 'Pressure altitude ' + (altimeter[:hpa] ? altimeter[:hpa].to_s + ' hpa' : altimeter[:hg].to_s + ' inches of mercury') + '. ' if altimeter[:hpa] || altimeter[:hg]
      @readable = str.strip
    end

    def read_wind
      return '' unless wind

      str = ''
      str += 'Variable ' if wind[:variable]
      str += "(from #{wind[:variation][:min]} to #{wind[:variation][:max]} degrees) " if wind[:variation]
      str + "Wind of #{wind[:speed]}#{wind[:unit]}" + (wind[:direction] ? " at #{wind[:direction]} degrees. " : '. ')
    end

    def read_runway_visual_range
      return '' unless runway_visual_range

      str = "Visual range for runway ##{runway_visual_range[:runway]} "
      str += runway_visual_range[:direction]
    end

    def method_missing(method_name, *arguments, &block)
      if parsed && parsed.keys.include?(method_name)
        parsed[method_name]
      else
        super
      end
    end

    def respond_to?(method_name, include_private = false)
      (parsed && parsed.keys.include?(method_name.to_s.split('_')[0])) || super
    end
  end
end
