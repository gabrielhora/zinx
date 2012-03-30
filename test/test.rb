require 'test/unit'
require 'zinx'

class ZinxTest < Test::Unit::TestCase
  def test_simple_search
    result = Zinx::Client.search 'something'
    assert result.status == 0, 'error in Sphinx'
    assert_equal result.error, ''
  end

  def test_stemming
  	assert_equal Zinx::Client.st('computer'), 'comput'
  end

  def test_crc
  	assert_equal Zinx::Client.crc('computer'), 2727913382
  end
end
