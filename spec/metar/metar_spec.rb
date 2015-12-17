require 'spec_helper'

describe Metar::Parser do
  describe '#parse' do
    METAR_EXPECTATIONS.each do |obj|
      parser = Metar::Parser.new(obj[:raw])
      parser.process
      it { expect(parser.parsed).to eq(obj[:parsed]) }
    end

    METAR_EXPECTATIONS.each do |obj|
      humanizer = Metar::Humanizer.new(obj[:raw])
      humanizer.read
      it { expect(humanizer.readable).to eq(obj[:readable]) }
    end
  end
end
