PlainSearch
===========

[![Gem Version](https://badge.fury.io/rb/plain_search.svg)](https://badge.fury.io/rb/plain_search)
[![GitHub version](https://badge.fury.io/gh/polycaster%2Fplain_search.svg)](https://badge.fury.io/gh/polycaster%2Fplain_search)

PlainSearch is a simple, scored search plugin for single ActiveRecord 
models. Suited for small projects with little needs for scalability 
and a reserved attitude towards technical debt.

It has little complexity and is small in size, so you can read and comprehend
the code in a couple of minutes. 

If you are, however, looking for a scalable and high-performance solution, have 
a look at this projects instead:
 
 - [elasticsearch-rails](https://github.com/elastic/elasticsearch-rails)
 - [sunspot](https://github.com/sunspot/sunspot)

Requirements
------------
 - activerecord
 - MySQL
 
Obviously you'll need activerecord. I've tested with 4.2.4, but in principle it 
should work with older versions down to 2.x as well. After all, PlainSearch is 
basically a decorator around `#find_by_sql` and uses `#after_save` and 
`#attribute_changed?` to interact with the model. 


Quick Start
-----------

### Setup

Add the Gem to your Gemfile:

    gem 'plain_search'

Run `bundle install` to install it. 

You'll need a table for caching the search terms. Run the generator for
a new migration:

    rails g migration CreateSearchTerms
    
Put this into the migration file: 

    class CreateSearchTerms < ActiveRecord::Migration
        def change
            create_table :search_terms do |t|
                t.string :term, index: true
                t.string :source, index: true
                t.belongs_to :findable, polymorphic: true
            end
        end
    end

Apply the changes by running `rake db:migrate`.

At the moment the Gem doesn't provide the AR model for search terms (feel free 
to add it - pull requests appreciated). 
 
So you'll have to add it to you model. Create `app/model/search_term.rb` with
this content: 

    class SearchTerm < ActiveRecord::Base
      belongs_to :findable, polymorphic: true
    end

Having, for instance, a model `Employee` which has the attributes `first_name`,
`last_name`, `profession` and `address`, you can enable ranked searches like so:

    class Employee < ActiveRecord::Base
        searchable_by id: 100, first_name: 10, last_name: 10, profession: 5, address: 1
        # ...
    end
    
`searchable_by` receives a hash as only argument. Its keys determine the 
attributes to search. The hash's values determine the value contributed to the 
rank for a single match. In short: The higher the value, the higher the rank. 
See #Ranking for details.   

### Performing searches

Now, with all the setup done, performing a search is pretty straight-forward: 

    matches = Employee.search('susi sorglos 33602 hauptstrasse developer')
    
`matches` contains a list of `Employee`s, ordered by the search score, which is
also available as an attribute (e.q. `matches[0].score`).


Rebuilding search terms
-----------------------

In the background, whenever you create or update a model on which 
`searchable_by` was called, the searchable fields' contents will be cached in the 
`search_terms` table. This means pre-existent records won't appear in the 
search results because they have never hit the respective post-save callback. 
You'll have to rebuild the cache for this models manually using 
`#rebuild_search_terms_for_all` like so: 

    Employee.rebuild_search_terms_for_all
    
Alternatively there's also a Rake task for re-building the cache:   
    
    rake plain_search:rebuild_terms CLASS=Employee

Performing updates without caching search terms
-----------------------------------------------

Let's say you have a scenario which performs a lot of updates to a specific 
model. Every insertion or update would result in `SearchTerm`s being build for
the respective record. This can be very time consuming (keep in mind that
PlainSearch is not a high performance beast, but a mere solution for 
prototyping). 
 
To circumvent this you can call the insertions/updates inside a block passed
to `#without_search_term_updates`. Which simply suppresses the after_save 
callback which normally builds SearchTerms.
 
An example: 

    Employee.without_search_term_updates do 
     Employee.update_all({some_non_searchable_attribute: 42})
    end
 
Therefore changes to searchable attributes within this block won't be reflected 
in the search results. So you should make sure that you either rebuild the 
search terms afterwards (e.q. using ActiveJob) or make sure no searchable 
attributes have been touched in the operation. 

Alternatively you could set `Model#auto_update_search_terms` to `true`/`false`, 
which is basically what `#without_search_term_updates` does, but in a less 
error-prone manner.  

Search term delimiter
---------------------

Values of searchable attributes are split into search terms using a regular
expression. This is `/[^\w\u00C0-\u00ff]/` by default. You can adjust it
to fit your specific needs: 

    class Employee < ActiveRecord::Base
        searchable_by # ...
        search_terms_delimiter = /[\-.]/
        # ...
    end

Ranking
-------

Plain search facilitates a very simple ranking algorithm. 
Every attribute considered for search has a score assigned to it. This is the
score of a single match. The total score of a search result is the sum of the
score of all matches.

Here's an example: If we had an `Employee` with `first_name` being "Susi" and 
her `profession` being "Web developer", then (in the scenario above), a query 
for "susi web" would result in a total score of 15 for this record. That is 10 
for the matching first name and 5 for the matching profession. 

License
-------

PlainSearch is released under the [MIT License](MIT-LICENSE).
