class TwoFer
  def self.two_fer(*args)
    if args[0]
      "One for #{args[0]}, one for me."
    else
      'One for you, one for me.'
    end
  end
end