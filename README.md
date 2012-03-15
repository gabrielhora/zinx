# Zinx

Zinx is a Ruby DSL for the [Sphinx Search Engine](http://www.sphinxsearch.com) (which is used in a lot of [big sites](http://sphinxsearch.com/info/powered/)). It is a simple wrapper around the oficial Ruby API.
The main goal is to have a more friendly way of searching Sphinx.

---

## How?

### Old Way (oficial Ruby API)

	sph = Sphinx::Client.new
	sph.SetFilter("some_filter", [1])
	sph.SetFilter("some_other_filter", ['bla bla bla'])
	sph.SetSortMode(Sphinx::Client::SPH_SORT_EXPR, "@weight + relevant_column")
	sph.SetGroupBy("some_mva", Sphinx::Client::SPH_GROUPBY_ATTR)
	sph.SetSelect("@groupby, @count")
	results = sph.Query('my query', "*")

### Better Way (using Zinx)

	search 'my query' do
		filter 'some_filter', 1
		filter 'some_other_filter', 'bla bla bla'
		sort Sphinx::Client::SPH_SORT_EXPR, '@weight + relevant_column'
		group Sphinx::Client::SPH_GROUPBY_ATTR, 'some_mva'
		select '@groupby, @count'
		matches # this is the result of running the query
	end

---

I'm building a simple Wiki with more examples, but for now the source code and [email](gabrielhora@gmail.com) are the best ways to find help.

This is a very new project, and in NO WAY done. For now is just something that I did in my time off.