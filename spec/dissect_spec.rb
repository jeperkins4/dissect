require 'spec_helper'
require 'stackprof'

describe Dissect do
  let(:brands) do
    [
      {name: 'Yamaha', categories: 'Musical Instrument'},
      {name: 'Fender', categories: 'Musical Instrument'},
      {name: 'Gibson', categories: 'Musical Instrument'},
      {name: 'Casio', categories: 'Musical Instrument'},
      {name: 'Ibanez', categories: 'Musical Instrument'},
      {name: 'Apple Computer', alternates: 'Apple', categories: 'Computers, Tablets, Phones, Electronics'},
      {name: 'Nike', categories: 'Sporting Goods'},
      {name: 'Wilson', categories: 'Sporting Goods'},
      {name: 'Adidas', categories: 'Clothing'},
      {name: 'Blundstone', categories: 'Clothing'}
    ]
  end
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
      {name: 'merlot', brands: "Frog's Leap, Rodney Strong", category: 'Beer, Wine & Spirits' }
    ]
  end

  context 'phraser' do
    it "should return a match" do
      terms = Dissect.phraser('Yamaha Electric Bass', items)
      terms.each do |term|
        term[:item][:name].should == 'bass'
        term[:category].should == 'Musical Instrument'
        term[:terms].downcase.should == 'yamaha electric bass'
        term[:brand].should == 'Yamaha'
      end
    end

    it "should return a match for football" do
      terms = Dissect.phraser('Football', items)
      terms.each do |term|
        term[:item][:name].should == 'football'
      end
    end

    it "should return a match for Nike shoes" do
      terms = Dissect.phraser('Nike shoes', items)
      matched = terms.select{|term|term[:terms] == 'Nike Shoes'}
      matched.should_not be_empty
    end

    it "should return a match for Apple" do
      terms = Dissect.phraser('Apple Macbook Pro', items)
      terms.each do |term|
        term[:terms].should == 'Apple Macbook Pro'
      end
    end

    it "should return a match for Apple" do
      terms = Dissect.phraser('Apples', items)
      terms.each do |term|
        term[:terms].should == 'Apples'
      end
    end

    it "should return a match for Merlot" do
      terms = Dissect.phraser('merlot', items)
      terms.each do |term|
        term[:terms].should == 'merlot'
      end
    end
  end
end
