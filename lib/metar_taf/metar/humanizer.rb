# Metar parser based on this spec : http://meteocentre.com/doc/metar.html
module Metar
  class Humanizer
    attr_reader :raw, :parsed, :readable
    def initialize(raw)
      parser = Metar::Parser.new(raw)
      parser.process
      @raw = raw
      @parsed = parser.parsed
      @readable = ''
    end

    def read
      %i(station correction time wind cavok visibility temperature altimeter
         runway_visual_range weather clouds recent_weather windshear
         non_standard).each do |sym|
        send("read_#{sym}")
      end
      @readable.strip!.gsub!(/\s+/, ' ')
    end

    private

    # append the given string to the readable final string.
    # also capitalize the first letters and those followed by a dot
    def add(str)
      @readable += str.sub(/./) { $&.upcase } + (str.length > 1 ? '. ' : '')
    end

    def read_station
      add("#{station}" + (auto ? ' (autostation)' : ''))
    end

    def read_correction
      add('CORRECTED report') if correction == true
      add("correction ##{correction}") if correction && correction != true
    end

    def read_time
      add(parsed[:time].strftime('%b %e, %H:%M UTC'))
    end

    def read_wind
      return unless wind

      str = ''
      str += 'variable ' if wind[:variable]
      str += "(from #{wind[:variation][:min]} to #{wind[:variation][:max]} degrees) " if wind[:variation]
      str += "wind of #{wind[:speed]}#{wind[:unit]}" + (wind[:direction] ? " at #{wind[:direction]} degrees" : '')
      str += " with gusts to #{wind[:gust]}#{wind[:unit]}" if wind[:gust]
      add(str)
    end

    def read_cavok
      add('clear sky') if cavok
    end

    def read_visibility
      add("visibility #{visibility[:distance]} #{visibility[:unit]}") if visibility
    end

    def read_temperature
      return unless temperature
      add("temperature #{temperature[:temperature]} degrees") if temperature[:temperature]
      add("dew point #{temperature[:dewpoint]} degrees") if temperature[:dewpoint]
    end

    def read_altimeter
      return unless altimeter

      str = 'pressure altitude '
      if altimeter[:hpa]
        str += altimeter[:hpa].to_s + ' hpa'
      else
        str += altimeter[:hg].to_s + ' inches of mercury'
      end
      add(str)
    end

    def read_runway_visual_range
      return unless runway_visual_range

      str = "visual range for runway ##{runway_visual_range[:runway]} #{runway_visual_range[:direction]} is "
      str += 'varying from ' if runway_visual_range[:maxValue]
      str += "#{runway_visual_range[:minIndicator]} #{runway_visual_range[:minValue]} "
      str += "to #{runway_visual_range[:maxIndicator]} #{runway_visual_range[:maxValue]} " if runway_visual_range[:maxValue]
      str += "#{runway_visual_range[:unit]}, the trend is #{runway_visual_range[:trend]}"
      add(str)
    end

    def read_weather
      add("weather : #{weather.join(', ')}") if weather
    end

    # TODO: check the unit
    def read_clouds
      return unless clouds
      add(
        clouds.map do |c|
          str = "#{c[:type]} clouds at #{c[:altitude]} feets"
          str += ' and cumulonimbus' if c[:cumulonimbus]
          str += ' and towering_cumulus' if c[:towering_cumulus]
          str
        end.join(', ')
      )
    end

    def read_recent_weather
      add("#{recent_weather}") if recent_weather
    end

    def read_windshear
      add("windshear was encountered on #{windshear}") if windshear
    end

    def read_non_standard
      add("not parsed : #{non_standard}") if non_standard
    end

    # provide direct access to the keys of the `parsed` hash. ie `weather` instead of parsed[:weather]
    def method_missing(method_name, *arguments, &block)
      if parsed && parsed.keys.include?(method_name)
        parsed[method_name]
      else
        super
      end
    end

    def respond_to?(method_name, include_private = false)
      parsed && parsed.keys.include?(method_name) || super
    end
  end
end
