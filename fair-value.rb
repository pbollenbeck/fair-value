require 'benchmark'
require 'date'
require 'distribution'
require 'parallel'
require 'ruby-progressbar'

LAST_CLOSING_PRICE = 9.1
FIRST_SIM_DATE= Date.parse('2023-03-30')
LAST_SIM_DATE= Date.parse('2027-03-29')
SIGMA = 0.022114372
DRIFT = -0.0007733862929
GRANT_ID = '2023-q1'
OUTPUT_FILE_NAME = "output-#{GRANT_ID}.txt"
NUMBER_OF_SIMULATIONS = 5_000_000

def trading_day?(date)
  ![0,6].include?(date.wday)
end

def trading_days(date_range)
  date_range.select { |date| trading_day?(date) }
end

def forecast(start_price, sigma, number_of_days, drift)
  last_price = start_price
  number_of_days.times do
    last_price = (last_price * Math.exp(
      drift + sigma * Distribution::Normal.p_value(rand())
    )).round(3)
  end
  last_price
end

def simulate
  length = trading_days(FIRST_SIM_DATE..LAST_SIM_DATE).length
  Parallel.map(1..NUMBER_OF_SIMULATIONS, progress: "Running simulations") do
    forecast(LAST_CLOSING_PRICE, SIGMA, length, DRIFT)
  end
end

forecasts = simulate

File.open(OUTPUT_FILE_NAME, 'w') do |f|
  j = 0
  average = 0.0
  forecasts.each_with_index do |forecast, i|
    average = (average * i + forecast) / (i+1)
    if (i+1) % 10_000 == 0
      j += 1
      f.write "#{j} x 10k average: #{average.round(2)}\n"
    end
  end
end
