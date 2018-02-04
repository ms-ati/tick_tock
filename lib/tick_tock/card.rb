require "values"

module TickTock
  # @api private
  #
  # The representation of a "punch card" used by the default {Punch}
  # implementation
  #
  # @!parse
  #   class Card
  #     # Constructor accepting keyword args.
  #     #
  #     # @param subject     [Object]     Description of subject of this card
  #     # @param parent_card [Card, nil]
  #     # @param time_in     [Time, nil]
  #     # @param time_out    [Time, nil]
  #     # @return [Card]
  #     def self.with(subject:, parent_card:, time_in:, time_out:); end
  #
  #     # @param subject     [Object]     Description of subject of this card
  #     # @param parent_card [Card, nil]
  #     # @param time_in     [Time, nil]
  #     # @param time_out    [Time, nil]
  #     def initialize(subject, parent_card, time_in, time_out); end
  #
  #     # @return [Card]
  #     #   a copy of this instance with any given values replaced.
  #     #
  #     # @param subject     [Object]     Description of subject of this card
  #     # @param parent_card [Card, nil]
  #     # @param time_in     [Time, nil]
  #     # @param time_out    [Time, nil]
  #     def with(subject: nil, parent_card: nil, time_in: nil, time_out: nil)
  #     end
  #   end
  #
  # @attr_reader subject     [Object]     Description of subject of this card
  # @attr_reader parent_card [Card, nil]
  # @attr_reader time_in     [Time, nil]
  # @attr_reader time_out    [Time, nil]
  class Card < Value.new(:subject, :parent_card, :time_in, :time_out)
  end
end
