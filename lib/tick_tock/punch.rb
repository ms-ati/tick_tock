require "logger"
require "values"

module TickTock
  Punch = Value.new(:time_now, :log_card)

  class Punch
    DEFAULT_TIME_NOW = Time.method(:now)
    DEFAULT_LOG_CARD = Logger.new($stdout).method(:info)

    def self.default
      with(time_now: DEFAULT_TIME_NOW, log_card: DEFAULT_LOG_CARD)
    end

    def card(subject: nil, parent_card: nil)
      Card.with(subject: subject, parent_card: parent_card, in: nil, out: nil)
    end

    def in(card)
      card.with(in: time_now.call)
    end

    def out(card)
      card_out = card.with(out: time_now.call)
      log_card&.call(card_out)
      card_out
    end

    Card = Value.new(:subject, :parent_card, :in, :out)
    private_constant :Card
  end
end
