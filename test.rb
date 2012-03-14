require './zinx'
require 'awesome_print'

search 'nike|puma', :index_name => 'marcas' do

	filter 'loja_id', 1
	sort Sphinx::Client::SPH_SORT_EXPR, '@weight + codigo'
	group Sphinx::Client::SPH_GROUPBY_ATTR, 'loja_id'

	ap matches
	
end