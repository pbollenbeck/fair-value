require 'distribution'
require 'parallel'
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
  end

  def call
    Parallel.map(1..NUMBER_OF_SIMULATIONS, progress: "Running simulations") do
      forecast
    end
  end

  private

  def trading_day?(date)
    ![0,6].include?(date.wday)
  end

  def trading_days(date_range)
    date_range.select { |date| trading_day?(date) }
  end

  def forecast
    (1..@number_of_days).inject(@last_closing_price) { |last_price, _| next_price(last_price) }
  end

  def next_price(last_price)
    (last_price * random_factor).round(3)
  end

  def random_factor
    Math.exp(@drift + @sigma * Distribution::Normal.p_value(rand()))
  end
end
