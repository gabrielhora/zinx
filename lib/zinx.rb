require File.dirname(__FILE__) + '/sphinx/sphinx'

module Zinx

	class Client < Sphinx::Client

		class << self
			attr_reader :client, # Sphinx::Client instance
						:query, # Query text specified by the user
						:index_name, # Index name to run the query against
						:multiple_queries, # Boolean if needs to run more then one query (add_query)
						:field_weights, # Hash of field weights
						:index_weights, # Hash of index weights
						:results # Results from Sphinx

			def filter(field, value, exclude = false)
				@client.SetFilter(field, value.instance_of?(Array) ? value : [value], exclude)
			end

			def filter_range(field, min, max, exclude = false)
				@client.SetFilterRange(field, min, max, exclude)
			end

			def filter_float_range(field, min, max, exclude = false)
				@client.SetFilterFloatRange(field, min, max, exclude)
			end

			def sort(mode, value = '')
				@client.SetSortMode(mode, value)
			end

			def group(mode, value)
				@client.SetGroupBy(value, mode)
			end

			def group_distinct(field)
				@client.SetGroupDistinct(field)
			end

			def select(value)
				@client.SetSelect(value)
			end

			def last_error
				@client.GetLastError
			end

			def last_warning
				@client.GetLastWarning
			end

			def server(host, port)
				@client.SetServer(host, port)
			end

			def limits(offset, limit, max = 0, cutoff = 0)
				@client.SetLimits(offset, limit, max, cutoff)
			end

			def max_query_time(time)
				@client.SetMaxQueryTime(time)
			end

			def match_mode(mode)
				@client.SetMatchMode(mode)
			end

			def ranking_mode(mode)
				@client.SetRankingMode(mode)
			end

			def field_weight(field, weight)
				@field_weights[field] = weight
			end

			def field_weights(hash)
				@field_weights = hash
			end

			def index_weight(index, weight)
				@index_weights[index] = weight
			end

			def index_weights(hash)
				@index_weights = hash
			end

			def id_range(min, max)
				@client.SetIDRange(min, max)
			end

			def geo_anchor(attr_lat, attr_lng, lat, lng)
				@client.Set(attr_lat, attr_lng, lat, lng)
			end

			def retries(count, delay = 0)
				@client.SetRetries(count, delay)
			end

			def override(field, type, values)
				@client.SetOverride(field, type, values)
			end

			def reset
				@client.ResetFilters
				@client.ResetGroupBy
				@client.ResetOverrides
			end

			def reset_filters
				@client.ResetFilters
			end

			def reset_groups
				@client.ResetGroupBy
			end

			def reset_overrides
				@client.ResetOverrides
			end

			def build_excerpts(docs, index, words, opts = {})
				init
				@client.BuildExcerpts(docs, index, words, opts)
			end

			def excerpts(docs, words, opts = {})
				run if @results.empty?
				@client.BuildExcerpts(docs, @index_name, words, opts)
			end

			def build_keywords(query, index, hits)
				init
				@client.BuildKeywords(query, index, hits)
			end

			def update(index, attrs, values, mva = false)
				init
				@client.UpdateAttributes(index, attrs, values, mva)
			end

			def results
				run if @results.empty?
				@results
			end

			# syntax sugar for results[0].matches when using only one query
			# you don't even have to call 'run' before using this
			def matches
				run if @results.empty?
				!@multiple_queries && @results.count > 0 ? @results[0].matches : []
			end

			# must call run before accessing search results
			def run
				# set the weights
				@client.SetFieldWeights(@field_weights) unless @field_weights.empty?
				@client.SetIndexWeights(@index_weights) unless @index_weights.empty?

				# run the query
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
				reset
			end

			# Entry point for searches
			# Valid params are:
			# 	:server => Sphinx server address (defaults to 'localhost')
			#   :port => Sphinx port number (defaults to 9312)
			#   :match_mode => Sphinx matching mode (defaults to Zinx::SPH_MATCH_EXTENDED)
			#   :index_name => Name of the index to search on
			def search(query, params = {}, &block)
				params[:query] = query
				init(params)
				if !block_given?
					run
					return @results
				else
					yield
				end
			end

			def init(params = {})
				@client = Client.new
				@client.SetServer(params[:server] || 'localhost', params[:port] || 9312)
				@client.SetMatchMode(params[:match_mode] || Zinx::Client::SPH_MATCH_EXTENDED)
				@query = params[:query]
				@index_name = params[:index_name] || "*"
				@multiple_queries = false
				@results = []
				@field_weights = {}
				@index_weights = {}
			end
		end
	end

	class Match
		def initialize(hash)
			@match = hash
		end

		def each(&block)
			@match.each do |m|
				block.call m
			end
		end

		def method_missing(method)
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

		def method_missing(method)
			@sphinx_hash["#{method}"]
		end
	end

	module Search
		class << self
			attr_accessor :target

			def delegate(*methods)
				methods.each do |method|
					define_method(method) do |*args, &block|
						Search.target.send(method, *args, &block)
					end
					private method
				end
			end
		end

		self.target = Zinx::Client

		delegate :filter, :filter_range, :filter_float_range, :sort, :group, :group_distinct,
			:select, :last_error, :last_warning, :server, :limits, :max_query_time, :match_mode,
			:ranking_mode, :field_weight, :field_weights, :index_weight, :index_weights,
			:id_range, :geo_anchor, :retries, :override, :reset, :reset_filter, :reset_groups,
			:reset_overrides, :build_excerpts, :excerpts, :build_keywords, :update, :results,
			:matches, :run, :add_query, :search, :init
	end

end

extend Zinx::Search