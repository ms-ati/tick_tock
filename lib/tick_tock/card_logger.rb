require "logger"
require "values"

module TickTock
  # CardLogger is {TickTock}'s default implementation for logging each {Card} as
  # it is punched in and out. Any implementation of {#call} taking a {Card} as
  # its only parameter can be used instead.
  #
  # This implementation defaults to using the Rails logger if present, falling
  # back to a default Ruby logger on STDOUT if not.
  #
  # @!parse
  #   class CardLogger
  #     # @!group Class Methods due to being a Value object
  #
  #     # Constructor accepting keyword args.
  #     #
  #     # @param logger         [Logger]   Instance of Ruby's Logger to use
  #     # @param severity       [Integer]  Level to log at (DEBUG, INFO, etc)
  #     # @param secs_decimals  [Integer]  How many decimal places for seconds
  #     # @param show_zero_mins [Boolean]  Whether to output minutes if zero
  #     # @param show_zero_hrs  [Boolean]  Whether to output hours if zero
  #     # @return [CardLogger]
  #     def self.with(logger:, severity:, secs_decimals:, show_zero_mins:, show_zero_hrs:); end
  #
  #     # @!endgroup
  #
  #     # @!group Instance Methods due to being a Value object
  #
  #     # @param logger         [Logger]   Instance of Ruby's Logger to use
  #     # @param severity       [Integer]  Level to log at (DEBUG, INFO, etc)
  #     # @param secs_decimals  [Integer]  How many decimal places for seconds
  #     # @param show_zero_mins [Boolean]  Whether to output minutes if zero
  #     # @param show_zero_hrs  [Boolean]  Whether to output hours if zero
  #     def initialize(logger, severity, secs_decimals, show_zero_mins, show_zero_hrs); end
  #
  #     # @return [CardLogger]
  #     #   a copy of this instance with any given values replaced.
  #     #
  #     # @param logger         [Logger]   Instance of Ruby's Logger to use
  #     # @param severity       [Integer]  Level to log at (DEBUG, INFO, etc)
  #     # @param secs_decimals  [Integer]  How many decimal places for seconds
  #     # @param show_zero_mins [Boolean]  Whether to output minutes if zero
  #     # @param show_zero_hrs  [Boolean]  Whether to output hours if zero
  #     def with(logger: nil, severity: nil, secs_decimals: nil, show_zero_mins: nil, show_zero_hrs: nil); end
  #
  #     # @!endgroup
  #   end
  #
  # @attr_reader logger         [Logger]   Instance of Ruby's Logger to use
  # @attr_reader severity       [Integer]  Level to log at (DEBUG, INFO, etc)
  # @attr_reader secs_decimals  [Integer]  How many decimal places for seconds
  # @attr_reader show_zero_mins [Boolean]  Whether to output minutes if zero
  # @attr_reader show_zero_hrs  [Boolean]  Whether to output hours if zero
  #
  class CardLogger < Value.new(:logger,
                               :severity,
                               :secs_decimals,
                               :show_zero_mins,
                               :show_zero_hrs)
    # @return [CardLogger] an instance with the default configuration
    def self.default
      with(
        logger:         default_logger,
        severity:       Logger::INFO,
        secs_decimals:  3,
        show_zero_mins: false,
        show_zero_hrs:  false
      )
    end

    # Default card logging action is to format it and send to the configured
    # {Logger} instance and the configured severity level.
    #
    # @param card [Card]
    #   Card to log in or out, depending on the state of the card.
    #
    # @return [String, nil]
    #   Formatted string that was logged, or +nil+ if the configured severity
    #   was not high enough to be logged by the configured logger.
    def call(card)
      formatted = nil
      logger.add(severity, nil, nil) { formatted = format(card) }
      formatted
    end

    private

    def self.default_logger
      if defined? Rails.logger
        Rails.logger
      else
        Logger.new($stdout)
      end
    end

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
