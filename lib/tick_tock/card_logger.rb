require "logger"
require "values"

module TickTock
  CardLogger = Value.new(:logger, :severity, :seconds_decimals)

  class CardLogger
    def self.default
      with(
        logger: Logger.new($stdout),
        severity: Logger::INFO,
        seconds_decimals: 3
      )
    end

    def call(card)
      logger.add(severity, nil, nil) { format(card) }
    end

    private

    def format(card)
      prefix, verb = card.out.nil? ? [">", "Started"] : ["<", "Completed"]
      elapsed = card.out && "[#{duration(card.out - card.in)}]"
      [prefix * depth(card), verb, card.subject, elapsed].compact.join(" ")
    end

    def depth(card, count = 1)
      card.parent_card.nil? ? count : depth(card.parent_card, count + 1)
    end

    def duration(secs)
      secs_width = 3 + seconds_decimals
      "%02dh:%02dm:%0#{secs_width}.#{seconds_decimals}fs" % [
        secs / 3600,    # hours
        secs / 60 % 60, # minutes
        secs % 60       # seconds
      ]
    end
  end
end
