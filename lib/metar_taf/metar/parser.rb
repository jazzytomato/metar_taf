require 'yaml'
require 'time'

# Metar parser based on this spec : http://meteocentre.com/doc/metar.html
module Metar
  class Parser
    attr_reader :raw, :fields, :parsed

    def initialize(raw)
      @raw = raw
      @dictionnary = YAML.load(File.open('dictionnaries/metar.yml'))
      @parsed = {}
      @fields = @raw.split(' ').map(&:strip)
    end

    def process
      %i(type station time auto correction wind cavok visibility
         runway_visual_range weather clouds temperature altimeter
         recent_weather windshear non_standard).each do |sym|
        @parsed[sym] = send("parse_#{sym}")
      end
    end

    def parse_type
      @dictionnary[:types].include?(fields.first) ? fields.shift : 'METAR'
    end

    def parse_station
      fields.shift
    end

    def parse_time
      Time.strptime(fields.shift + '+0000', '%d%H%MZ%z')
    end

    def parse_auto
      !!(fields.first == 'AUTO' && fields.shift)
    end

    # returns true if COR
    # returns the correction version if CC*, version can be A,B,C...
    def parse_correction
      return true if fields.first == 'COR' && fields.shift

      if (m = /CC([A-Z])/.match(fields.first))
        fields.shift
        m[1]
      else
        false
      end
    end

    # 14012G23KT -> Wind 140 deg at 12 knots with gusts at 23 knots
    # VRB02KT -> Wind direction variable with a speed of 2 knots
    def parse_wind
      wind = fields.shift
      results = { variation: nil, direction: nil }

      if (direction = wind[0..2]) == 'VRB'
        results[:variable] = true
      else
        results[:variable] = false
        results[:direction] = direction.to_i
      end
      results[:speed] = wind[3..4].to_i
      results[:gust] = wind[6..7].to_i if wind[5] == 'G'

      results[:unit] = /KT|MPS|KPH|SM$/.match(wind)[0]

      # 260V340 -> variations min 260 max 340
      if (wind_var = /^([0-9]{3})V([0-9]{3})$/.match(fields.first))
        fields.shift
        results[:variable] = true
        results[:variation] = { min: wind_var[1].to_i, max: wind_var[2].to_i }
      end
      results
    end

    def parse_cavok
      @cavok = !!(fields.first == 'CAVOK' && fields.shift)
    end

    def parse_visibility
      return unless !@cavok && (m = %r{((\d/?){1,4})(SM)?$}.match(fields.first))

      fields.shift
      if (operands = m[1].split('/')).count == 2
        distance = operands[0].to_f / operands[1].to_f
      else
        distance = m[1].to_f
      end
      { distance: distance, unit: m[3] || 'meters' }
    end

    def parse_runway_visual_range
      return unless !@cavok &&
                    (/^R[0-9]+/ =~ fields.first &&
                    (rm = %r{R(\d{2})([L|R|C])?(/)([P|M])?(\d+)(?:([V])([P|M])?(\d+))?(FT)?/?([N|U|D])?}.match(fields.shift)))
      {
        runway: rm[1],
        direction: lookup(:directions, rm[2]),
        minIndicator: rm[4],
        minValue: rm[5],
        maxIndicator: rm[7],
        maxValue: rm[8],
        unit: rm[9],
        trend: lookup(:trends, rm[10])
      }
    end

    def parse_weather
      return if @cavok

      results = []
      while (res = parse_single_weather(fields.first))
        fields.shift
        results << res
      end
      results if results.any?
    end

    def parse_single_weather(entry)
      meaning, rest = try_lookup(:weather, entry)
      sentence = meaning

      # as long as we find a corresponding entry in the dictionnary (meaning) and that there's still work to do
      while meaning && rest
        meaning, rest = try_lookup(:weather, rest)
        sentence += ' ' + meaning
      end
      sentence
    end

    # TODO: DRY with the weather
    def parse_clouds
      return if @cavok

      results = []
      while (res = parse_single_clouds(fields.first))
        fields.shift
        results << res
      end
      results if results.any?
    end

    def parse_single_clouds(entry)
      meaning, rest = try_lookup(:clouds, entry)
      return unless meaning && rest

      {
        type: meaning,
        altitude: rest.to_i * 100,
        cumulonimbus: !(/CB/ =~ entry).nil?,
        towering_cumulus: !(/TCU/ =~ entry).nil?
      }
    end

    # Try to find an entry into the dictionnary
    # take the first 4, then 3, until 1 character and return the first match
    # and the rest of the string for potential further lookups
    def try_lookup(type, entry)
      3.downto(0) do |n|
        value = lookup(type, entry[0..n])
        return [value, entry[n + 1..-1]] if value
      end
      [false, false]
    end

    # read from the dictionary
    def lookup(type, entry)
      @dictionnary[type][entry]
    end

    # M10/M10 or 15/13 or M01/01 etc.
    def parse_temperature
      temp = fields.shift.gsub(/M/, '-').split('/')
      {
        temperature: temp[0].to_i,
        dewpoint: temp[1].to_i
      }
    end

    # inches of mercury if AXXXX
    # nearest hectopascal if QXXXX
    def parse_altimeter
      return unless (entry = fields.shift)

      if entry[0] == 'A'
        { hg: entry[1..-1].insert(2, '.').to_f }
      elsif entry[0] == 'Q'
        { hpa: entry[1..-1].to_i }
      end
    end

    def parse_recent_weather
      return unless (entry = fields.first)

      result = lookup(:recent_weather, entry)
      fields.shift if result
      result
    end

    def parse_windshear
      return unless fields.first == 'WS'

      fields.shift

      if (entry = fields.shift) == 'ALL'
        puts entry
        fields.shift
        'all runways'
      elsif (m = /RWY(\d{1,2})(R|L|C)?/.match(entry))
        fields.shift
        "runway #{m[1]} #{lookup(:directions, m[2])}".strip
      end
    end

    # additional (non-standard) variants. not sure how to parse.
    def parse_non_standard
      fields.join(' ') unless fields.empty?
    end
  end
end
