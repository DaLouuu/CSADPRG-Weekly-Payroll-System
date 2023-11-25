require 'date'

class WeeklyPayrollSystem
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
    @holidays = {}
    @settings_changed = false
  end

  def display_menu
    puts "\nWeekly Payroll System Menu"
    puts "1. Generate Payroll"
    puts "2. Configure Payroll Settings"
    puts "3. Exit"
    print "Select Option: "
  end

  def generate_payroll
    update_settings if @settings_changed
    puts "\nGenerating Weekly Payroll...."
    print "Enter Employee Name: "
    @employee_name = gets.chomp

    total_salary = 0
    regular_days_present = 0
    rest_days_present = 0
    regular_days_absent = 0
    rest_days_absent = 0

    (1..(@workdays + @rest_days)).each do |day|
      puts "\n---------------------------------"
      puts "DAY #{day}"

      if day <= @workdays
        puts "Regular Day"
      else
        puts "Rest Day"
        @out_times[day] = "0900" if !@settings_changed && @out_times[day] == "0900"
      end

      day_type = determine_day_type(day)
      holiday_type = @holidays[day] || "not_applicable"

      salary = calculate_salary(@out_times[day], day_type, holiday_type)
      total_salary += salary

      if day <= @workdays
        salary > 0 ? regular_days_present += 1 : regular_days_absent += 1
      else
        salary > 0 ? rest_days_present += 1 : rest_days_absent += 1
      end
    end

    display_summary(total_salary, regular_days_present, rest_days_present, regular_days_absent, rest_days_absent)
  end

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

  private

  def determine_day_type(day)
    day <= @workdays ? "normal day" : "rest day"
  end

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

  def calculate_salary(out_time, day_type, holiday_type)
    in_time = "0900"

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

    overtime_hours = [0, worked_hours - @regular_hours].max
    overtime_pay = calculate_overtime_pay(overtime_hours, out_time, day_type, holiday_type)

    total_salary = base_salary + overtime_pay
    puts "Salary for the day: #{'%.2f' % total_salary}"

    total_salary
  end

  def base_salary(day_type, worked_hours, holiday_type)
    hourly_rate = @daily_salary / @regular_hours

    case day_type
    when "normal day"
      worked_hours * hourly_rate
    when "rest day"
      worked_hours * hourly_rate * 1.3
    end
  end

  def holiday_rest_day_multiplier(day_type, holiday_type)
    multiplier = 1.0

    case holiday_type
    when "special_non_working_day"
      multiplier *= 1.3
    when "regular_holiday"
      multiplier *= 2.0
    end

    case day_type
    when "rest day"
      multiplier *= 1.5
    end

    multiplier
  end

  def calculate_overtime_pay(overtime_hours, out_time, day_type, holiday_type)
    return 0 if overtime_hours <= 0

    overtime_rate = overtime_rate(day_type, holiday_type, night_shift?(out_time))
    overtime_hours * overtime_rate
  end

  def overtime_rate(day_type, holiday_type, night_shift)
    OVERTIME_RATES[holiday_type.to_sym][night_shift ? :night_shift : :non_night_shift]
  end

  def calculate_worked_hours(in_time, out_time)
    in_time_dt = DateTime.strptime(in_time, '%H%M')
    out_time_dt = DateTime.strptime(out_time, '%H%M')

    ((out_time_dt - in_time_dt) * 24).to_f # Convert to hours
  end

  def night_shift?(out_time)
    out_time_dt = DateTime.strptime(out_time, '%H%M')
    out_time_dt.hour >= NIGHT_SHIFT_START_HOUR || out_time_dt.hour < NIGHT_SHIFT_END_HOUR
  end

  def update_out_time_per_day
    (1..(@workdays + @rest_days)).each do |day|
      print "Enter OUT time for Day #{day} (in military time format, e.g., 1800): "
      @out_times[day] = gets.chomp
    end
    puts "OUT times updated successfully."
  end

  def update_holidays
    (1..@workdays).each do |day|
      choose_holiday_type(day)
    end
    puts "Holidays updated successfully."
  end

  def revert_to_default_settings
    @daily_salary = 500.0
    @regular_hours = 8
    @workdays = 5
    @rest_days = 2
    @out_times = Hash.new("0900")
    @holidays = {}
    @settings_changed = false
  end

  def update_settings
    print "Do you want to update default settings? (yes/no): "
    choice = gets.chomp.downcase

    if choice == "yes"
      configure_payroll_settings
    else
      puts "Default settings will be used for this payroll generation."
    end
  end

  def display_summary(total_salary, regular_days_present, rest_days_present, regular_days_absent, rest_days_absent)
    puts "\nWeekly Payroll Summary for #{@employee_name}"
    puts "Number of (Regular) Days Present: #{regular_days_present}"
    puts "Number of (Rest) Days Present: #{rest_days_present}"
    puts "Number of (Regular) Days Absent: #{regular_days_absent}"
    puts "Number of (Rest) Days Absent: #{rest_days_absent}"
    puts "Total Hours Overtime (Night Shift Overtime): #{total_overtime_hours}"
    puts "--------------------------------------------------------"
    puts "Total Salary for the Week: #{'%.2f' % total_salary}"
  end

  def total_overtime_hours
    (1..(@workdays + @rest_days)).sum do |day|
      next unless @out_times[day] != "0900"

      worked_hours = calculate_worked_hours("0900", @out_times[day])
      [0, worked_hours - @regular_hours].max
    end
  end
end

# Main program
weekly_payroll_system = WeeklyPayrollSystem.new

loop do
  weekly_payroll_system.display_menu
  choice = gets.chomp.to_i

  case choice
  when 1
    weekly_payroll_system.generate_payroll
  when 2
    weekly_payroll_system.configure_payroll_settings
  when 3
    puts "Exiting Weekly Payroll System."
    break
  else
    puts "Invalid option. Please enter a valid option."
  end
end