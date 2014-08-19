require "dissect/version"
require 'active_support/all'
require "dissect/ngram"
require 'fuzzystringmatch'

module Dissect
  def self.phraser(sentence, items)
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
    items.each do |item|
      names = Set.new
      brand_names = item.has_key?(:brands) ? item[:brands].split(",").map(&:strip) : []
      modifiers = item.has_key?(:modifiers) ? item[:modifiers].split(",").map(&:strip) : []
      alternates = item.has_key?(:alternates) ? item[:alternates].split(",").map(&:strip) : []
      names = modified_names(item)
      brand_names.each do |brand_name|
        names += modified_names(item, brand_name)
      end
      phrazy = sentence
      names.each do |name|
        sentence, _terms = term_builder(sentence, name, jarow)
        if phrazy.length != sentence.length
          _terms = _terms.titleize
          _categories = item[:category]
          brand = brand_names.select{|bn|_terms.include?(bn)}
          results << { terms: _terms, item: item, brand: brand.first, category: _categories } unless _terms.blank?
          break if sentence.blank?
        end
      end
    end
    return results if sentence.blank?

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

  private
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
