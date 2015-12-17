require 'spec_helper'

describe MetarTaf::Metar do
  describe '#parse' do

    it { expect({a: 'a', b: 'b', c: {d: 'd'}}).to eq({b: 'b', a: 'a', c: {d: 'd'}})}

    it do
      METAR_EXPECTATIONS.each do |original, parsed|
        expect(MetarTaf::Metar.new(original).parse).to eq(parsed)
      end
    end
  end
end
