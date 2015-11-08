module PlainSearch
  class Railtie < Rails::Railtie

    initializer 'plain_search.extend_active_record_base' do
      ActiveRecord::Base.send(:include, PlainSearch)
    end

    rake_tasks do
      load "tasks/plain_search.rake"
    end

  end
end
