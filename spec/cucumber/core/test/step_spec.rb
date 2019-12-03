# frozen_string_literal: true
require 'cucumber/core/test/step'

module Cucumber::Core::Test
  describe Step do
    let(:text) { 'step text' }
    let(:location) { double }

    describe '#to_message' do
      let(:step) { Step.new("pickle-step-id", text, location, nil, nil) }
      let(:message) { step.to_message }
      let(:uuid_regex) { /[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}/ }

      it 'outputs the step ID' do
        expect(message.id).to match(uuid_regex)
      end

      it 'outputs the pickleStepId' do
        expect(message.pickleStepId).to eq('pickle-step-id')
      end
    end

    describe "describing itself" do
      it "describes itself to a visitor" do
        visitor = double
        args = double
        test_step = Step.new('', text, location, nil, nil)
        expect( visitor ).to receive(:test_step).with(test_step, args)
        test_step.describe_to(visitor, args)
      end
    end

    describe "backtrace line" do
      let(:text) { 'this step passes' }
      let(:location)  { Location.new('path/file.feature', 10) }
      let(:test_step) { Step.new('', text, location, nil, nil) }

      it "knows how to form the backtrace line" do
        expect( test_step.backtrace_line ).to eq("path/file.feature:10:in `this step passes'")
      end
    end

    describe "executing" do
      it "passes arbitrary arguments to the action's block" do
        args_spy = nil
        expected_args = [double, double]
        test_step = Step.new('', text, location, nil, nil).with_action do |*actual_args|
          args_spy = actual_args
        end
        test_step.execute(*expected_args)
        expect(args_spy).to eq expected_args
      end

      context "when a passing action exists" do
        it "returns a passing result" do
          test_step = Step.new('', text, location, nil, nil).with_action {}
          expect( test_step.execute ).to be_passed
        end
      end

      context "when a failing action exists" do
        let(:exception) { StandardError.new('oops') }

        it "returns a failing result" do
          test_step = Step.new('', text, location, nil, nil).with_action { raise exception }
          result = test_step.execute
          expect( result           ).to be_failed
          expect( result.exception ).to eq exception
        end
      end

      context "with no action" do
        it "returns an Undefined result" do
          test_step = Step.new('', text, location, nil, nil)
          result = test_step.execute
          expect( result           ).to be_undefined
        end
      end
    end

    it "exposes the text and location of as attributes" do
      test_step = Step.new('', text, location, nil, nil)
      expect( test_step.text              ).to eq text
      expect( test_step.location          ).to eq location
    end

    it "exposes the location of the action as attribute" do
      location = double
      action = double(location: location)
      test_step = Step.new('', text, location, nil, action)
      expect( test_step.action_location ).to eq location
    end

    it "returns the text when converted to a string" do
      text = 'a passing step'
      test_step = Step.new('', text, location, nil, nil)
      expect( test_step.to_s     ).to eq 'a passing step'
    end
  end

  describe HookStep do
    context '#to_message' do
      let(:step) { HookStep.new('hook-id', 'some-text', nil, nil) }
      let(:message) { step.to_message}

      it 'provides the Hook id' do
        expect(message.hookId).to eq('hook-id')
      end
    end
  end
end
