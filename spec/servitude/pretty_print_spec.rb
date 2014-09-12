require "servitude/pretty_print"

describe Servitude::PrettyPrint do

  describe '.configuration_lines' do
    def configuration_lines( *arguments )
      described_class.configuration_lines( *arguments )
    end

    describe 'a key-value pair' do
      specify {
        expect( configuration_lines( foo: 'bar' )).to eq( ["foo: bar"] )
      }
    end

    describe 'multiple key-value pair' do
      specify {
        expect( configuration_lines( foo: 'bar', baz: 'bam' )).to eq( ["foo: bar", "baz: bam"] )
      }
    end

    describe 'a nested key-value pair' do
      specify {
        expect( configuration_lines({ foo: { 'bar' => 'baz' } })).to eq( ["foo.bar: baz"] )
      }
    end

    describe 'a nested config with an array' do
      specify {
        expect( configuration_lines({ foo: { 'bar' => 'baz', bam: [1,2,3] } })).to eq( ["foo.bar: baz", "foo.bam: [1, 2, 3]"] )
      }
    end

    describe 'a nested config with an array with filter apilied' do
      specify {
        expect( configuration_lines({ foo: { 'bar' => 'baz', bam: [1,2,3] } }, '', %w(foo.bam))).to eq( ["foo.bar: baz"] )
      }
    end
  end

  describe '.format_configuration' do
    def format_configuration( *arguments )
      described_class.format_configuration( *arguments )
    end

    describe 'a key-value pair' do
      specify {
        expect( format_configuration( foo: 'bar' )).to eq( [["foo", "bar"]] )
      }
    end

    describe 'multiple key-value pair' do
      specify {
        expect( format_configuration( foo: 'bar', baz: 'bam' )).to eq( [["foo","bar"],["baz","bam"]] )
      }
    end

    describe 'a nested key-value pair' do
      specify {
        expect( format_configuration({ foo: { 'bar' => 'baz' } })).to eq( [["foo.bar", "baz"]] )
      }
    end

    describe 'a nested config with an array' do
      specify {
        expect( format_configuration({ foo: { 'bar' => 'baz', bam: [1,2,3] } })).to eq( [["foo.bar", "baz"], ["foo.bam", "[1, 2, 3]"]] )
      }
    end
  end

end
