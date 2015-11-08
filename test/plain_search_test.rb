require 'test_helper'

class PlainSearchTest < ActiveSupport::TestCase

  def setup

    @acme = Company.create!(name: 'ACME')
    @initec = Company.create!(name: 'IniTec')

    @andreas = Employee.create!(
      company: @acme,
      first_name: 'Andreas',
      last_name: 'Baumgart',
      address: 'Adalbertstr. 8',
      zip_code: '10999',
      city: 'Berlin',
      phone: '00491731234567',
      email: 'andreas@polycast.de',
      profession: 'Web Developer',
    )

    @oskar = Employee.create!(
      company: @acme,
      first_name: 'Oskar',
      last_name: 'Entenweich',
      address: 'Hauptstrasse 10',
      zip_code: '33602',
      city: 'Bielefeld',
      phone: '00491791234501',
      email: 'oskar@polycast.de',
      profession: 'Visual Artist',
    )

    @sebastian = Employee.create!(
      company: @initec,
      first_name: 'Sebastian',
      last_name: 'Sorglos',
      address: 'Auf dem Holzweg 1',
      zip_code: '33602',
      city: 'Bielefeld',
      phone: '00491791234501',
      email: 'oskar@polycast.de',
      profession: 'Administrator',
    )

    @susi = Employee.create!(
      company: @initec,
      first_name: 'Susi',
      last_name: 'Sorglos',
      address: 'Hauptstrasse 10',
      zip_code: '33602',
      city: 'Bielefeld',
      phone: '00491791234502',
      email: 'oskar@polycast.de',
      profession: 'Mobile Developer',
    )

    @dossier_1 = Dossier.create!(filename: 'susi-cv.pdf')
    @dossier_2 = Dossier.create!(filename: 'susi-portfolio.pdf')
    @dossier_3 = Dossier.create!(filename: 'sebastian.pdf')
    @dossier_4 = Dossier.create!(filename: 'oskar-cv.doc')
    @dossier_5 = Dossier.create!(filename: 'andreas-cv.doc')
    @dossier_6 = Dossier.create!(filename: 'oskar-portfolio.doc')

  end

  def test_by_example

    Employee.searchable_by company_name: 50, first_name: 10, last_name: 10, profession: 5, address: 1, zip_code: 1, city: 1
    Employee.rebuild_search_terms_for_all

    assert Employee.searchable_attributes.present?

    results = Employee.search('susi sorglos 33602 hauptstrasse developer')

    # first_name: 10
    # last_name: 10
    # profession: 5
    # zip_code: 1
    # address: 1
    # -----------
    # total: 27
    assert_equal results[0], @susi
    assert_equal 27, results[0].score

    # last_name: 10
    # zip_code: 1
    # -----------
    # total: 11
    assert_equal results[1], @sebastian
    assert_equal 11, results[1].score

    # profession: 5
    # -----------
    # total: 5
    assert_equal results[2], @andreas
    assert_equal 5, results[2].score

    # address: 1
    # zip_code: 1
    # -----------
    # total: 2
    assert_equal results[3], @oskar
    assert_equal 2, results[3].score


    Dossier.searchable_by :filename
    Dossier.rebuild_search_terms_for_all
    Dossier.search_terms_delimiter = /[\-.]/

    results = Dossier.search('susi portfolio pdf')

    assert_equal results.size, 4
    assert_equal results[0], @dossier_2
    assert_equal results[1], @dossier_1
    assert_equal results[2], @dossier_3
    assert_equal results[3], @dossier_6

    results = Employee.search('susi initec')
    assert_equal results.size, 2

    # company_name: 50
    # first_name: 10
    # -----------
    # total: 60
    assert_equal results[0], @susi
    assert_equal 60, results[0].score

    # company_name: 50
    # -----------
    # total: 50
    assert_equal results[1], @sebastian
    assert_equal 50, results[1].score

  end
end
