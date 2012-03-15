# encoding: utf-8

Gem::Specification.new do |s|
	s.rubygems_version = '1.8.19'

	s.name = 'zinx'
	s.summary = 'Simple DSL for Sphinx Search Server'
	s.version = '0.0.2'
	s.date = '2012-03-15'
	s.description = 'Simple DSL for Sphinx Search Server'
	s.authors = ['Gabriel Hora']
	s.email = 'gabrielhora@gmail.com'
	s.homepage = 'https://github.com/gabrielhora/zinx'
	s.files = Dir['lib/**/*.rb'].to_a
	s.test_files = Dir['test/**/*.rb'].to_a
end
