# frozen_string_literal: true
require 'cucumber/core/event_bus'
require 'cucumber/core/gherkin/parser'
require 'cucumber/core/gherkin/document'
require 'cucumber/core/compiler'
require 'cucumber/core/test/runner'
require 'cucumber/messages'
require 'gherkin/query'

module Cucumber
  module Core

    def execute(gherkin_documents, filters = [], event_bus = EventBus.new, id_generator = Cucumber::Messages::IdGenerator::Incrementing.new)
      yield event_bus if block_given?
      receiver = Test::Runner.new(event_bus)
      compile gherkin_documents, receiver, filters, event_bus, id_generator
      self
    end

    def compile(gherkin_documents, last_receiver, filters = [], event_bus = EventBus.new, id_generator = Cucumber::Messages::IdGenerator::Incrementing.new)
      first_receiver = compose(filters, last_receiver)
      gherkin_query = ::Gherkin::Query.new
      compiler = Compiler.new(first_receiver, gherkin_query, id_generator, event_bus)
      parse gherkin_documents, compiler, event_bus, gherkin_query, id_generator
      self
    end

    private

    def parse(gherkin_documents, compiler, event_bus, gherkin_query, id_generator)
      parser = Core::Gherkin::Parser.new(compiler, event_bus, gherkin_query, id_generator)
      gherkin_documents.each do |document|
        parser.document document
      end
      parser.done
      self
    end

    def compose(filters, last_receiver)
      filters.reverse.reduce(last_receiver) do |receiver, filter|
        filter.with_receiver(receiver)
      end
    end

  end
end
