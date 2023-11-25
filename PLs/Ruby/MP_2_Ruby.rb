=begin
********************
Last names: Brodeth, Guillarte, Llorando, Zulueta
Language: Ruby
Paradigm(s): Object Oriented, Functional, Procedural
********************
=end

# CONSTANT
HOURLY_RATE = 62.5
NON_NIGHT_SHIFT = 0
NIGHT_SHIFT = 1
NIGHT_SHIFT_TIME = [2300, 0, 100, 200, 300, 400, 500, 600]
DIFF = 1.10 # Night Shift Differential

# Day shift is from 0900 to 1800
# Night shift is from 2200 to 0600

# Displays the main menu options for the payroll system.
def display_main_menu
  puts "WEEKLY PAYROLL SYSTEM"
  puts "-------------------------"
  puts "1. Configure Employee"
  puts "2. Generate Payroll"
  puts "3. Exit the Program"
  puts "--------------------------"
  print "Select an option: "
end

# Represents a workday with specific attributes such as start time, end time, day type, and additional pay details.
class Workday

  attr_accessor :daily_wage, :start_time, :end_time, :day_type, :overtime_hours, :night_shift_hours

  # Initializes a new Workday instance with default values.
  def initialize(start_time = 900, end_time = 900, day_type = "Normal Day")
    @daily_wage = 500
    @start_time = start_time
    @end_time = end_time 
    @day_type = day_type
    @overtime_hours = 0
    @night_shift_hours = 0
  end

  # Calculates additional pay based on the start and end times of the workday.
  def calculate_additional_pay
    if (@start_time == 900 && @end_time > 2200) || (@start_time == 900 && NIGHT_SHIFT_TIME.include?(@end_time))
      @overtime_hours = 4
    elsif (@start_time == 900 && @end_time > 1800) && (@start_time == 900 && @end_time < 2200)
      @overtime_hours = (@end_time - 1800) % 1000 / 100
    end
    
    if NIGHT_SHIFT_TIME.include?(@end_time)
      @night_shift_hours = NIGHT_SHIFT_TIME.index(@end_time) + 1
    end
  end

  # Formats the workday configuration as a string for display.
  def display_config
    print "\nDAILY WAGE: #{@daily_wage}\n-------------------------------\n"
  
    if start_time < 1000
      print "Start Time: 0#{@start_time}\n"
    else
      print "Start Time: #{@start_time}\n"
    end

    if end_time < 1000
      puts "End Time: 0#{@end_time}"
    else
      puts "End Time: #{@end_time}"
    end

    puts "Day Type: #{@day_type}"
    puts "Overtime Hours: #{@overtime_hours}"
    print "Night Shift Hours: #{@night_shift_hours}"
  end
end

# Represents an employee with a name and an array of workdays for each day of the week.
class Worker

  attr_accessor :name

  @@workers = []

  # Initializes a new Worker instance with a specified name.
  def initialize(name)
    @name = name
    @workdays = Array.new(7) { Workday.new }
    @@workers << self
  end

  # Adds a workday to the employee's array of workdays for a specific day.
  def add_workday(day, workday)
    @workdays[day - 1] = workday if day >= 1 && day <= 7
  end

  # Retrieves the workday for a specific day.
  def retrieve_workday(day)
    @workdays[day - 1]
  end

  # Finds a worker by name.
  def find_worker(workers, name)
    workers.any? { |worker| worker.name == name }
  end
end

# Checks if a worker with the given name exists in the array of workers.
def find_worker(workers, name)
  workers.any? { |worker| worker.name == name }
end

# Retrieves a worker with the given name from the array of workers.
def get_worker(workers, name)
  workers.find { |worker| worker.name == name }
end

# Determines the rest holiday pay multiplier based on the type of rest day.
def rest_holiday_multiplier(type)
  case type
  when "Rest Day"
    return 1.30
  when "SNWH" # Special Non-Working Holiday
    return 1.30
  when "SNWH and Rest Day"
    return 1.50
  when "RH" # Regular Holiday
    return 2.00
  when  "RH and Rest Day"
    return 2.60
  end
end

# Determines the overtime pay multiplier based on the type of workday and shift.
def overtime_multiplier(type, is_shift)
  if is_shift == NON_NIGHT_SHIFT
    case type
    when "Normal Day"
      return 1.25
    when "Rest Day"
      return 1.69
    when "SNWH"
      return 1.69
    when "SNWH and Rest Day"
      return 1.95
    when "RH"
      return 2.60
    when  "RH and Rest Day"
      return 3.38
    end
  elsif is_shift == NIGHT_SHIFT
    case type
    when "Normal Day"
      return 1.375
    when "Rest Day"
      return 1.869
    when "SNWH"
      return 1.859
    when "SNWH and Rest Day"
      return 2.145
    when "RH"
      return 2.860
    when  "RH and Rest Day"
      return 3.718
    end
  end
end

# Program execution

workers = []

loop do
  display_main_menu
  choice = gets.chomp.to_i

  case choice
  # Configure Employee
  when 1
    puts  "\nCONFIGURE EMPLOYEE"
    print "Enter employee name: "
    name = gets.chomp


    if !find_worker(workers, name)
      workers << Worker.new(name)
      puts "New employee added!"
    end

    if find_worker(workers, name)
      worker = get_worker(workers, name)
      for day in 1..7 do
        workday = worker.retrieve_workday(day-1)

        puts "\nModifying attributes for day #{day} of Employee: #{worker.name}:\n"
        puts "Current configuration:"
        puts workday.display_config
        
        print "-------------------------------\nEnter End Time: "
        workday.end_time = gets.chomp.to_i
        
        if workday.end_time != 900
          print "Enter Day Type: "
          workday.day_type = gets.chomp
        elsif day != 6 && day != 7
          workday.day_type = "Absent"
        else
          workday.day_type = "Rest Day"
        end
        
        puts "\nModified day #{day} for Employee: #{worker.name}"
        
        workday.calculate_additional_pay
        puts workday.display_config
      end
    end
  
  # Generate Payroll
  when 2
    puts  "GENERATE PAYROLL"
    print "Enter employee name: "
    name = gets.chomp

    if find_worker(workers, name)
      worker = get_worker(workers, name)
      weekly_earnings = 0
      for i in 0..6 do
        workday = worker.retrieve_workday(i)

        print workday.display_config
        earnings = workday.daily_wage
        
        # Employee worked
        if workday.start_time == 900 && workday.end_time != 900
          if workday.day_type == "Normal Day"
            if workday.overtime_hours > 0
              earnings += workday.overtime_hours * HOURLY_RATE * overtime_multiplier(workday.day_type, 0)
            end
            
            if workday.night_shift_hours > 0
              earnings += workday.night_shift_hours * HOURLY_RATE * overtime_multiplier(workday.day_type, 1)
            end
          elsif workday.day_type != "Normal Day"
            earnings = earnings * rest_holiday_multiplier(workday.day_type)
            if workday.overtime_hours > 0
              earnings += workday.overtime_hours * HOURLY_RATE * overtime_multiplier(workday.day_type, 0)
            end
            
            if workday.night_shift_hours > 0
              earnings += workday.night_shift_hours * HOURLY_RATE * overtime_multiplier(workday.day_type, 1)
            end
          end
        # Employee did not work
        # Either they were absent or it was their rest day
        elsif workday.start_time == 900 && workday.end_time == 900
          if i == 5 || i == 6 # Rest day
            earnings = workday.daily_wage;
          else                # Absent
            earnings -= earnings
          end
        # Night shift
        elsif workday.start_time == 1800
          earnings += workday.night_shift_hours * HOURLY_RATE * DIFF
        end
        weekly_earnings += earnings
        printf "\nDay #{i+1}: " + '%.2f' % earnings + "\n\n"
      end
      puts "TOTAL WEEKLY EARNINGS: #{weekly_earnings}"
    else
      puts "Employee not found!"
    end

  when 3
    puts "Thank you for using the payroll system. Goodbye!"
    break
  else
    puts "\nInvalid option. Please try again."
  end
end
