require "test_helper"
require 'pry'

class TwoFerTest < Minitest::Test

  def test_fixtures
    #skip
    dir = File.expand_path("#{__FILE__}/../../fixtures/two-fer/")
    Dir.foreach(dir).each do |id|
      next if id == "." || id == ".."
      next unless File.exist?("#{dir}/#{id}/analysis.json")

      expected = TwoFer::Analyze.(File.read("#{dir}/#{id}/two_fer.rb"))
      actual = JSON.parse(File.read("#{dir}/#{id}/analysis.json"))

      assert_equal expected[:status].to_s, actual['status']
      assert_equal expected[:comments], actual['comments']
    end
  end

  # ###
  # Test the module/class
  # ###
  def test_simple_class_passes
    #skip
    source = %q{
      class TwoFer
        def self.two_fer(name="you")
          "One for #{name}, one for me."
        end
      end
    }
    results = TwoFer::Analyze.(source)
    assert_equal :approve_as_optimal, results[:status]
    assert_equal [], results[:comments]
  end

  def test_simple_module_passes
    #skip
    source = %q{
      module TwoFer
        def self.two_fer(name="you")
          "One for #{name}, one for me."
        end
      end
    }
    results = TwoFer::Analyze.(source)
    assert_equal :approve_as_optimal, results[:status]
    assert_equal [], results[:comments]
  end

  def test_simple_module_with_bookkeeping_passes
    #skip
    source = %q{
      module TwoFer
        def self.two_fer(name="you")
          "One for #{name}, one for me."
        end
      end

      module Bookkeeping
        VERSION = 10
      end
    }
    results = TwoFer::Analyze.(source)
    assert_equal :approve_as_optimal, results[:status]
    assert_equal [], results[:comments]
  end

  def test_different_module_name_fails
    #skip
    source = %q{
      module SomethingElse
        def self.two_fer(name="you")
          "One for #{name}, one for me."
        end
      end
    }
    results = TwoFer::Analyze.(source)
    assert_equal :disapprove_with_comment, results[:status]
    assert_equal ["ruby.general.no_target_module"], results[:comments]
  end

  # ###
  # Test the method exists and is correctly structured
  # ###

  def test_different_method_value_fails
    #skip
    source = %q{
      module TwoFer
        def self.foobar(name="you")
          "One for #{name}, one for me."
        end
      end
    }
    results = TwoFer::Analyze.(source)
    assert_equal :disapprove_with_comment, results[:status]
    assert_equal ["ruby.general.no_target_method"], results[:comments]
  end

  def test_missing_param
    #skip
    source = %q{
      module TwoFer
        def self.two_fer
          "One for #{name}, one for me."
        end
      end
    }
    results = TwoFer::Analyze.(source)
    assert_equal :disapprove_with_comment, results[:status]
    assert_equal ["ruby.two_fer.missing_default_param"], results[:comments]
  end

  def test_missing_default_value_fails
    #skip
    source = %q{
      module TwoFer
        def self.two_fer(name)
          "One for #{name}, one for me."
        end
      end
    }
    results = TwoFer::Analyze.(source)
    assert_equal :disapprove_with_comment, results[:status]
    assert_equal ["ruby.two_fer.missing_default_param"], results[:comments]
  end

  def test_splat_fails
    #skip
    source = %q{
      module TwoFer
        def self.two_fer(*foos)
          "One for #{name}, one for me."
        end
      end
    }
    results = TwoFer::Analyze.(source)
    assert_equal :disapprove_with_comment, results[:status]
    assert_equal [["ruby.two_fer.splat_args", :foos]], results[:comments]
  end

  # ### 
  # Now let's guard against string building
  # ###
  def test_for_string_building
    #skip
    source = %q{
      class TwoFer
        def self.two_fer(name="you")
          "One for " + name + ", one for me."
        end
      end
    }
    results = TwoFer::Analyze.(source)
    assert_equal :approve_with_comment, results[:status]
    assert_equal ["ruby.two_fer.avoid_string_building"], results[:comments]
  end

  def test_for_kernel_format
    #skip
    source = %q{
      class TwoFer
        def self.two_fer(name="you")
          format("One for %s, one for me.", name)
        end
      end
    }
    results = TwoFer::Analyze.(source)
    assert_equal :approve_with_comment, results[:status]
    assert_equal ["ruby.two_fer.avoid_kernel_format"], results[:comments]
  end

  def test_for_string_format
    #skip
    source = %q{
      class TwoFer
        def self.two_fer(name="you")
          "One for %s, one for me." % name
        end
      end
    }
    results = TwoFer::Analyze.(source)
    assert_equal :approve_with_comment, results[:status]
    assert_equal ["ruby.two_fer.avoid_string_format"], results[:comments]
  end

  def test_conditional_with_nil
    #skip
    source = %q{
      module TwoFer
        def self.two_fer(name=nil)
          if name == nil
            "One for you, one for me."
          else
            "One for #{name}, one for me."
          end
        end
      end
    }
    results = TwoFer::Analyze.(source)
    assert_equal :disapprove_with_comment, results[:status]
    assert_equal ["ruby.two_fer.incorrect_default_param"], results[:comments]
  end

  def test_conditional_with_nil_reversed
    #skip
    source = %q{
      module TwoFer
        def self.two_fer(name=nil)
          if nil == name
            "One for you, one for me."
          else
            "One for #{name}, one for me."
          end
        end
      end
    }
    results = TwoFer::Analyze.(source)
    assert_equal :disapprove_with_comment, results[:status]
    assert_equal ["ruby.two_fer.incorrect_default_param"], results[:comments]
  end

  def test_conditional_with_string
    #skip
    source = %q{
      module TwoFer
        def self.two_fer(name='dog')
          if name == 'dog'
            "One for you, one for me."
          else
            "One for #{name}, one for me."
          end
        end
      end
    }
    results = TwoFer::Analyze.(source)
    assert_equal :disapprove_with_comment, results[:status]
    assert_equal ["ruby.two_fer.incorrect_default_param"], results[:comments]
  end

  def test_unknown_solution
    #skip
    source = %q{
      module TwoFer
        def self.two_fer(name=nil)
          I.have.no.idea.what.this.is
        end
      end
    }
    results = TwoFer::Analyze.(source)
    assert_equal :refer_to_mentor, results[:status]
    assert_equal [], results[:comments]
  end

  [%q{
    class TwoFer
      def self.two_fer(name="you")
          "One for %s, one for me." % name
      end
    end
  }, %q{
      class TwoFer
      def self.two_fer(name="you")
          "One for %s, one for me." % name
      end
    end
  }, %q{
    class TwoFer
      def self.two_fer(name="you")
        "One for %s, one for me." % name
     end
    end
  }].each.with_index do |source, idx|
    define_method "test_incorrect_indentation_#{idx}" do
      ##skip
      results = TwoFer::Analyze.(source)
      assert_equal :disapprove_with_comment, results[:status]
      assert_equal ["ruby.general.incorrect_indentation"], results[:comments]
    end
  end
end

# Explicit return
=begin
class TwoFer
  def self.two_fer(name="you")
    return "One for #{name}, one for me."
  end
end
=end

# Use of premature return
=begin
class TwoFer
  class << self
    def two_fer(name = "")
      return "One for you, one for me." if name.empty?
      "One for #{name}, one for me."
    end
  end
end
=end
