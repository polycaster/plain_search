module PlainSearch

  extend ActiveSupport::Concern

  included do

    def clear_search_terms_for(attributes)
      search_terms.where(source: attributes).delete_all
    end

    def changed_searchable_attributes
      self.class.searchable_attributes.select do |attribute_name|
        if has_attribute? attribute_name
          attribute_changed? attribute_name
        else
          true # not all attributes map to DB columns and support *_changed?
        end
      end
    end

    def rebuild_search_terms
      self.class.transaction do
        clear_search_terms_for(self.class.searchable_attributes)
        create_search_terms_for(self.class.searchable_attributes)
      end
    end

    def create_search_terms_for(attributes)
      self.class.transaction do
        Array.wrap(attributes).each do |attr_name|
          attr_value = send(attr_name)
          self.class.tokenize_search_terms(attr_value).each do |term|
            SearchTerm.create!(findable: self, term: term, source: attr_name)
          end
        end
      end
    end

  end

  class_methods do

    def auto_update_search_terms?
      !!auto_update_search_terms
    end

    def searchable?
      searchable_attributes.present? and searchable_attributes.any?
    end

    def without_search_term_updates
      orig_value = self.auto_update_search_terms
      begin
        self.auto_update_search_terms = false
        yield if block_given?
      ensure
        self.auto_update_search_terms = orig_value
      end
    end

    def searchable_by(*attributes)

      has_many :search_terms, as: :findable

      cattr_accessor :searchable_attributes
      cattr_accessor :searchable_attribute_scores

      cattr_accessor :auto_update_search_terms
      self.auto_update_search_terms = true

      cattr_accessor :search_terms_delimiter

      # Add latin-1 umlauts to word characters.
      # Add more if you must.
      self.search_terms_delimiter = /[^\w\u00C0-\u00ff]/

      delegate :searchable?, to: :class
      delegate :auto_update_search_terms, to: :class
      delegate :auto_update_search_terms?, to: :class

      if attributes.size == 1 and attributes[0].is_a? Hash
        # searchable_by attr1: 5, attr2: 1, ...
        self.searchable_attribute_scores = attributes[0]
        self.searchable_attributes = attributes[0].keys
      else
        # searchable_by :attr1, :attr2, ...
        self.searchable_attribute_scores = nil
        self.searchable_attributes = attributes
      end

      after_save do
        if searchable? and auto_update_search_terms?
          attribs = changed_searchable_attributes
          clear_search_terms_for(attribs)
          create_search_terms_for(attribs)
        end
      end

    end

    def tokenize_search_terms(value)
      value.to_s.gsub(search_terms_delimiter, ' ').gsub(/\s+/, ' ').split(' ')
    end

    def rebuild_search_terms_for_all
      self.transaction do
        SearchTerm.where("findable_type = '#{self.name}'").delete_all
        all.each do |record|
          record.create_search_terms_for(self.searchable_attributes)
        end
      end
    end

    def search(query)

      return none if searchable_attributes.empty?

      terms = tokenize_search_terms(query)
      return none if terms.empty?

      if score_search?
        perform_scored_search(terms)
      else
        perform_unscored_search(terms)
      end

    end

    def score_search?
      not searchable_attribute_scores.nil?
    end

    private

    def search_conditions_for_terms(terms)
      quoted_terms = terms.collect do |t|
        ActiveRecord::Base.connection.quote("#{t}%")
      end
      quoted_terms.collect do |quoted_term|
        "#{SearchTerm.table_name}.term LIKE #{quoted_term}"
      end
    end

    def perform_scored_search(terms)
      conditions = search_conditions_for_terms(terms)

      score_statement = searchable_attributes.collect do |attr_name|
        "WHEN search_terms.source = '#{attr_name}' then #{searchable_attribute_scores[attr_name]}"
      end.join("\n           ")

      find_by_sql <<-SQL
        SELECT SUM(e1.match_score) AS score, e1.*
        FROM (
          SELECT
           CASE
           #{score_statement}
           ELSE 0
           END AS match_score,
           #{table_name}.*
          FROM #{table_name}
          JOIN #{SearchTerm.table_name}
            ON #{SearchTerm.table_name}.findable_id = #{table_name}.id
            AND #{SearchTerm.table_name}.findable_type = '#{self.name}'
          WHERE #{conditions.join(' OR ')}
          ) AS e1
        GROUP BY e1.id
        ORDER BY score DESC
      SQL
    end

    def perform_unscored_search(terms)
      conditions = search_conditions_for_terms(terms)
      find_by_sql <<-SQL
        SELECT #{table_name}.*, COUNT(#{SearchTerm.table_name}.id) as hits
        FROM #{table_name}
        JOIN #{SearchTerm.table_name}
          ON #{SearchTerm.table_name}.findable_id = #{table_name}.id
          AND #{SearchTerm.table_name}.findable_type = '#{self.name}'
        WHERE #{conditions.join(' OR ')}
        GROUP BY #{table_name}.id
        ORDER BY hits DESC
      SQL
    end
  end

end