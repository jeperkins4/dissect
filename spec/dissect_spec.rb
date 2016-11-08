require 'spec_helper'
require 'stackprof'

describe Dissect::Text do
  let(:dissect) { Dissect::Text.new }
  let(:items) do
    [
      {name: 'bass', modifiers: 'standup, electric, fretless', brands: 'Yamaha,Fender', category: 'Musical Instrument'},
      {name: 'piano', modifiers: 'standup,grand,baby grand', brands: 'Yamaha,Casio', category: 'Musical Instrument'},
      {name: 'guitar', modifiers: 'electric, acoustic', brands: 'Gibson,Ibanez,Fender', category: 'Musical Instrument'},
      {name: 'apple', alternates: 'apples', modifiers: 'granny smith, macintosh', brands: nil, category: 'Produce'},
      {name: 'football', brands: 'Nike,Wilson', category: 'Sporting Goods'},
      #{name: 'Macbook', modifiers: 'pro, air', brands: 'Apple Computer'},
      {:id=>3368, :name=>"macbook", :modifiers=>"pro, air", :brands=>"Apple Computer, LOVEdecal, Consumer Electronics Store,iBenzer,Kuzy,Case Logic,fds,Moshi,Apple", :category=>"Electronics"},
      {name: 'shoes', brands: 'Blundstone,Nike,Adidas', category: 'Clothing'},
      {name: 'merlot', brands: "Frog's Leap, Rodney Strong", category: 'Beer, Wine & Spirits' },
      {name: 'cabernet sauvignon', brands: "Frog's Leap, Grgich Hills", category: 'Beer, Wine & Spirits' },
      {name: 'Al Capone', brands: nil, category: 'Inmate' },
      {name: "bottled water", modifiers: "spring, purified, distilled, mineral", brands: "Dasani, SmartWater, FIJI Water, FIJI, Fiji", alternates: "water, water bottles", category: "Beverages"}
    ]
  end

  context 'phraser' do
    it "should return a match" do
      terms = dissect.phraser('Yamaha Electric Bass', items)
      terms.each do |term|
        term[:item][:name].should == 'bass'
        term[:category].should == 'Musical Instrument'
        term[:terms].downcase.should == 'yamaha electric bass'
        term[:brand].should == 'Yamaha'
      end
    end

    it "should return a match for football" do
      terms = dissect.phraser('Football', items)
      terms.each do |term|
        term[:item][:name].should == 'football'
      end
    end

    it "should return a match for Nike shoes" do
      terms = dissect.phraser('Nike shoes', items)
      matched = terms.select{|term|term[:terms] == 'Nike Shoes'}
      matched.should_not be_empty
    end

    it "should return a match for Apple" do
      terms = dissect.phraser('Apple Macbook Pro', items)
      terms.each do |term|
        term[:terms].should == 'Apple Macbook Pro'
      end
    end

    it "should return a match for Apple" do
      terms = dissect.phraser('Apples', items)
      terms.each do |term|
        term[:terms].downcase.should == 'apples'
      end
    end

    it "should return a match for Merlot" do
      terms = dissect.phraser('merlot', items)
      terms.each do |term|
        term[:terms].should == 'Merlot'
      end
    end

    it "should return a match for Merlot" do
      terms = dissect.phraser('cabernet sauvignon', items)
      terms.each do |term|
        term[:terms].should == 'Cabernet Sauvignon'
      end
    end

    it "should return a match for water" do
      terms = dissect.phraser('water', items)
      terms.each do |term|
        term[:terms].downcase.should == 'water'
      end
    end

    it "should return a match for Shoes and Merlot" do
      terms = dissect.phraser('shoes and merlot', items)
      terms.map{|term|term[:terms]}.should include('Shoes')
    end
  end
end
