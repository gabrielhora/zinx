require File.dirname(__FILE__) + '/sphinx/sphinx'
require 'lingua/stemmer'
require 'zlib'

module Zinx
  class Client < Sphinx::Client
    @config = {
      # Known searchd commands
      :search => Sphinx::Client::SEARCHD_COMMAND_SEARCH,
      :excerpt => Sphinx::Client::SEARCHD_COMMAND_EXCERPT,
      :update => Sphinx::Client::SEARCHD_COMMAND_UPDATE,
      :keywords => Sphinx::Client::SEARCHD_COMMAND_KEYWORDS,

      # Current client-side command implementation versions
      :version_search => Sphinx::Client::VER_COMMAND_SEARCH,
      :version_excerpt => Sphinx::Client::VER_COMMAND_EXCERPT,
      :version_update => Sphinx::Client::VER_COMMAND_UPDATE,
      :version_keywords => Sphinx::Client::VER_COMMAND_KEYWORDS,

      # Known searchd status codes
      :ok => Sphinx::Client::SEARCHD_OK,
      :error => Sphinx::Client::SEARCHD_ERROR,
      :retry => Sphinx::Client::SEARCHD_RETRY,
      :warning => Sphinx::Client::SEARCHD_WARNING,

      # Known match modes
      :all => Sphinx::Client::SPH_MATCH_ALL,
      :any => Sphinx::Client::SPH_MATCH_ANY,
      :phrase => Sphinx::Client::SPH_MATCH_PHRASE,
      :boolean => Sphinx::Client::SPH_MATCH_BOOLEAN,
      :extended => Sphinx::Client::SPH_MATCH_EXTENDED,
      :fullscan => Sphinx::Client::SPH_MATCH_FULLSCAN,
      :extended2 => Sphinx::Client::SPH_MATCH_EXTENDED2,

      # Known ranking modes (ext2 only)
      :proximity_bm25 => Sphinx::Client::SPH_RANK_PROXIMITY_BM25,
      :bm25 => Sphinx::Client::SPH_RANK_BM25,
      :none => Sphinx::Client::SPH_RANK_NONE,
      :word_count => Sphinx::Client::SPH_RANK_WORDCOUNT,
      :proximity => Sphinx::Client::SPH_RANK_PROXIMITY,

      # Known sort modes
      :relevance => Sphinx::Client::SPH_SORT_RELEVANCE,
      :attr_desc => Sphinx::Client::SPH_SORT_ATTR_DESC,
      :attr_asc => Sphinx::Client::SPH_SORT_ATTR_ASC,
      :time_segments => Sphinx::Client::SPH_SORT_TIME_SEGMENTS,
      :expr => Sphinx::Client::SPH_SORT_EXPR,

      # Known filter types
      :values => Sphinx::Client::SPH_FILTER_VALUES,
      :range => Sphinx::Client::SPH_FILTER_RANGE,
      :float_range => Sphinx::Client::SPH_FILTER_FLOATRANGE,

      # Known attribute types
      :integer => Sphinx::Client::SPH_ATTR_INTEGER,
      :timestamp => Sphinx::Client::SPH_ATTR_TIMESTAMP,
      :ordinal => Sphinx::Client::SPH_ATTR_ORDINAL,
      :bool => Sphinx::Client::SPH_ATTR_BOOL,
      :float => Sphinx::Client::SPH_ATTR_FLOAT,
      :bigint => Sphinx::Client::SPH_ATTR_BIGINT,
      :string => Sphinx::Client::SPH_ATTR_STRING,
      :multi => Sphinx::Client::SPH_ATTR_MULTI,
      :multi64 => Sphinx::Client::SPH_ATTR_MULTI64,

      # Known grouping functions
      :day => Sphinx::Client::SPH_GROUPBY_DAY,
      :week => Sphinx::Client::SPH_GROUPBY_WEEK,
      :month => Sphinx::Client::SPH_GROUPBY_MONTH,
      :year => Sphinx::Client::SPH_GROUPBY_YEAR,
      :attr => Sphinx::Client::SPH_GROUPBY_ATTR,
      :attr_pair => Sphinx::Client::SPH_GROUPBY_ATTRPAIR
    }

    attr_reader :client, # Sphinx::Client instance
    :query, # Query text specified by the user
    :index, # Index name to run the query against
    :multiple_queries, # Boolean if needs to run more then one query (add_query)
    :field_weights, # Hash of field weights
    :index_weights, # Hash of index weights
    :results, # Results from Sphinx
    :current_match_mode,
    :current_ranking_mode

    class << self
      # Utility methods

      # Stem all words in text (removing accent and special characters)
      def st(words, language="en", encoding="utf-8")
        stemmer = Lingua::Stemmer.new(:language => language, :encoding => encoding)
        result = ""
        words.downcase.gsub(/[^a-z ]/, '').strip.split(" ").each do |w|
          result += stemmer.stem(w.strip) + " "
        end
        return result.strip
      end

      # Apply CRC32 function to text
      def crc(text)
        Zlib::crc32(text)
      end

      # Search methods
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
        @client.SetSortMode(@config[mode], value)
      end

      def group(mode, value)
        @client.SetGroupBy(value, @config[mode])
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
        @current_match_mode = @config[mode]
      end

      def ranking_mode(mode)
        @current_ranking_mode = @config[mode]
      end

      def field_weight(field, weight)
        @field_weights[field] = weight
      end

      def field_weights(hash)
        hash.each do |k, v|
          @field_weights[k] = v
        end
      end

      def index_weight(index, weight)
        @index_weights[index] = weight
      end

      def index_weights(hash)
        hash.each do |k, v|
          @index_weights[k] = v
        end
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
        @client.BuildExcerpts(docs, @index, words, opts)
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

        # set modes
        @client.SetMatchMode(@current_match_mode) unless @current_match_mode.nil?
        @client.SetRankingMode(@current_ranking_mode) unless @current_ranking_mode.nil?

        # run the query
        if @multiple_queries
          q = @client.RunQueries
          q.each do |result|
            @results << Result.new(result)
          end
          @results
        else
          q = @client.Query(@query, @index)
          @results << Result.new(q)
          @results.first
        end
      end

      # add query for multiple queries
      def add_query
        @multiple_queries = true
        @client.AddQuery(@query, @index)
      end

      # Entry point for searches
      # Valid params are:
      #   :server => Sphinx server address (defaults to 'localhost')
      #   :port => Sphinx port number (defaults to 9312)
      #   :match_mode => Sphinx matching mode (defaults to Zinx::SPH_MATCH_EXTENDED)
      #   :index => Name of the index to search on
      def search(query, params = {}, &block)
        params[:query] = query
        init(params)
        yield self if block_given?
        run
      end

      def init(params = {})
        @client = Client.new
        @client.SetServer(params[:server] || 'localhost', params[:port] || 9312)
        @query = params[:query]
        @index = params[:index] || "*"
        if params.has_key?("filter")
          params[:filter].each do |field, value|
            filter(field, value, value[:exclude] || false)
          end
        end
        if params.has_key?("sort")
          params[:sort].each do |mode, value|
            sort(mode, value)
          end
        end
        if params.has_key?("group")
          params[:group].each do |mode, value|
            group(mode, value)
          end
        end
        select(params[:select]) if params.has_key?("select")
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

    def each
      @match.each do |m|
        yield m
      end
    end

    def method_missing(method, *args, &block)
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
      if @sphinx_hash.has_key?("matches")
        @sphinx_hash["matches"].each do |match|
          @matches << Match.new(match)
        end
      end
    end

    def method_missing(method, *args, &block)
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
