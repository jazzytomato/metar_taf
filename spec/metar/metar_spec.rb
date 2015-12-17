require 'spec_helper'

describe Metar::Parser do
  describe '#parse' do
    it do
      METAR_EXPECTATIONS.each do |original, parsed|
        expect(Metar::Parser.new(original).process).to eq(parsed)
      end
    end
  end
end
