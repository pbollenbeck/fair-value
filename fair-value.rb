require 'date'
require 'distribution'

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

days = trading_days(Date.parse('2021-11-19')..Date.parse('2025-11-18'))
forecasts = []
j = 0
average = 0
length = days.length
5_000_000.times do |i|
  last_price = forecast(29.2, 0.02292496765, length, -0.00005344090089)
  forecasts.push(last_price)
  average = (average * i + last_price) / (i+1)

  if (i+1) % 10_000 == 0
    j += 1
    puts j.to_s + " x 10k average: " + average.round(2).to_s
  end
end

puts "\nTotal average price: " + (forecasts.sum / forecasts.length).round(2)
