# Metar parser based on this spec : http://meteocentre.com/doc/metar.html
module Metar
  class Humanizer
    attr_reader :raw, :parsed, :readable
    def initialize(raw)
      parser = Metar::Parser.new(raw)
      parser.process
      @parsed = parser.parsed
      @readable = ''
    end

    def read
      add("#{station}" + (auto ? ' (autostation)' : ''))
      add('CORRECTED report') if correction == true
      add("correction ##{correction}") if correction && correction != true
      add(parsed[:time].strftime('%b %e, %H:%M UTC'))
      add(read_wind)
      add('clear sky') if cavok
      add("visibility #{visibility[:distance]} #{visibility[:unit]}") if visibility
      add("temperature #{temperature[:temperature]} degrees, dew point #{temperature[:dewpoint]} degrees")
      add('pressure altitude ' + (altimeter[:hpa] ? altimeter[:hpa].to_s + ' hpa' : altimeter[:hg].to_s + ' inches of mercury')) if altimeter[:hpa] || altimeter[:hg]
      add(read_runway_visual_range)
      add("weather : #{weather.join(', ')}") if weather
      add(read_clouds)
      add("#{recent_weather}") if recent_weather
      add("windshear was encountered on #{windshear}") if windshear
      add("not parsed : #{non_standard}") if non_standard
      @readable.strip!.gsub!(/\s+/, ' ')
    end

    def add(str)
      @readable += capitalize_first(str) + (str.length > 1 ? '. ' : '')
    end

    def read_wind
      return '' unless wind

      str = ''
      str += 'variable ' if wind[:variable]
      str += "(from #{wind[:variation][:min]} to #{wind[:variation][:max]} degrees) " if wind[:variation]
      str + "wind of #{wind[:speed]}#{wind[:unit]}" + (wind[:direction] ? " at #{wind[:direction]} degrees" : '')
    end

    def read_runway_visual_range
      return '' unless runway_visual_range

      str = "visual range for runway ##{runway_visual_range[:runway]} #{runway_visual_range[:direction]} is "
      str += 'varying from ' if runway_visual_range[:maxValue]
      str += "#{runway_visual_range[:minIndicator]} #{runway_visual_range[:minValue]} "
      str += "to #{runway_visual_range[:maxIndicator]} #{runway_visual_range[:maxValue]} " if runway_visual_range[:maxValue]
      str + "#{runway_visual_range[:unit]}, the trend is #{runway_visual_range[:trend]}"
    end

    # TODO: check the unit
    def read_clouds
      return '' unless clouds

      clouds.map do |c|
        str = "#{c[:type]} clouds at #{c[:altitude]} feets"
        str += ' and cumulonimbus' if c[:cumulonimbus]
        str += ' and towering_cumulus' if c[:towering_cumulus]
        str
      end.join(', ')
    end

    def capitalize_first(str)
      (str.slice(0) || '').upcase + (str.slice(1..-1) || '')
    end

    # Just so I can use weather instead of parsed[:weather] etc...
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
