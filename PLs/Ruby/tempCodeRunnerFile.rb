  def calculate_salary(out_time, day_type, holiday_type)
    in_time = "0900"

    # If out time is 0900, consider the person absent
    if out_time == "0900"
      if day_type == "rest day"
        puts "Salary for the day: #{@daily_salary}" # Display daily salary for rest day when absent
        return @daily_salary
      else
        return 0
      end
    end

    worked_hours = calculate_worked_hours(in_time, out_time)
    
    # Add worked hours to the daily salary if it's a rest day
    base_salary = day_type == "rest day" ? @daily_salary + worked_hours : @daily_salary

    base_salary *= night_shift?(out_time) ? 1.1 : 1.0
    base_salary *= holiday_rest_day_multiplier(day_type, holiday_type)

    # Subtract regular hours before calculating overtime hours
    overtime_hours = [0, worked_hours - @regular_hours - 1].max
    @total_overtime_hours += overtime_hours
    overtime_pay = overtime_hours.positive? ? (overtime_hours * overtime_rate(out_time, day_type, holiday_type)) : 0

    puts "Salary for the day: #{(base_salary + overtime_pay).round(2)}"

    (base_salary + overtime_pay).round(2)
  end