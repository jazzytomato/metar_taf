require 'yaml'
require 'time'

module MetarTaf
  # Metar parser based on this spec : http://meteocentre.com/doc/metar.html
  class Metar
    attr_reader :raw, :dictionnary, :readable

    def initialize(raw)
      @raw = raw
      @dictionnary = YAML.load(File.open('dictionnaries/metar.yml'))
      @results = {}
    end

    def parse
      @fields = @raw.split(' ').map(&:strip)
      @results[:type] = parse_type
      @results[:station] = parse_station
      @results[:time] = parse_date
      @results[:auto] = parse_auto
      @results[:correction] = parse_correction
      @results[:wind] = parse_wind
      @results[:cavok] = parse_cavok
      @results[:visibility] = parse_visibility
      @results[:runway_visual_range] = parse_runway_visual_range
      @results[:weather] = parse_all_weather
      @results[:clouds] = parse_clouds

      puts '*' * 10
      puts @results
      puts '*' * 10

      # parse_clouds
      # parse_temp_dewpoint
      # parse_altimeter
      # parse_recent_significant_weather
    end

    def parse_type
      dictionnary[:types].include?(@fields.first) ? @fields.shift : 'METAR'
    end

    def parse_station
      @fields.shift
    end

    def parse_date
      Time.strptime(@fields.shift + '+0000', '%d%H%MZ%z')
    end

    def parse_auto
      !!(@fields.first == 'AUTO' && @fields.shift)
    end

    # returns true if COR
    # returns the correction version if CC*, version can be A,B,C...
    def parse_correction
      return true if @fields.first == 'COR' && @fields.shift

      if (m = /CC([A-Z])/.match(@fields.first))
        @fields.shift
        m[1]
      else
        false
      end
    end

    # 14012G23KT -> Wind 140 deg at 12 knots with gusts at 23 knots
    # VRB02KT -> Wind direction variable with a speed of 2 knots
    def parse_wind
      wind = @fields.shift
      results = { variation: {} }

      puts wind
      if (direction = wind[0..2]) == 'VRB'
        results[:variable] = true
      else
        results[:variable] = false
        results[:direction] = direction.to_i
      end

      results[:gust] = wind[6..7] if wind[5] == 'G'

      results[:unit] = /KT|MPS|KPH|SM$/.match(wind)[0]

      if (wind_var = /^([0-9]{3})V([0-9]{3})$/.match(@fields.first))
        @fields.shift
        results[:variable] = true
        results[:variation][:min] = wind_var[1]
        results[:variation][:max] = wind_var[2]
      end
      results
    end

    def parse_cavok
      !!(@fields.first == 'CAVOK' && @fields.shift)
    end

    def parse_visibility
      if (m = /((\d\/?){1,4})(SM)?$/.match(@fields.first))
        @fields.shift
        { distance: m[1], unit: m[3] || 'meters' }
      end
    end

    def parse_runway_visual_range
      if /^R[0-9]+/ =~ @fields.first &&
         (rm = /R(\d{2})([L|R|C])?(\/)([P|M])?(\d+)(?:([V])([P|M])?(\d+))?(FT)?\/?([N|U|D])?/.match(@fields.shift))
        {
          runway: rm[1],
          direction: rm[2],
          minIndicator: rm[4],
          minValue: rm[5],
          maxIndicator: rm[7],
          maxValue: rm[8],
          unit: rm[9],
          trend: rm[10]
        }
      end
    end

    def parse_weather(entry)
      meaning, rest = try_lookup(:weather, entry)
      sentence = meaning

      # as long as we find a corresponding entry in the dictionnary (meaning) and that there's still work to do
      while meaning && rest
        meaning, rest = try_lookup(:weather, rest)
        sentence += ' ' + meaning
      end
      sentence
    end

    def parse_all_weather
      results = []
      while (res = parse_weather(@fields.shift))
        results << res
      end
      results
    end

    def try_lookup(type, entry)
      3.downto(0) do |n|
        value = lookup(type, entry[0..n])
        return [value, entry[n + 1..-1]] if value
      end
      [false, false]
    end

    # read from the dictionary
    def lookup(type, entry)
      dictionnary[type][entry]
    end


    def parse_clouds
      # try_lookup(:clouds, )
    end
  end
end
