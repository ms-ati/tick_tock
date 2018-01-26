require "tick_tock/wraps"

module TickTock
  Timer = Value.new(:punch)

  class Timer
    include Wraps

    def tick(subject: nil, parent_card: nil, use_existing_card: nil)
      card = use_existing_card || punch.card(
        subject: subject,
        parent_card: parent_card
      )
      punch.in(card)
    end

    def tock(card)
      punch.out(card)
    end
  end
end
