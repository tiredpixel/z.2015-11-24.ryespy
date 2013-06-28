require 'minitest/autorun'

require_relative '../../lib/ryespy/version'


describe "Ryespy::VERSION" do
  
  it "uses major.minor.patch" do
    Ryespy::VERSION.must_match /\A\d+\.\d+\.\d+\z/
  end
  
end
