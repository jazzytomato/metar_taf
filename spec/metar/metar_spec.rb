require 'metar_taf'
require 'metar/metar_expectations'

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

    Dir.glob('spec/metar/resources/invalid/*.TXT') do |metar|
      it "should raise a parser error on #{metar}" do
        expect { @humanizer = Metar::Humanizer.new(File.readlines(metar, encoding: 'ISO-8859-1')[1]) }.to raise_error(Error::ParserError)
      end
    end
  end

  OUTPUT_READABLE = false

  describe 'parse all files' do
    f = File.open('tmp/parsing.txt', 'a') if OUTPUT_READABLE
    Dir.glob('spec/metar/resources/valid/*.TXT') do |metar|
      it "should parse #{metar}" do
        expect { @humanizer = Metar::Humanizer.new(File.readlines(metar, encoding: 'ISO-8859-1')[1]) }.not_to raise_error
        expect { @humanizer.read }.not_to raise_error
        if OUTPUT_READABLE
          f.puts @humanizer.raw
          f.puts @humanizer.readable
          f.puts
        end
      end
    end
  end
end
