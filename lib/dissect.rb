require "dissect/version"
require 'active_support/all'
require "dissect/ngram"
require 'fuzzystringmatch'

module Dissect
  def self.phraser(sentence, brands, items)
    results = Set.new
    _categories = nil
    sentence = sentence.downcase #Force downcase on string
    sentence = sentence.split(
    /\s*[,;]\s* # comma or semicolon, optionally surrounded by whitespace
    |           # or
    \s{2,}      # two or more whitespace characters
    |           # or
    [\r\n]+     # any number of newline characters
    /x).join(' ')
    jarow = FuzzyStringMatch::JaroWinkler.create(:pure)
    brands.each do |brand|
      _categories = brand[:categories]
      next if brand[:name].blank?
      brand_names = brand[:name].split(",").map(&:strip)
      if brand.has_key?(:alternates)
        brand[:alternates].split(",").map(&:strip).each do |alt|
          brand_names << alt
        end
      end
      brand_names.each do |b_name|
        phrazy = sentence
        sentence, _terms = term_builder(sentence, b_name, jarow)
        if phrazy.length != sentence.length
          sentence = phrazy
          _item = nil
          brand_items = items.select{|i|i[:brands].include?(b_name)}
          brand_items.each do |item|
            modified_names(item, b_name).each do |name|
              sentence, matched_term = term_builder(sentence, name, jarow)
              unless matched_term.blank?
                _terms = matched_term
                _item = item
              end
              _categories = item[:category] unless item[:category].blank?
            end
          end
          _item = brand_items.first if _item.nil? && !brand_items.empty?
          _terms = _terms.titleize #Properly titleize brand names
          results << { terms: _terms, item: _item, brand: brand, category: _categories }
        end
      end
      sentence, _terms = term_builder(sentence, brand[:name], jarow)
      puts "Terms are #{_terms}"
      break if _terms.blank? && sentence.blank?
    end
    return results if sentence.blank?
    items.each do |item|
      item_names = item[:name].split(',').map(&:strip)
      item_names.each do |item_name|
        sentence, _terms = term_builder(sentence, item_name, jarow)
        #debugger if _terms.include? 'Meat'

        if _terms.downcase.include?(item_name.downcase)
          item = items.select{|i|i if i[:name].split(',').map(&:strip).include?(item_name)}.first
          results << { terms: _terms, item: item, brand: nil, category: item[:category] }
        end
        if sentence.blank? && results.empty?
          item = items.select{|i|i if i[:name].split(',').map(&:strip).include?(item_name)}.first
          results << { terms: _terms, item: item, brand: nil, category: item[:category] }
        end
        return results if sentence.blank?
      end
      #ignore_words = BLACKLIST[:ignore_words].split(',').map(&:strip)
      #ignore_words += BLACKLIST[:curse_words].split(',').map(&:strip)
    end

    sentence.split(" ").each do |word|
      #results << { terms: word, brand: nil, category: other } unless ignore_words.include?(word)
      results << { terms: word, brand: nil, category: 'Other'} unless ['and','the','a','of','an','some'].include?(word)
    end
    return results
  end

  def self.term_builder(sentence, word, jarow)
    terms = []
    word = word.strip
    size = sentence.split.size # 9
    (size).downto(1) do |i|
      ngram = Ngram.new(sentence)
      fragments = ngram.ngrams(i).map{|x|x.join(" ")}
      fragments.each do |fragment|
        score = jarow.getDistance(fragment.upcase, word.upcase)
        #debugger if fragment == 'bell pepper' && word.include?('bell pepper')
        if score > 0.989
          puts "Score for #{sentence} is #{score} between ngram #{fragment} and phrase #{word}"
          terms << fragment.strip
          sentence = sentence.gsub(fragment,'')
        end
      end
    end
    return sentence, terms.join(", ")
  end

  def self.modified_names(hash, b_name = nil)
    names = [b_name, hash[:name]].compact
    return names.permutation.to_a.map{|n|n.join(' ')} if hash[:modifiers].blank?
    hash[:modifiers].split(",").map(&:strip).each do |modifier|
      combo_list = [b_name, modifier, hash[:name]].compact
      names += combo_list.permutation.to_a.map{|n|n.join(" ")}
      if hash.has_key?(:alternates)
        hash[:alternates].split(",").map(&:strip).each do |alt|
          names += [b_name, modifier, alt].compact.permutation.to_a.map{|n|n.join(" ")}
        end
      end
    end
    return names.sort_by{|n|n.split(' ').size}.reverse
  end

end
