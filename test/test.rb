require 'test/unit'
require 'zinx'

class ZinxTest < Test::Unit::TestCase
	def test_simple_search
		result = Zinx::Client.search 'something'
		assert result.count > 0, 'nothing returned from search'
		assert_equal result.first.error, ''
	end
end