class Leap
    extend Helpers
    def is_leap_year?(year)
        mod(year, 4)
    end
end
