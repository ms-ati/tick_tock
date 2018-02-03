require "values"

module TickTock
  Punch = Value.new(:time_now, :log_card_in, :log_card_out)
end

require "tick_tock/punch/card"
require "tick_tock/punch/card_logger"

module TickTock
  class Punch
    def self.default
      default_time_now = Time.method(:now)
      default_log_card = CardLogger.default.method(:call)
      with(
        time_now:     default_time_now,
        log_card_in:  default_log_card,
        log_card_out: default_log_card
      )
    end

    def card(subject: nil, parent_card: nil)
      Card.with(subject: subject, parent_card: parent_card, in: nil, out: nil)
    end

    def in(card)
      card_in = card.with(in: time_now.call)
      log_card_in&.call(card_in)
      card_in
    end

    def out(card)
      card_out = card.with(out: time_now.call)
      log_card_out&.call(card_out)
      card_out
    end

    def parent_card_of(card)
      card.parent_card
    end
  end
end
