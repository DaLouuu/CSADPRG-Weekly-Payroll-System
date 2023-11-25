package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"
)

type Configuration struct {
	DailySalary      float64
	RegularWorkHours int
}

const (
	RegularShiftStart = 900
	RegularShiftEnd   = 2200
	NightShiftStart   = 2200
	NightShiftEnd     = 600
)

func isValidTimeFormat(timeStr string) bool {
	if timeStr == "0000" {
		return true
	}

	_, err := time.Parse("1504", timeStr)
	return err == nil
}

// This function is for calculating the overtime salary for Regular Days
func calculateOvertimeSalary(overTime int, hourlyRate float64, isNightShiftOT bool, nightOverTime int, holidayType string) float64 {
	overtimeRate := 1.25
	if isNightShiftOT {
		overtimeRate = 1.375 // Adjust the night shift overtime rate
		return float64(nightOverTime)*hourlyRate*overtimeRate + 312.50
	}
	if holidayType == "HD" {
		overtimeRate := 2.6
		return float64(overTime) * hourlyRate * overtimeRate
	}

	return float64(overTime) * hourlyRate * overtimeRate
}

func calculateOvertimeSalaryRestDay(overTime int, hourlyRate float64, isNightShiftOT bool, nightOverTime int) float64 {
	overtimeRate := 1.69
	if isNightShiftOT {
		overtimeRate = 1.859 // Adjust the night shift overtime rate
		return float64(nightOverTime)*hourlyRate*overtimeRate + 422.50
	}

	return float64(overTime) * hourlyRate * overtimeRate
}

func calculateNightShiftHours(startTime, endTime string) int {
	// Convert start and end times to integers
	startTimeInt, _ := strconv.Atoi(startTime)
	endTimeInt, _ := strconv.Atoi(endTime)

	// If end time is "0000," adjust it to "2400"
	if endTimeInt == 0 {
		endTimeInt = 2400
	}

	// Check if the start time is after 2200 (considered as night shift start)
	if startTimeInt >= 2200 {
		// Calculate the night shift hours between 2200 and the end time
		nightShiftHours := endTimeInt - 2200
		if nightShiftHours < 0 {
			nightShiftHours += 2400
		}
		return nightShiftHours
	} else if startTimeInt < 2200 && endTimeInt < 600 {
		// Check if the shift spans across midnight
		// Calculate the night shift hours between 2200 and 0600
		nightShiftHours := endTimeInt + (2400 - 2200)
		return nightShiftHours
	}

	return 0 // No night shift hours if start time is before 2200 and end time is after 0600
}

func generatePayroll(config Configuration, day int, employeeName string, startTime string, endTime string, holidayType string) {
	fmt.Printf("\nGenerating Pay Roll for Day %d...\n", day)

	isHoliday := holidayType != ""
	isRestDay := day == 6 || day == 7

	duration, err := calculateDuration(startTime, endTime)
	if err != nil {
		fmt.Println("Error:", err)
		os.Exit(1)
	}

	workHours := int(duration.Hours()) - 1
	if workHours < 0 {
		workHours += 24
	}

	minutes := int(duration.Minutes()) % 60
	if endTime == "0000" {
		minutes += 1
		if minutes == 60 {
			minutes = 0
			workHours += 1
		}
	}

	fmt.Printf("Employee: %s\n", employeeName)
	fmt.Printf("Work Duration: %d hours %d minutes\n", workHours, minutes)

	overTime := workHours - config.RegularWorkHours
	isNightShiftOT := false
	nightOverTime := 0
	/**------------------------------  HOLIDAY -----------------------------------------------------------***/
	if !isRestDay && overTime <= 4 && startTime == "0900" && holidayType == "HD" && isHoliday { // Regular Day with OT - Non-Night Shift
		fmt.Println("=================================")
		overtimeSalary := calculateOvertimeSalary(overTime, config.DailySalary/float64(config.RegularWorkHours), isNightShiftOT, nightOverTime, holidayType)
		fmt.Printf("Daily Rate: %.2f\n", config.DailySalary)
		fmt.Printf("Hours Overtime (Night Shift Overtime): %d (%d)\n", overTime, nightOverTime)
		fmt.Printf("Salary for the day: %.2f\n", overtimeSalary+config.DailySalary)
		fmt.Println("\n=================================")
	}

	/**------------------------------  REST DAYS -----------------------------------------------------------***/

	if isRestDay && overTime <= 4 && startTime == "0900" && !isHoliday { // Rest Day with OT - Non-Night Shift
		fmt.Println("==================================")
		overtimeSalary := calculateOvertimeSalaryRestDay(overTime, config.DailySalary/float64(config.RegularWorkHours), isNightShiftOT, nightOverTime)
		fmt.Printf("Daily Rate: %.2f\n", config.DailySalary)
		fmt.Printf("Hours Overtime (Night Shift Overtime): %d (%d)\n", overTime, nightOverTime)
		fmt.Printf("Salary for the day: %.2f\n", overtimeSalary+config.DailySalary)
		fmt.Println("\n=================================")
	}

	if isRestDay && overTime > 4 && startTime == "0900" && !isHoliday { // Rest Day with OT - Night Shift
		isNightShiftOT = true
		nightOverTime = overTime - 4
		overTime = 4
		overtimeSalary := calculateOvertimeSalaryRestDay(overTime, config.DailySalary/float64(config.RegularWorkHours), isNightShiftOT, nightOverTime)
		fmt.Println("=================================")
		fmt.Printf("Daily Rate: %.2f\n", config.DailySalary)
		fmt.Printf("Hours Overtime (Night Shift Overtime): %d (%d)\n", overTime, nightOverTime)
		fmt.Printf("Salary for the day: %.2f\n", overtimeSalary+config.DailySalary)
		fmt.Println("\n=================================")
	}

	/**------------------------------  REGULAR DAYS -----------------------------------------------------------***/

	if !isRestDay && startTime >= "1800" && !isHoliday { // Night Shift With Over Time
		nightShiftHours := calculateNightShiftHours(startTime, endTime) / 100
		fmt.Println("=================================")
		fmt.Printf("\nDaily Rate: %.2f\n", config.DailySalary)
		fmt.Printf("Night Shift Hours Covered: %d hours\n", nightShiftHours)
		nightShiftPay := float64(nightShiftHours)*config.DailySalary/float64(config.RegularWorkHours)*1.10 + config.DailySalary
		fmt.Printf("Salary for the day: %.2f \n", nightShiftPay)
		fmt.Println("\n=================================")
	}

	if !isRestDay && overTime <= 4 && startTime == "0900" && !isHoliday { // Regular Day with OT - Non-Night Shift
		fmt.Println("=================================")
		overtimeSalary := calculateOvertimeSalary(overTime, config.DailySalary/float64(config.RegularWorkHours), isNightShiftOT, nightOverTime, holidayType)
		fmt.Printf("Daily Rate: %.2f\n", config.DailySalary)
		fmt.Printf("Hours Overtime (Night Shift Overtime): %d (%d)\n", overTime, nightOverTime)
		fmt.Printf("Salary for the day: %.2f\n", overtimeSalary+config.DailySalary)
		fmt.Println("\n=================================")
	}

	if !isRestDay && overTime > 4 && startTime == "0900" && !isHoliday { // Regular Day with OT - Night Shift
		isNightShiftOT = true
		nightOverTime = overTime - 4
		overTime = 4
		overtimeSalary := calculateOvertimeSalary(overTime, config.DailySalary/float64(config.RegularWorkHours), isNightShiftOT, nightOverTime, holidayType)
		fmt.Println("=================================")
		fmt.Printf("Daily Rate: %.2f\n", config.DailySalary)
		fmt.Printf("Hours Overtime (Night Shift Overtime): %d (%d)\n", overTime, nightOverTime)
		fmt.Printf("Salary for the day: %.2f\n", overtimeSalary+config.DailySalary)
		fmt.Println("\n=================================")
	}

}

func calculateDuration(startTime, endTime string) (time.Duration, error) {
	if !isValidTimeFormat(startTime) || !isValidTimeFormat(endTime) {
		return 0, fmt.Errorf("invalid time format. Please enter time in HHMM format")
	}

	// Adjust the format to consider the case where OUT time is 0000
	if endTime == "0000" {
		endTime = "2359"
	}

	const timeFormat = "1504"

	startTimeParsed, err := time.Parse(timeFormat, startTime)
	if err != nil {
		return 0, err
	}

	endTimeParsed, err := time.Parse(timeFormat, endTime)
	if err != nil {
		return 0, err
	}

	// Calculate the duration
	duration := endTimeParsed.Sub(startTimeParsed)

	return duration, nil
}

func main() {
	config := Configuration{
		DailySalary:      500,
		RegularWorkHours: 8,
	}

	for {
		fmt.Println("\nPayroll Menu")
		fmt.Println("\n1. Generate Pay Roll")
		fmt.Println("\n2. Generate Pay Roll")
		fmt.Println("3. Exit")
		fmt.Print("Select an option: ")

		var choice int
		fmt.Scanln(&choice)

		switch choice {
		case 1:
			fmt.Print("Enter Employee Name: ")
			scanner := bufio.NewScanner(os.Stdin)
			scanner.Scan()
			employeeName := scanner.Text()

			for day := 5; day <= 7; day++ {
				if day == 6 || day == 7 {
					fmt.Printf("\n\nToday is Day %d (Rest Day)\n", day)
				} else {
					fmt.Printf("\n\nToday is Day %d\n", day)
				}
				fmt.Print("Is today a Holiday or Special-Non Working Holiday? (Y/N): ")
				var holidayInput string
				fmt.Scanln(&holidayInput)
				holidayInput = strings.ToUpper(strings.TrimSpace(holidayInput))

				var holidayType string // Declare holidayType here
				if holidayInput == "Y" {
					fmt.Print("Is it a Holiday (HD) or Special-Non Working Holiday (SNWH)? (HD/SNWH): ")
					fmt.Scanln(&holidayType)
					holidayType = strings.ToUpper(strings.TrimSpace(holidayType))

					if holidayType != "HD" && holidayType != "SNWH" {
						fmt.Println("Invalid holiday type. Please enter HD or SNWH.")
						return
					}
				}

				fmt.Print("Enter IN Time (HHMM): ")
				var startTime string
				fmt.Scanln(&startTime)

				fmt.Print("Enter OUT Time (HHMM): ")
				var endTime string
				fmt.Scanln(&endTime)

				if !isValidTimeFormat(startTime) || !isValidTimeFormat(endTime) {
					fmt.Println("Invalid time format. Please enter time in HHMM format.")
					return
				}
				generatePayroll(config, day, employeeName, startTime, endTime, holidayType)
			}
		case 2:
			fmt.Println("Exiting the system.")
			return
		default:
			fmt.Println("Invalid option. Please try again.")
		}
	}
}
