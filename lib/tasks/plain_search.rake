namespace :plain_search do

  desc "Clear and rebuild search terms for a given model class"
  task rebuild: :environment do

    class_name = ENV['CLASS']

    abort('Usage: rake plain_search:rebuild_terms CLASS=MySearchableModel') if class_name.blank?

    klass = Object.const_get(class_name)

    raise "Plain Search is not enabled on model #{class_name}" unless klass.searchable?

    puts "Rebuilding search terms for model #{class_name}..."
    klass.rebuild_search_terms_for_all
    puts "Done."
  end

end
