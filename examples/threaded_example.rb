require "pp"
require "tick_tock"

inputs = [1, 2, 3]

slow_proc = ->(n) { sleep(1); n * Thread.current.name.to_i }

wrapped_slow_proc = TickTock.tick_tock_proc(
  slow_proc,
  subject: ->(n) { "Thr #{Thread.current.name}, Num #{n}" }
)

result =
  TickTock.tick_tock(subject: "Top Level") do
    thread_proc = TickTock.tick_tock_proc(
      subject: ->(n) { "Thr #{n}" },
      save_context: true
    ) do |n|
      Thread.current.name = n.to_s
      inputs.map(&wrapped_slow_proc)
    end

    # In each thread, we pick up logging within the saved context
    Array.new(3) { |n| Thread.new(n + 1, &thread_proc) }.map(&:value)
  end

pp result
