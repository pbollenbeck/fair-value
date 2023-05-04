require 'benchmark'
require 'date'
require 'distribution'
require 'parallel'
require 'ruby-progressbar'

LAST_CLOSING_PRICE = 9.1
LAST_TRADING_DAY = Date.parse('2023-03-29')
SIGMA = 0.022114372
DRIFT = -0.0007733862929
GRANT_ID = '2023-q1'
OUTPUT_FILE_NAME = "output-#{GRANT_ID}.txt"

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

def write_output(forecasts, file_name)
  File.open(file_name, 'w') do |f|
    sum = 0.0
    forecasts.each_with_index do |forecast, i|
      sum += forecast
      if (i+1) % 10_000 == 0
        average = (sum / (i+1)).round(2)
        f.write "#{(i+1)/10000} x 10k average: #{average}\n"
      end
    end
  end
end

forecasts = MonteCarloSimulation.new(LAST_CLOSING_PRICE, LAST_TRADING_DAY,
                                     SIGMA, DRIFT).call
write_output(forecasts, OUTPUT_FILE_NAME)
