require "test_helper"

class Manageiq::SosTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Manageiq::Sos::VERSION
  end
end
