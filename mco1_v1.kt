
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

fun isOverTime(inTime : String, outTime : String) : Boolean{
    val calInTime = toMilitaryTime(inTime)
    val calOutTime = toMilitaryTime(outTime)

    val workDurationInMins = calculateDuration(calInTime, calOutTime)

    if(workDurationInMins <= 8 * 60){
        return true
    }
    else{
        return false
    }
}

fun toMilitaryTime(timeStr : String): Calendar{
    val calendar = Calendar.getInstance()
    val hour = timeStr.substring(0, 2).toInt()
    val min = timeStr.substring(2, 4).toInt()
    calendar.set(Calendar.HOUR_OF_DAY, hour)
    calendar.set(Calendar.MINUTE, min)
    return calendar;
}

fun calculateDuration(inTime : Calendar, outTime : Calendar) : Int{
    return ((outTime.timeInMillis - inTime.timeInMillis) / (1000 * 60)).toInt()
}

fun calculateOverTime(inTime: String, outTime: String): String {
    val calInTime = toMilitaryTime(inTime)
    val calOutTime = toMilitaryTime(outTime)

    val workDurationInMins = calculateDuration(calInTime, calOutTime)

    val normalWorkDuration = 8 * 60 // 8 hours in minutes
    val overTimeMinutes = maxOf(workDurationInMins - normalWorkDuration, 0)

    val overTimeHours = overTimeMinutes / 60

    return overTimeHours.toString()
}

fun splitOvertime(payroll: Payroll, overtimeHours : Int) : String{
    val pOutTime = payroll.outTime.toInt()
    if(pOutTime >= 2200 || (pOutTime >= 0 && pOutTime < 600)){
        //night shift
        val nightShiftEnd = if (pOutTime >= 0 && pOutTime < 600) 600 else 2200
        val nightShiftHours = minOf(overtimeHours, maxOf(0, nightShiftEnd - pOutTime))
        val dayShiftHours = overtimeHours - nightShiftHours

        payroll.dDayHour = dayShiftHours
        payroll.dNightHours = nightShiftHours

        return "$dayShiftHours ($nightShiftHours)"
    }
    else{
        payroll.dDayHour = overtimeHours
        return "$overtimeHours (0)"
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
    var pOutTime = payroll.outTime
    var pInTime = payroll.inTime
    var dRate = payroll.dailyRate
    var dType = payroll.dayType
    var pSalary = payroll.salary

    //compute if there are any overtime hours
    var otHours = calculateOverTime(pInTime, pOutTime)
    println("ot hours : $otHours")

    //split overtime
    var splitOT = splitOvertime(payroll, otHours.toInt())
    var dDay = payroll.dDayHour
    var dNight = payroll.dNightHours
    println("day hours : $dDay")
    println("night hours : $dNight")
    //put split in payroll class
    changeOverTimeHours(payroll, splitOT)

    //conditions
    if(otHours.toInt() > 0){
        //there is overtime
        if(dNight > 0){
            //may nightshift
            val withDayIncrease = dDay * (dRate/8) * getOTDayRate(dType)
            val withNightIncrease = dNight * (dRate/8) * getOTNightRate(dType)
            pSalary = pSalary + withDayIncrease + withNightIncrease
            payroll.salary = pSalary
        }
        else{
            //no nightshift
            println(getOTDayRate(dType))
            val withDayIncrease = dDay * (dRate/8) * getOTDayRate(dType)
            payroll.salary = pSalary + withDayIncrease
        }
    }
    else{
        //no overtime
        pSalary = pSalary + ((dRate / 8) * getRateNoOT(dType))
        payroll.salary = pSalary
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

                   // println("now computing for overtime")
                    // compute overtime hours
                    //var otHours = calculateOverTime(choosePayroll.inTime, choosePayroll.outTime)
                    //println("overtime hours: $otHours")
                    // split to string

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