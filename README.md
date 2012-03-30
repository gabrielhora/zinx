# Zinx

Zinx is a Ruby DSL for the [Sphinx Search Engine](http://www.sphinxsearch.com) (which is used in a lot of [big sites](http://sphinxsearch.com/info/powered/)). It is a simple wrapper around the oficial Ruby API.
The main goal is to have a more friendly way of searching Sphinx.

Most methods are just a wrap around the corresponding Sphinx API method. Best thing to do is to read the code, it's quite simple.

---

## Install

	gem install zinx

## Examples

### Configuring

	match_mode :extended
	ranking_mode :word_count
	field_weight 'field1', 1000
	field_weights {'field1' => 1000, 'field2' => 50}
	index_weight 'index1', 400
	index_weights {'index2' => 100, 'index3' => 231}

### Simple Search

	results = search 'simple'

### Filtering

	results = search 'simple', :filter => {'field': 'value'}
	# or
	results = search 'simple' do
		filter 'field', 'value'
	end

### Sorting

	results = search 'simple', :sort => {:expr: '@weight + 10'}
	# or
	results = search 'simple' do
		sort :expr, '@weight + 10'
	end

### Grouping

	results = search 'simple', :group => {:attr: 'field'}
	# or
	results = search 'simple' do
		group :attr, 'field'
	end

### Select List

	results = search 'simple', :select => 'field1, field2, field3'
	# or
	results = search 'simple' do
		select 'field1, field2, field3'
	end

### Multiple Queries

	# this will return an array of 3 results
	results = search 'simple' do
		filter 'field', 'value'
		sort :expr, '@weight + 10'
		add_query

		filter 'field2', 'value2'
		group :attr, 'field2'
		add_query

		reset_groups
		select 'SUM(1) AS total'
		group :attr, 'total'
		add_query
	end

### Accessing Result Information

	results = search 'simple', :select => 'field1, field2, @weight'
	# error?
	puts results.first.error
	# matches
	puts results.matches
	# accessig fields
	puts results.matches.first.field1
	puts results.matches.first.weight