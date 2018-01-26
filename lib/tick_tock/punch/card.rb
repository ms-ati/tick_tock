require "values"

module TickTock
  class Punch
    Card = Value.new(:subject, :parent_card, :in, :out)
  end
end
