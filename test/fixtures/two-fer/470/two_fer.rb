class TwoFer
	def self.two_fer(name = nil)
		@name = name if name
		name ? "One for #{@name}, one for me." : "One for you, one for me."
	end
end
