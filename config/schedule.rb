every :weekday, at: '2:35 pm' do
  runner 'RefreshExchangeRatesJob.perform_later'
end