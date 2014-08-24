require "dissect/version"
require 'active_support/all'
require "dissect/ngram"
require 'fuzzystringmatch'

module Dissect
  class Text
    attr_accessor :parent_key

    def initialize(parent_key = 'brands')
      self.parent_key = parent_key
    end

    def phraser(sentence, items)
      # preprocess the items
      items = items.select{|i|!(sentence.downcase.split & i[:name].downcase.split + splitter(i[:alternates]).map{|i|i.downcase}).empty? || !(sentence.downcase.split & splitter(i[:brands]).map{|b|b.downcase}).empty?}
      results = Set.new
      _categories = nil
      sentence.downcase! #Force downcase on string
      sentence = sentence.split(
      /\s*[,;]\s* # comma or semicolon, optionally surrounded by whitespace
      |           # or
      \s{2,}      # two or more whitespace characters
      |           # or
      [\r\n]+     # any number of newline characters
      /x).join(' ')
      jarow = FuzzyStringMatch::JaroWinkler.create(:pure)

      #t_start = Time.now
      phrazy = sentence
      items.each do |item|
        names = Set.new
        brand_names = splitter(item[parent_key.to_sym]) if item.key?(parent_key.to_sym)
        alternates = item.key?(:alternates) && !item[:alternates].blank? ? splitter(item[:alternates]) : []
        item_list = alternates.push(item[:name]) # Item name + alternatives/aliases
        names = modified_names(item)
        brand_names.each do |brand_name|
          names += modified_names(item, brand_name)
        end
        names = names.uniq.sort_by{|n|n.split(' ').size}.reverse
        names.each do |name|
          sentence, _terms = term_builder(sentence, name, jarow)
          if phrazy.length != sentence.length
            _terms = _terms.titleize
            _categories = item[:category]
            matched_brand = brand_names.select{|bn|_terms.include?(bn)}
            if !item_list.select{|il|phrazy.downcase.include?(il.downcase)}.empty? && !_terms.blank?
              results << { terms: _terms, item: item, brand: matched_brand.uniq.join(", "), category: _categories }
            end
          end
          break if sentence.blank?
        end
        break if sentence.blank?
        sentence = phrazy
      end
      #puts "Time is #{(Time.now - t_start)}"
      sentence = phrazy
      results.sort_by{|n|n[:terms].split(' ').size}.reverse.each do |result|
        sentence, _terms = term_builder(sentence, result[:terms], jarow)
        if _terms.blank?
          results.delete(result)
        end
      end
      return results if sentence.blank?

      sentence.split(" ").each do |word|
        results << { terms: word, brand: nil, category: 'Other'} unless ['and','the','a','of','an','some'].include?(word)
      end
      return results
    end

    def term_builder(sentence, word, jarow)
      terms = []
      word = word.upcase.strip
      size = sentence.split.size # 9
      (size).downto(1) do |i|
        ngram = Ngram.new(sentence)
        fragments = ngram.ngrams(i).map{|x|x.join(" ")}
        fragments.each do |fragment|
          if jarow.getDistance(fragment.upcase, word) > 0.99
            #puts "Score for #{sentence} is #{score} between ngram #{fragment} and phrase #{word}"
            terms << fragment.strip
            sentence = sentence.gsub(fragment,'')
          end
        end
      end
      return sentence, terms.join(", ")
    end

    private
      def modified_names(hash, b_name = nil)
        return if hash[:name].blank?
        names = [b_name, hash[:name]].compact
        names += names.permutation.to_a.map{|n|n.join(' ')}
        if hash.key?(:alternates)
          splitter(hash[:alternates]).each do |alt|
            names += [b_name, alt].compact.permutation.to_a.map{|n|n.join(" ")}
          end
        end
        if hash.key?(:modifiers)
          splitter(hash[:modifiers]).each do |modifier|
            names += [b_name, modifier, hash[:name]].compact.permutation.to_a.map{|n|n.join(" ")}
            if hash.key?(:alternates)
              splitter(hash[:alternates]).each do |alt|
                names += [b_name, modifier, alt].compact.permutation.to_a.map{|n|n.join(" ")}
              end
            end
          end
        end
        return names.sort_by{|n|n.split.size}.reverse
      end

      def splitter(line)
        line.blank? ? [] : lambda{|sl|sl.split(",").map{|l|l.strip}}.call(line)
      end
  end
end
