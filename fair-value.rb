require 'date'
require 'distribution'

LAST_CLOSING_PRICE = 11.8
FIRST_SIM_DATE= Date.parse('2022-12-21')
LAST_SIM_DATE= Date.parse('2026-12-20')
SIGMA = 0.02144133922
DRIFT = -0.0005997348378

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

days = trading_days(FIRST_SIM_DATE..LAST_SIM_DATE)
forecasts = []
j = 0
average = 0
length = days.length
5_000_000.times do |i|
  last_price = forecast(LAST_CLOSING_PRICE, SIGMA, length, DRIFT)
  forecasts.push(last_price)
  average = (average * i + last_price) / (i+1)

  if (i+1) % 10_000 == 0
    j += 1
    puts j.to_s + " x 10k average: " + average.round(2).to_s
  end
end

puts "\nTotal average price: " + (forecasts.sum / forecasts.length).round(2)
