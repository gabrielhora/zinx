require 'test/unit'
require 'zinx'
require 'pp'
require 'zlib'

class ZinxTest < Test::Unit::TestCase
	def test_simple_search
		result = Zinx::Client.search 'something'
		assert result.status == 0, 'error in Sphinx'
		assert_equal result.error, ''
	end
end