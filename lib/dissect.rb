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
      phrazy = sentence
      items.each do |item|
        t_start = Time.now
        names = Set.new
        brand_names = item.has_key?(parent_key.to_sym) && !item[parent_key.to_sym].blank? ? item[parent_key.to_sym].split(",").map(&:strip) : []
        alternates = item.has_key?(:alternates) && !item[:alternates].blank? ? item[:alternates].split(",").map(&:strip) : []
        item_list = alternates.push(item[:name]) # Item name + alternatives/aliases
        names = modified_names(item)
        brand_names.each do |brand_name|
          names += modified_names(item, brand_name)
        end
        names = names.uniq.sort_by{|n|n.split(' ').size}.reverse
        #item[:permutations] = names
        names.each do |name|
          sentence, _terms = term_builder(sentence, name, jarow)
          if phrazy.length != sentence.length
            _terms = _terms.titleize
            _categories = item[:category]
            matched_brand = brand_names.select{|bn|_terms.include?(bn)}
            if !item_list.select{|il|phrazy.include?(il)}.empty? && !_terms.blank?
              results << { terms: _terms, item: item, brand: matched_brand.uniq.join(", "), category: _categories }
            end
          end
          break if sentence.blank?
        end
        #puts "Time is #{(Time.now - t_start)}"
        break if sentence.blank?
        sentence = phrazy
      end
      sentence = phrazy
      results.sort_by{|n|n[:terms].split(' ').size}.reverse.each do |result|
        sentence, _terms = term_builder(sentence, result[:terms], jarow)
        if _terms.blank?
          results.delete(result)
        end
      end
      return results if sentence.blank?

      sentence.split(" ").each do |word|
        #results << { terms: word, brand: nil, category: other } unless ignore_words.include?(word)
        results << { terms: word, brand: nil, category: 'Other'} unless ['and','the','a','of','an','some'].include?(word)
      end
      return results
    end

    def term_builder(sentence, word, jarow)
      terms = []
      word = word.strip
      size = sentence.split.size # 9
      (size).downto(1) do |i|
        ngram = Ngram.new(sentence)
        fragments = ngram.ngrams(i).map{|x|x.join(" ")}
        fragments.each do |fragment|
          score = jarow.getDistance(fragment.upcase, word.upcase)
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
      def modified_names(hash, b_name = nil)
        return if hash[:name].blank?
        names = [b_name, hash[:name]].compact
        names += names.permutation.to_a.map{|n|n.join(' ')}
        if hash.has_key?(:modifiers) && !hash[:modifiers].blank?
          hash[:modifiers].split(",").map(&:strip).each do |modifier|
            combo_list = [b_name, modifier, hash[:name]].compact
            names += combo_list.permutation.to_a.map{|n|n.join(" ")}
            if hash.has_key?(:alternates)
              hash[:alternates].split(",").map(&:strip).each do |alt|
                names += [b_name, modifier, alt].compact.permutation.to_a.map{|n|n.join(" ")}
              end
            end
          end
        else
          if hash.has_key?(:alternates) && !hash[:alternates].blank?
            hash[:alternates].split(",").map(&:strip).each do |alt|
              names += [b_name, alt].compact.permutation.to_a.map{|n|n.join(" ")}
            end
          end
        end
        return names.sort_by{|n|n.split(' ').size}.reverse
      end
  end
end
