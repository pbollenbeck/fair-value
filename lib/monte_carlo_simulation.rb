require 'opencl_ruby_ffi'
require 'ruby-progressbar'

class MonteCarloSimulation
  NUMBER_OF_SIMULATIONS = 5_000_000
  TIME_IN_YEARS = 4

  def initialize(last_closing_price, last_trading_day, sigma, drift)
    @last_closing_price = last_closing_price
    @sigma = sigma
    @drift = drift
    first_sim_date = last_trading_day.next_day
    last_sim_date = last_trading_day >> (12 * TIME_IN_YEARS) # Advance by months
    @number_of_days = trading_days(first_sim_date..last_sim_date).length

    setup_opencl
  end

  def call
    progressbar = ProgressBar.create(title: "Running simulations", total: NUMBER_OF_SIMULATIONS)
    results = Array.new(NUMBER_OF_SIMULATIONS)
    @queue.enqueue_nd_range_kernel(@kernel, [NUMBER_OF_SIMULATIONS])
    @queue.enqueue_read_buffer(@results_buffer, results)
    @queue.finish
    progressbar.finish
    results
  end

  private

  def trading_day?(date)
    ![0,6].include?(date.wday)
  end

  def trading_days(date_range)
    date_range.select { |date| trading_day?(date) }
  end

  def setup_opencl
    platform = OpenCL.platforms.first
    device = platform.devices.first
    @context = OpenCL::Context.new(device)
    @queue = OpenCL::CommandQueue.new(@context, device)

    # Create and build the OpenCL program
    source = File.read('monte_carlo_simulation.cl')
    program = @context.create_program_with_source(source)
    program.build

    # Create the kernel
    @kernel = program.create_kernel('monte_carlo_simulation')

    # Set up kernel arguments
    @kernel.set_arg(0, @last_closing_price)
    @kernel.set_arg(1, @drift)
    @kernel.set_arg(2, @sigma)
    @kernel.set_arg(3, @number_of_days)
    @results_buffer = OpenCL::Buffer.new(@context, OpenCL::Mem::WRITE_ONLY, NUMBER_OF_SIMULATIONS * 8)
    @kernel.set_arg(4, @results_buffer)
  end
end
