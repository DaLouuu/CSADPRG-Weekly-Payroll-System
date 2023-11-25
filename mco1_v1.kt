
import java.util.Calendar

class Payroll{
    val dailyRate = 500.00
    val inTime = "0900"
    var outTime = "1700" //0900 by default
    var dayType = "Normal" //normal by default
    var overTimeHours = "0 (0)" // by default
    var dDayHour = 0
    var dNightHours = 0
    var salary = 500.00
}

fun changeOutTime(payroll : Payroll, outTime : String){
    payroll.outTime = outTime
}

fun changeDayType (payroll : Payroll, dayType : String){
    payroll.dayType = dayType
}

fun changeOverTimeHours(payroll: Payroll, overtime : String){
    payroll.overTimeHours = overtime
}

fun calculateOverTime(payroll : Payroll){
    var inTimeStr = payroll.inTime
    var outTimeStr = payroll.outTime
    var othours = 0
    try{
        //change input to hours and minutes
        val inHours = inTimeStr.substring(0, 2).toInt()
        val inMinutes = inTimeStr.substring(2, 4).toInt()

        val outHours = outTimeStr.substring(0, 2).toInt()
        val outMinutes = outTimeStr.substring(2, 4).toInt()

        //calculate the difference in minutes
        var inTimeMinutes = inHours * 60 + inMinutes
        var outTimeMinutes = outHours * 60 + outMinutes

        //so that there is no negative
        if (outTimeMinutes < inTimeMinutes) {
            outTimeMinutes += 24 * 60 // Add 24 hours to consider the next day
        }

        val minutesPassed = outTimeMinutes - inTimeMinutes

        // Convert minutes to hours
        val hoursPassed = minutesPassed / 60

        println("Number of hours passed: $hoursPassed")

        if (hoursPassed > 9) {
            othours = hoursPassed - 9
            println("Number of hours Overtime: $othours")
            payroll.dDayHour = othours
            payroll.overTimeHours = "$othours (0)"
        }

        if (outTimeStr.toInt() > 2200 || outTimeStr.toInt() <= 600) {
            println("There is nightshift overtime")

            // Calculate overtime day (night)
            val nightShHours = othours - 4
            val dayShHours = othours - nightShHours
            payroll.dDayHour = dayShHours
            payroll.dNightHours = nightShHours
            println("Hours nightshift: $nightShHours")
            println("Total hours ot: $dayShHours ($nightShHours)")
            payroll.overTimeHours = "$dayShHours ($nightShHours)"

        }


    }catch (e : Exception){
        println("INVALID input. Please use HHMM format")
    }
}

fun displayWeeklyPayRoll(payrollList : Array<Payroll>){
    var day = 1
    for(payroll in payrollList){
        println("-------------------")
        println("Day : $day")
        println("Daily Rate : ${payroll.dailyRate}")
        println("In Time: ${payroll.inTime}")
        println("Out Time; ${payroll.outTime}")
        println("Day Type: ${payroll.dayType}")
        println("Overtime Hours (Night Hours): ${payroll.overTimeHours}")
        println("Salary: ${payroll.salary}")
        println("-------------------")
        day++
    }

}

fun displayInOutTime(payrollList : Array<Payroll>){
    var day = 1
    for(payroll in payrollList){
        println("[$day]-------------")
        println("In Time: ${payroll.inTime}")
        println("Out Time; ${payroll.outTime}")
        println("-------------------")
        day++
    }
}

fun displayDayType(payrollList : Array<Payroll>){
    var day = 1
    for(payroll in payrollList){
        println("[$day]-------------")
        println("Day type: ${payroll.dayType}")
        println("-------------------")
        day++
    }
}

fun getRateNoOT(dType : String) : Double{
    when(dType.lowercase()){
        "rest" -> {
            return 1.30
        }
        "snwd" ->{
            return 1.30
        }
        "snwdr" -> {
            return 1.50
        }
        "rh"-> {
            return 2.00
        }
        "rht" -> {
            return 2.60
        }
        else -> {
            return 1.00
        }

    }
}

fun getOTDayRate(dType : String) : Double{
    when(dType.lowercase()){
        "normal" -> {
            return 1.25
        }
        "rest" -> {
            return 1.69
        }
        "snwh" -> {
            return 1.69
        }
        "snwhr" -> {
            return 1.95
        }
        "rh" -> {
            return 2.60
        }
        "rhr" -> {
            return 3.38
        }
        else -> {
            return 1.00
        }
    }
}

fun getOTNightRate(dType : String) : Double{
    when(dType.lowercase()){
        "normal" -> {
            return 1.375
        }
        "rest" -> {
            return 1.859
        }
        "snwh" -> {
            return 1.859
        }
        "snwhr" -> {
            return 2.145
        }
        "rh" -> {
            return 2.860
        }
        "rhr" -> {
            return 3.718
        }
        else -> {
            return 1.00
        }
    }
}

fun computeSalary(payroll : Payroll){
    //which condition
    if(payroll.dDayHour > 0){
        //there is overtime
        if(payroll.dNightHours > 0){
            //there is overtime night hours
            var dayincrease = payroll.dDayHour * (payroll.dailyRate/8) * getOTDayRate(payroll.dayType)
            var nightincrease = payroll.dNightHours * (payroll.dailyRate/8) * getOTNightRate(payroll.dayType)
            payroll.salary = payroll.dailyRate + dayincrease + nightincrease
        }
        else{
            var dayincrease = payroll.dDayHour * (payroll.dailyRate/8) * getOTDayRate(payroll.dayType)
            payroll.salary = payroll.dailyRate + dayincrease
        }
    }
    else{
        //no overtime
        var increase = (payroll.dailyRate/8) * getRateNoOT(payroll.dayType)
        payroll.salary = payroll.dailyRate + increase
    }
}

fun main() {
    println("Payroll for the week")

    //day 1
    var pDay1 = Payroll()
    //day 2
    var pDay2 = Payroll()
    //day 3
    var pDay3 = Payroll()
    //day 4
    var pDay4 = Payroll()
    //day 5
    var pDay5 = Payroll()
    //day 6
    var pDay6 = Payroll()
    changeDayType(pDay6, "Rest")
    changeOutTime(pDay6, "0900")
    //day 7
    var pDay7 = Payroll()
    changeDayType(pDay7, "Rest")
    changeOutTime(pDay7, "0900")

    //put in array
    var payrollArray = arrayOf(pDay1, pDay2, pDay3, pDay4, pDay5, pDay6, pDay7)

    // for displaying
    //displayWeeklyPayRoll(payrollArray)
    var choice = -1

    while (choice != 4) {
        println("Welcome to Payroll Simulation!")
        println("Choose an action to perform:")
        println("[1] View Current Payroll")
        println("[2] Change Out Time")
        println("[3] Change Day Type")
        println("[4] Exit")

        // Read a line of input as a String
        val inputString = readLine()

        // Convert the String to an Int
        choice = inputString?.toIntOrNull() ?: -1

        if (choice == null) {
            println("Invalid input. Please enter a valid number.")
        } else {
            when (choice) {
                1 -> {
                    // View current payroll
                    displayWeeklyPayRoll(payrollArray)
                }
                2 -> {
                    // Change out time
                    var choice1 = -1
                    while (!(choice1 in 1..7)) {
                        displayInOutTime(payrollArray)

                        var inputChoice1 = readLine()
                        choice1 = inputChoice1?.toIntOrNull() ?: -1

                        if (!(choice1 in 1..7)) {
                            println("The number you inputted is invalid, please try again")
                        }
                    }

                    println("You picked day $choice1")
                    print("Enter out time: ")
                    var inputOutTime = readLine()

                    inputOutTime = inputOutTime ?: "1700" // Default 5:00 PM
                    var choosePayroll = payrollArray[choice1 - 1]

                    println("changing out time to $inputOutTime")
                    changeOutTime(choosePayroll, inputOutTime)

                    calculateOverTime(choosePayroll)
                    //compute salary
                    computeSalary(choosePayroll)

                }
                3 -> {
                    // Change day type
                    var choice1 = -1
                    while (!(choice1 in 1..7)) {
                        displayDayType(payrollArray)

                        var inputChoice1 = readLine()
                        choice1 = inputChoice1?.toIntOrNull() ?: -1

                        if (!(choice1 in 1..7)) {
                            println("The number you inputted is invalid, please try again")
                        }
                    }

                    println("You picked day $choice1")
                    print("Enter day type: ")
                    var inputDayType = readLine()

                    inputDayType = inputDayType ?: "Normal" // Default normal
                    var choosePayroll = payrollArray[choice1 - 1]

                    changeDayType(choosePayroll, inputDayType)

                    //compute salary
                    computeSalary(choosePayroll)
                }
                4 -> {
                    println("Now exiting the program")
                }
                else -> {
                    println("Invalid choice. Please choose a valid option.")
                }
            }
        }
    }

}