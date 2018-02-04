require "logger"
require "values"

module TickTock
  CardLogger = Value.new(
    :logger,
    :severity,
    :secs_decimals,
    :show_zero_mins,
    :show_zero_hrs
  )

  class CardLogger
    def self.default
      with(
        logger:         Logger.new($stdout),
        severity:       Logger::INFO,
        secs_decimals:  3,
        show_zero_mins: false,
        show_zero_hrs:  false
      )
    end

    def call(card)
      logger.add(severity, nil, nil) { format(card) }
    end

    private

    def format(card)
      prefix, verb = card.time_out.nil? ? [">", "Started"] : ["<", "Completed"]
      suffix = card.time_out && "[#{elapsed(card.time_out - card.time_in)}]"
      [prefix * depth(card), verb, card.subject, suffix].compact.join(" ")
    end

    def depth(card, count = 1)
      card.parent_card.nil? ? count : depth(card.parent_card, count + 1)
    end

    def elapsed(secs)
      if secs < 60 && !show_zero_hrs && !show_zero_mins
        "%.#{secs_decimals}fs" % secs
      else
        secs_width = 3 + secs_decimals # because 3 is 2 digits plus a "."

        str = "%02dh:%02dm:%0#{secs_width}.#{secs_decimals}fs" % [
          secs / 3600,    # hours
          secs / 60 % 60, # minutes
          secs % 60       # seconds
        ]

        str.sub!("00h:", "") unless show_zero_hrs
        str.sub!("00m:", "") unless show_zero_hrs || show_zero_mins
        str
      end
    end
  end
end
