require 'date'

class PayrollSystem
  attr_accessor :daily_salary, :regular_hours, :workdays, :rest_days, :out_times, :holidays

  NIGHT_SHIFT_START_HOUR = 22
  NIGHT_SHIFT_END_HOUR = 6

  OVERTIME_RATES = {
    normal: { non_night_shift: 1.25, night_shift: 1.375 },
    rest_day: { non_night_shift: 1.69, night_shift: 1.859 },
    special_non_working_day: { non_night_shift: 1.69, night_shift: 1.859 },
    special_non_working_day_rest_day: { non_night_shift: 1.95, night_shift: 2.145 },
    regular_holiday: { non_night_shift: 2.6, night_shift: 2.86 },
    regular_holiday_rest_day: { non_night_shift: 3.38, night_shift: 3.718 }
  }.freeze

  def initialize
    @employee_name = ""
    @daily_salary = 500.0
    @regular_hours = 8
    @workdays = 5
    @rest_days = 2
    @out_times = Hash.new("0900") # Default OUT time is 0900 for all days
    @total_overtime_hours = 0
    @holidays = {}
    @settings_changed = false
  end

  # Display the main menu
  def display_menu
    puts "\nPayroll Menu"
    puts "1. Generate Payroll"
    puts "2. Configure Payroll Settings"
    puts "3. Exit"
    print "Select Option: "
  end

  # Generate the payroll for an employee
  def generate_payroll
    update_settings if @settings_changed
    puts "\nGenerating Pay Roll...."
    print "Enter Employee Name: "
    @employee_name = gets.chomp

    total_salary = 0
    regular_days_present = 0  # Counter for regular days present
    rest_days_present = 0     # Counter for rest days present
    regular_days_absent = 0   # Counter for regular days absent
    rest_days_absent = 0      # Counter for rest days absent

    # Loop through workdays and rest days
    (1..(@workdays + @rest_days)).each do |day|
      puts "\n---------------------------------"
      puts "DAY #{day}"

      if day <= @workdays
        puts "Regular Day"
      else
        puts "Rest Day"
        # Set default OUT time to 0900 on rest days if no settings were changed
        @out_times[day] = "0900"
      end

      # Choose holiday type in update work hours if not already chosen
      day_type = determine_day_type(day)
      holiday_type = @holidays[day] || "not_applicable"

      salary = calculate_salary(@out_times[day], day_type, holiday_type)
      total_salary += salary

      if day <= @workdays
        regular_days_present += 1
      else
        rest_days_present += 1
      end
    end

    display_summary(total_salary, regular_days_present, rest_days_present, regular_days_absent, rest_days_absent)
  end

  # Update work hours configuration
  def configure_payroll_settings
    @settings_changed = true
    puts "\nConfigure Payroll Settings"
    puts "1. Update Daily Salary"
    puts "2. Update Maximum Regular Hours per Day"
    puts "3. Update Number of Workdays in a Week"
    puts "4. Update Number of Rest Days in a Week"
    puts "5. Update OUT Time per Day"
    puts "6. Update Holidays"
    puts "7. Revert back to Default Settings"
    puts "8. Exit"
    print "Select Option: "
    option = gets.chomp.to_i

    case option
    when 1
      print "Enter new Daily Salary: "
      @daily_salary = gets.chomp.to_f
      puts "Daily Salary updated successfully."
    when 2
      print "Enter new Maximum Regular Hours per Day: "
      @regular_hours = gets.chomp.to_i
      puts "Maximum Regular Hours per Day updated successfully."
    when 3
      print "Enter new Number of Workdays in a Week: "
      @workdays = gets.chomp.to_i
      puts "Number of Workdays in a Week updated successfully."
    when 4
      print "Enter new Number of Rest Days in a Week: "
      @rest_days = gets.chomp.to_i
      puts "Number of Rest Days in a Week updated successfully."
    when 5
      update_out_time_per_day
    when 6
      update_holidays
    when 7
      revert_to_default_settings
      puts "Settings reverted back to default values."
    when 8
      puts "Exiting Configure Payroll Settings."
    else
      puts "Invalid option. Please enter a valid option."
    end
  end

  # Revert the settings to default values
  def revert_to_default_settings
    reset_to_default_settings
    @settings_changed = true
  end

  private

  # Determine the type of day (normal day or rest day)
  def determine_day_type(day)
    day <= @workdays ? "normal day" : "rest day"
  end

  # Get the type of holiday for a given day
  def choose_holiday_type(day)
    return if determine_day_type(day) == "rest day"

    puts "Holiday:"
    puts "1. Special Non Working Holiday"
    puts "2. Regular Holiday"
    puts "3. Not Applicable"
    print "Enter Choice (1-3): "
    holiday_choice = gets.chomp.to_i

    case holiday_choice
    when 1
      @holidays[day] = "special_non_working_day"
    when 2
      @holidays[day] = "regular_holiday"
    else
      @holidays[day] = "not_applicable"
    end
  end

  # Calculate the salary for a given day
  def calculate_salary(out_time, day_type, holiday_type)
    in_time = "0900"

    # If OUT time is 0900, consider the person absent
    if out_time == "0900"
      if day_type == "rest day"
        puts "Salary for the day: #{@daily_salary}" # Display daily salary for rest day when absent
        return @daily_salary
      else
        puts "Employee is absent on a regular day."
        return 0
      end
    end

    worked_hours = calculate_worked_hours(in_time, out_time)
    base_salary = base_salary(day_type, worked_hours, holiday_type)

    base_salary *= night_shift?(out_time) ? 1.1 : 1.0
    base_salary *= holiday_rest_day_multiplier(day_type, holiday_type)

    # Subtract regular hours before calculating overtime hours
    overtime_hours = [0, worked_hours - @regular_hours].max
    overtime_pay = calculate_overtime_pay(overtime_hours, out_time, day_type, holiday_type)

    total_salary = base_salary + overtime_pay
    puts "Salary for the day: #{'%.2f' % total_salary}"

    total_salary
  end

  # Calculate the base salary for a given day
  def base_salary(day_type, worked_hours, holiday_type)
    hourly_rate = @daily_salary / @regular_hours

    case day_type
    when "rest day"
      base_salary = @daily_salary + (worked_hours * hourly_rate * 0.3) # Additional 30% for rest day
    else
      base_salary = @daily_salary
    end

    base_salary
  end

  # Calculate overtime pay for a given day
  def calculate_overtime_pay(overtime_hours, out_time, day_type, holiday_type)
    return 0 if overtime_hours <= 0

    overtime_rate = overtime_rate(out_time, day_type, holiday_type)
    overtime_pay = overtime_hours * (@daily_salary / @regular_hours) * overtime_rate
    puts "Overtime Pay: #{'%.2f' % overtime_pay}"

    @total_overtime_hours += overtime_hours # Update total overtime hours

    overtime_pay
  end

  # Calculate the worked hours based on the in and out times
  def calculate_worked_hours(in_time, out_time)
    in_time = DateTime.strptime("2000-01-01 #{in_time}", "%Y-%m-%d %H%M")

    # Convert out_time to the corresponding 24-hour format if it's until 8:59 AM
    out_time = out_time.to_i <= 859 ? DateTime.strptime("2000-01-02 #{out_time}", "%Y-%m-%d %H%M") : DateTime.strptime("2000-01-01 #{out_time}", "%Y-%m-%d %H%M")

    total_worked_seconds = out_time.to_time - in_time.to_time
    total_worked_hours = total_worked_seconds / 3600.0

    total_worked_hours
  end

  # Check if the out time falls within the night shift hours
  def night_shift?(out_time)
    out_time_hours = DateTime.strptime("2000-01-01 #{out_time}", "%Y-%m-%d %H%M").hour
    out_time_hours < NIGHT_SHIFT_END_HOUR || out_time_hours >= NIGHT_SHIFT_START_HOUR
  end

  # Get the multiplier for holiday and rest day
  def holiday_rest_day_multiplier(day_type, holiday_type)
    multiplier = 1.0

    if holiday_type != "not_applicable"
      multiplier = case holiday_type
                   when /rest day/ then 3.38
                   when /holiday/ then 2.6
                   else 1.69
                   end
    elsif day_type == "rest day"
      multiplier = 1.3
    end

    multiplier
  end

  # Get the overtime rate based on the day type and holiday type
  def overtime_rate(out_time, day_type, holiday_type)
    rate_key = "#{day_type}_#{holiday_type}".to_sym

    if OVERTIME_RATES.key?(rate_key)
      shift_type = night_shift?(out_time) ? :night_shift : :non_night_shift
      OVERTIME_RATES[rate_key][shift_type]
    else
      1.0
    end
  end

  # Reset the settings to default values
  def reset_to_default_settings
    @daily_salary = 500.0
    @regular_hours = 8
    @workdays = 5
    @rest_days = 2
    @out_times = Hash.new("0900") # Default OUT time is 0900 for all days
    @holidays = {}
  end

  # Display the summary of the weekly payroll, including regular and rest days count
  def display_summary(total_salary, regular_days_present, rest_days_present, regular_days_absent, rest_days_absent)
    puts "\n#{@employee_name}'s Weekly Payroll"
    puts "Number of (Regular) Days Present\t\t\t#{regular_days_present}"
    puts "Number of (Rest) Days Present\t\t\t\t#{rest_days_present}"
    puts "Number of (Regular) Days Absent\t\t\t\t#{regular_days_absent}"
    puts "Number of (Rest) Days Absent\t\t\t\t#{rest_days_absent}"
    puts "Total Hours Overtime (Night Shift Overtime)\t\t#{@total_overtime_hours}"
    puts "--------------------------------------------------------"
    puts "Total Salary for the Week\t\t\t\t#{'%.2f' % total_salary}"
  end

  # Ask for OUT time for each day
  def ask_for_out_time
    print "Enter OUT Time (HHMM in military time format, e.g., 1700): "
    gets.chomp
  end

  # Update OUT time for each day
  def update_out_time_per_day
    (1..(@workdays + @rest_days)).each do |day|
      puts "\n---------------------------------"
      puts "DAY #{day}"

      if day <= @workdays
        puts "Regular Day"
      else
        puts "Rest Day"
      end

      @out_times[day] = ask_for_out_time
    end

    puts "OUT Time updated successfully."
  end

  # Update holidays for each day
  def update_holidays
    (1..(@workdays + @rest_days)).each do |day|
      puts "\n---------------------------------"
      puts "DAY #{day}"

      if day <= @workdays
        puts "Regular Day"
        choose_holiday_type(day)
      else
        puts "Rest Day"
        @holidays[day] = "not_applicable"
      end
    end

    puts "Holidays updated successfully."
  end

  # Update settings if they have been changed
  def update_settings
    # Add logic to update any other settings if needed
    @settings_changed = false
  end
end

# Instantiate the PayrollSystem
payroll_system = PayrollSystem.new

# Main program loop
loop do
  payroll_system.display_menu
  option = gets.chomp.to_i

  case option
  when 1
    payroll_system.generate_payroll
  when 2
    payroll_system.configure_payroll_settings
  when 3
    break
  else
    puts "Invalid option. Please enter a valid option."
  end
end
