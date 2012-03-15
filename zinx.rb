require './lib/sphinx/sphinx'

class Match
	def initialize(hash)
		@match = hash
	end

	def each(&block)
		@match.each do |m|
			block.call m
		end
	end

	def method_missing(method, args = {})
		if ['groupby', 'count', 'expr'].include?("#{method}")
			@match["attrs"]["@#{method}"]
		elsif ['id', 'weight', 'attrs'].include?("#{method}")
			@match["#{method}"]
		else
			@match["attrs"]["#{method}"]
		end
	end
end

class Result
	attr_reader :matches

	def initialize(sphinx_hash)
		@matches = []
		@sphinx_hash = sphinx_hash
		@sphinx_hash["matches"].each do |match|
			@matches << Match.new(match)
		end
	end
end

class Zinx < Sphinx::Client
end

class << self
	attr_reader :client, # Sphinx::Client instance
				:query, # Query text specified by the user
				:index_name, # Index name to run the query against
				:multiple_queries, # Boolean if needs to run more then one query (add_query)
				:results # Results from Sphinx

	def filter(field, value)
		@client.SetFilter(field, value.instance_of?(Array) ? value : [value])
	end

	def sort(mode, value)
		@client.SetSortMode(mode, value)
	end

	def group(mode, value)
		@client.SetGroupBy(value, mode)
	end

	def select(value)
		@client.SetSelect(value)
	end

	# syntax sugar for results[0].matches when using only one query
	# you don't even have to call 'run' before using this
	def matches
		run if @results.empty?
		@results.count == 1 ? @results[0].matches : []
	end

	# must call run before accessing search results
	def run
		if @multiple_queries
			q = @client.RunQueries
			q.each do |result|
				@results << Result.new(result)
			end
		else
			q = @client.Query(@query, @index_name)
			@results << Result.new(q)
		end
	end

	# add query for multiple queries
	def add_query
		@multiple_queries = true
		@client.AddQuery(@query, @index_name)
		@client.ResetFilters; @client.ResetGroupBy; @client.ResetOverrides
	end

	# Entry point for searches
	# Valid params are:
	# 	:server => Sphinx server address (defaults to 'localhost')
	#   :port => Sphinx port number (defaults to 9312)
	#   :match_mode => Sphinx matching mode (defaults to Zinx::SPH_MATCH_EXTENDED)
	def search(query, params = {}, &block)
		@client = Sphinx::Client.new
		@client.SetServer(params[:server] || 'localhost', params[:port] || 9312)
		@client.SetMatchMode(params[:match_mode] || Sphinx::Client::SPH_MATCH_EXTENDED)
		@query = query
		@index_name = params[:index_name] || "*"
		@multiple_queries = false
		@results = []
		block.call
	end
end