RSpec.describe TickTock::CardLogger do
  describe ".default_logger" do
    subject { described_class.default_logger }

    context "when 'Rails.logger' is not defined" do
      before(:each) { hide_const("Rails") }
      it { is_expected.to be_a ::Logger }
    end

    context "when 'Rails.logger' is defined" do
      before(:each) { stub_const("Rails", stubbed_rails_const) }

      let(:stubbed_rails_const) do
        double("Rails", logger: :expected_rails_logger)
      end

      it { is_expected.to be :expected_rails_logger }
    end
  end

  describe "#call" do
    subject { card_logger.call(card) }

    let(:card_logger) { described_class.default }

    let(:card) do
      TickTock::Card.with(
        subject:     "Foo",
        parent_card: nil,
        time_in:     Time.now,
        time_out:    nil
      )
    end

    context "happy path" do
      before(:each) { hide_const("Rails") }

      it { expect { subject }.to output.to_stdout }
    end
  end
end
