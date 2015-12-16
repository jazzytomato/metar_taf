require 'spec_helper'

describe MetarTaf::Metar do
  describe '#parse' do

    it do
      METAR_EXPECTATIONS.each do |original, parsed|
        expect(MetarTaf::Metar.new(original).parse).to eq(parsed)
      end
    end
  end
end
