$LOAD_PATH.unshift(File.expand_path('lib', __dir__))

require 'date'
require 'monte_carlo_simulation'

LAST_CLOSING_PRICE = 9.1
LAST_TRADING_DAY = Date.parse('2023-03-29')
SIGMA = 0.022114372
DRIFT = -0.0007733862929
GRANT_ID = '2023-q1'
OUTPUT_FILE_NAME = "output-#{GRANT_ID}.txt"

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
