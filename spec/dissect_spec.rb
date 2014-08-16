require 'spec_helper'

describe Dissect do
  let(:brands) do
    [
      {name: 'Yamaha', categories: 'Musical Instrument'},
      {name: 'Fender', categories: 'Musical Instrument'},
      {name: 'Gibson', categories: 'Musical Instrument'},
      {name: 'Casio', categories: 'Musical Instrument'},
      {name: 'Ibanez', categories: 'Musical Instrument'},
      {name: 'Nike', categories: 'Sporting Goods'},
      {name: 'Wilson', categories: 'Sporting Goods'},
      {name: 'Adidas', categories: 'Clothing'},
      {name: 'Blundstone', categories: 'Clothing'}
    ]
  end
  let(:items) do
    [
      {name: 'bass', modifiers: 'standup, electric, fretless', brands: 'Yamaha,Fender'},
      {name: 'piano', modifiers: 'standup,grand,baby grand', brands: 'Yamaha,Casio'},
      {name: 'guitar', modifiers: 'electric, acoustic', brands: 'Gibson,Ibanez,Fender'},
      {name: 'football', brands: 'Nike,Wilson'},
      {name: 'shoes', brands: 'Blundstone,Nike,Adidas'}
    ]
  end

  context 'phraser' do
    it "should return a match" do
      terms = Dissect.phraser('Yamaha Electric Bass', brands, items)
      terms.each do |term|
        term[:brand][:name].should == 'Yamaha'
        term[:item][:name].should == 'bass'
        term[:category].should == 'Musical Instrument'
        term[:terms].downcase.should == 'yamaha electric bass'
      end
    end

    it "should return a match for football" do
      terms = Dissect.phraser('Football', brands, items)
      terms.each do |term|
        term[:item][:name].should == 'football'
      end
    end

    it "should return a match for Nike shoes" do
      terms = Dissect.phraser('Nike shoes', brands, items)
      terms.each do |term|
        term[:terms].should == 'Nike shoes'
      end
    end
  end
end
