# frozen_string_literal: true
require 'gherkin'

module Cucumber
  module Core
    module Gherkin
      ParseError = Class.new(StandardError)

      class Parser
        attr_reader :receiver, :event_bus, :gherkin_query, :id_generator
        private     :receiver, :event_bus, :gherkin_query, :id_generator

        def initialize(receiver, event_bus, gherkin_query, id_generator)
          @receiver = receiver
          @event_bus = event_bus
          @gherkin_query = gherkin_query
          @id_generator = id_generator
        end

        def document(document)
          messages = ::Gherkin.from_source(document.uri, document.body, gherkin_options(document))
          messages.each do |message|
            event_bus.envelope(message)
            gherkin_query.update(message)
            if !message.gherkin_document.nil?
              event_bus.gherkin_source_parsed(message.gherkin_document)
            elsif !message.pickle.nil?
              receiver.pickle(message.pickle)
            elsif !message.attachment.nil?
              # Parse error
              raise Core::Gherkin::ParseError.new("#{document.uri}: #{message.attachment.text}")
            else
              raise "Unknown message: #{message.to_hash}"
            end
          end
        end

        def gherkin_options(document)
          {
            default_dialect: document.language,
            include_source: false,
            include_gherkin_document: true,
            include_pickles: true,
            id_generator: id_generator
          }
        end

        def done
          receiver.done
          self
        end
      end
    end
  end
end
