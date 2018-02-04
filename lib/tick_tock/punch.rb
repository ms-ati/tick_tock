require "tick_tock/card"

module TickTock
  class Punch < Value.new(:time_now)
    def self.default
      with(time_now: Time.method(:now))
    end

    def card(subject: nil, parent_card: nil)
      Card.with(
        subject: subject,
        parent_card: parent_card,
        time_in: nil,
        time_out: nil
      )
    end

    def in(card)
      card.with(time_in: time_now.call)
    end

    def out(card)
      card.with(time_out: time_now.call)
    end

    def parent_card_of(card)
      card.parent_card
    end
  end
end
