require "pp"
require "tick_tock"

lazy_enum = [1, 2, 3].lazy

slow_proc = ->(n) { sleep(1); n * 2 }

TickTock.wrap_block(subject: "Top Level") do
  wrapped_enum = TickTock.wrap_lazy(
    # lazy_enum.map do |n|
    #   TickTock.wrap_proc(slow_proc, subject: ->(n) { "Num #{n}" }).call(n)
    # end,
    lazy_enum.map do |n|
      TickTock.wrap_block(subject: "Num #{n}") { slow_proc.call(n) }
    end,
    subject: "Lazy Enum"
  )

  pp wrapped_enum.to_a
end
