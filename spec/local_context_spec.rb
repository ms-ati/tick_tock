require "securerandom"

RSpec.describe TickTock::LocalContext do
  let!(:a_proc) { ->(n) { n * described_class[a_key] } }

  let!(:a_key) { "key_" + SecureRandom.hex(2) }

  let!(:input_to_proc) { 2 }

  let!(:value_to_fetch) { 21 }

  let(:expected_result) { 42 }

  describe ".wrap_proc" do
    shared_context "a_proc_fetching_a_key_from_local_context" do
      context "when no value set" do
        it { expect { subject }.to raise_error(KeyError, /key not found/) }
      end

      context "when set to nil" do
        before(:each) { described_class[a_key] = nil }

        it "fetches nil which results in raising a TypeError in the Proc" do
          expect { subject }.
            to raise_error(
                 TypeError,
                 /nil can't be coerced into (Fixnum|Integer)/
               )
        end
      end

      context "when set to a value" do
        before(:each) { described_class[a_key] = value_to_fetch }

        it "fetches the value which results in expected result from Proc" do
          is_expected.to eq expected_result
        end
      end

      context "when proc modifies its local context" do
        let(:a_proc) do
          proc do |n|
            described_class[a_key] = -n   # change existing key
            described_class[key_2] = rand # add another key
          end
        end

        let!(:key_2) { "key_2_" + SecureRandom.hex(2) }

        it "restores local context after running wrapped proc" do
          described_class[a_key] = value_to_fetch
          expect { subject }.not_to change { described_class.context }
        end
      end
    end

    shared_context "verify_tests_executed_asynchronously" do
      let!(:async_results) { [] }

      it "executes asynchronously - verify test does what we think" do
        described_class[a_key] = value_to_fetch
        expect { subject }.to change { async_results }.to([expected_result])
      end
    end

    context "synchronously" do
      include_context "a_proc_fetching_a_key_from_local_context"

      subject do
        wrapped_proc = described_class.wrap_proc(&a_proc)
        wrapped_proc.call(input_to_proc)
      end
    end

    context "asynchronously in new Thread" do
      include_context "a_proc_fetching_a_key_from_local_context"
      include_context "verify_tests_executed_asynchronously"

      subject do
        wrapped_proc = described_class.wrap_proc(&a_proc)

        thread = Thread.new do
          async_results << wrapped_proc.call(input_to_proc)
          async_results.first
        end

        thread.value
      end
    end

    context "asynchronously in new Fiber" do
      include_context "a_proc_fetching_a_key_from_local_context"
      include_context "verify_tests_executed_asynchronously"

      subject do
        wrapped_proc = described_class.wrap_proc(&a_proc)

        fiber = Fiber.new do
          async_results << wrapped_proc.call(input_to_proc)
          async_results.first
        end

        fiber.resume
      end
    end
  end
end
