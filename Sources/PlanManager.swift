//
//  PlanManager.swift
//  NewFan
//
//  Created by 赵少龙 on 2016/12/11.
//
//

import Foundation
import PerfectLib

let occurBugReport = "哎呀，不好，粗bug啦 (⊙０⊙) "
let saveFailedReport = (false, occurBugReport)
let notImplementedReport = (false, "planManager's method has not been implemented..")

//制定计划的type
enum PlanType {
    case add    //添加计划
    case cancel //取消计划
}

struct PlanManager {
    var planDict: [String: Any]
    let planFile: File
    
    struct PlanKeySuit {
        let planKey: String
        let opposedPlanKey: String
    }
    
    init?() {
        planFile = File("./plan.config")
        print("plan path: \(planFile.path)")
        guard let _ = try? planFile.open(.readWrite) else {
            print("open file failed..")
            return nil
        }
        guard var planString = try? planFile.readString() else {
            print("read plan failed..")
            planFile.close()
            return nil
        }
        planFile.close()
        
        if planString.isEmpty {
            planString = "{\"initialized\": true}"
        }
        guard let planJson = try? planString.jsonDecode() else {
            print("planString jsonDecoded failed...")
            return nil
        }
        guard let planDict = planJson as? [String: Any] else {
            print("planDict initial failed...")
            return nil
        }
        self.planDict = planDict
    }
    
    private func save() -> Bool {
        print("save planing....")
        print("plan: \(planDict)")
        if let jsonStr = try? planDict.jsonEncodedString() {
            try! planFile.open(.write)
            defer {
                planFile.close()
            }
            if let _ = try? planFile.write(string: jsonStr) {
                return true
            }
            print("plan write failed...")
            return false
        }
        print("dictionary jsonencode failed..")
        return false
    }
    /*
     * TODO: need add comment
     */
    mutating func addWeekPlanFor(_ user: String) -> (Bool, String) {
        if var plan = planDict[user] as? [String: Any] {
            if let hasWeekPlan = plan["week"] as? Bool, hasWeekPlan == true {
                return (true, "\(user)之前已经订过工作日的计划了哦,我是不会忘哒（＾ω＾）")
            } else {
                plan["week"] = true
                planDict[user] = plan
                if save() {
                    return (true, "\(user)工作日点晚餐的工作就交给智能晚饭君啦 (ง •̀_•́)ง")
                } else {
                    return saveFailedReport
                }
            }
        } else {
            planDict[user] = ["week": true]
            if save() {
                return (true, "\(user)工作日点晚餐的工作就交给智能晚饭君啦 (ง •̀_•́)ง")
            } else {
                return saveFailedReport
            }
        }
    }
    mutating func cancelWeekPlanFor(_ user: String) -> (Bool, String) {
        if var plan = planDict[user] as? [String: Any] {
            if plan["week"] == nil || plan["week"]! as! Bool == false {
                return (true, "哎呦，\(user)之前还没有制定过点饭计划哦 (oﾟωﾟo)")
            }
            plan["week"] = false
            planDict[user] = plan
            if save() {
                return (true, "已经帮\(user)取消了工作日点饭计划，再来哦 ...(｡•ˇ‸ˇ•｡) ...")
            } else {
                return (false, occurBugReport)
            }
        } else {
            return (true, "哎呦，\(user)之前还没有制定过点饭计划哦 (oﾟωﾟo)")
        }
    }
    mutating func addWeekDayPlanFor(_ user: String, withDay day: Int) -> (Bool, String) {
        if var plan = planDict[user] as? [String: Any] {
            if let hasWeekPlan = plan["week"] as? Bool, hasWeekPlan == true {
                if var exceptWeekDayPlan = convertIntArray(plan["exceptWeekDay"]) {
                    if let idx = exceptWeekDayPlan.index(of: day) {
                        exceptWeekDayPlan.remove(at: idx)
                        plan["exceptWeekDay"] = exceptWeekDayPlan
                        planDict[user] = plan
                        if save() {
                            return (true, "成功预订了每" + getDespOf(weekday: day) + "的晚饭")
                        } else {
                            return saveFailedReport
                        }
                    }
                }
                return (true, "已经有了每个工作日的订饭计划，不需要再单独添加星期几的计划哦")
            }
            if var weekDayPlan = convertIntArray(plan["weekDay"]) {
                if weekDayPlan.contains(day) {
                    return (true, "已经添加过此计划啦")
                }
                if var exceptWeekDayPlan = convertIntArray(plan["exceptWeekDay"]) {
                    if let idx = exceptWeekDayPlan.index(of: day) {
                        exceptWeekDayPlan.remove(at: idx)
                        plan["exceptWeekDay"] = exceptWeekDayPlan
                        planDict[user] = plan
                    }
                }
                weekDayPlan.append(day)
                plan["weekDay"] = weekDayPlan
                planDict[user] = plan
                if save() {
                    return (true, "成功预订了每" + getDespOf(weekday: day) + "的晚饭")
                } else {
                    return saveFailedReport
                }
            } else {
                print("debugtag: not hasWeekDayPlan...")
                plan["weekDay"] = [day]
                planDict[user] = plan
                if save() {
                    return (true, "成功预订了每" + getDespOf(weekday: day) + "的晚饭")
                } else {
                    return saveFailedReport
                }
            }
        } else {
            planDict[user] = ["WeekDay": [day]]
            if save() {
                return (true, "成功预订了每" + getDespOf(weekday: day) + "的晚饭")
            } else {
                return saveFailedReport
            }
        }
    }
    mutating func cancelWeekDayPlanFor(_ user: String, withDay day: Int) -> (Bool, String) {
        if var plan = planDict[user] as? [String: Any] {
            if var exceptWeekDayPlan = convertIntArray(plan["exceptWeekDay"]) {
                if exceptWeekDayPlan.contains(day) {
                    return (true, "已经添加过此计划哦")
                }
                if var weekDayPlan = convertIntArray(plan["weekDay"]) {
                    if let idx = weekDayPlan.index(of: day) {
                        weekDayPlan.remove(at: idx)
                        plan["weekDay"] = weekDayPlan
                    }
                }
                exceptWeekDayPlan.append(day)
                plan["exceptWeekDay"] = exceptWeekDayPlan
                planDict[user] = plan
                if save() {
                    return (true, "成功取消了每" + getDespOf(weekday: day) + "的晚饭")
                } else {
                    return saveFailedReport
                }
            } else {
                plan["exceptWeekDay"] = [day]
                planDict[user] = plan
                if save() {
                    return (true, "成功取消了每" + getDespOf(weekday: day) + "的晚饭")
                } else {
                    return saveFailedReport
                }
            }
        } else {
            planDict[user] = ["exceptWeekDay": [day]]
            if save() {
                    return (true, "成功取消了每" + getDespOf(weekday: day) + "的晚饭")
            } else {
                return saveFailedReport
            }
        }
    }
    
    mutating func addOffsetDayPlanFor(_ user: String, withOffset offset: Int) -> (Bool, String) {
//        if offset == 0 {
//            return (true, "OK,今天的饭已经帮你点上啦")
//        }
        let day = getFormattedDateOffsetOfToday(with: offset)
        let keySuit = PlanKeySuit(planKey: "explicitDay", opposedPlanKey: "exceptExplicitDay")
        return makePlanFor(user, withDay: day, keySuit: keySuit)
    }
    
    mutating func cancelOffsetDayPlanFor(_ user: String, withOffset offset: Int) -> (Bool, String) {
//        if offset == 9999 {
//            return (true, "OK,今天的饭已经帮你取消喽")
//        }
        let day = getFormattedDateOffsetOfToday(with: offset == 9999 ? 0 : offset)
        let keySuit = PlanKeySuit(planKey: "exceptExplicitDay", opposedPlanKey: "explicitDay")
        return makePlanFor(user, withDay: day, keySuit: keySuit)
    }
    
    mutating func addExplicitDayPlanFor(_ user: String, withDay day: Int) -> (Bool, String) {
        let today = getFormattedDateOfToday()
        print("today: \(today)")
        if day < today {
            return (false, "指定的日期是过去的时间哦，请确认日期")
//        } else if day == today {
//            return (true, "ok,今天的饭已经帮你点上了哦")
        }
        let keySuit = PlanKeySuit(planKey: "explicitDay", opposedPlanKey: "exceptExplicitDay")
        return makePlanFor(user, withDay: day, keySuit: keySuit)
    }
    
    mutating func cancelExplicitDayPlanFor(_ user: String, withDay day: Int) -> (Bool, String) {
        let today = getFormattedDateOfToday()
        if day < today {
            return (false, "指定的日期是过去的时间哦，请确认日期")
//        } else if day == today {
//            return (true, "ok, 今天的饭已经取消了")
        }
        let keySuit = PlanKeySuit(planKey: "exceptExplicitDay", opposedPlanKey: "explicitDay")
        return makePlanFor(user, withDay: day, keySuit: keySuit)
    }
    
    mutating func makePlanFor(_ user: String, withDay day: Int, keySuit: PlanKeySuit) -> (Bool, String) {
        let planKey = keySuit.planKey
        let opposedPlanKey = keySuit.opposedPlanKey
        
        if var plan = planDict[user] as? [String: Any] {
            if var originPlan = convertIntArray(plan[planKey]) {
                if originPlan.contains(day) {
                    return (true, "已经制定过此计划哦")
                }
                if var opposedPlan = convertIntArray(plan[opposedPlanKey]) {
                    if let idx = opposedPlan.index(of: day) {
                        opposedPlan.remove(at: idx)
                        plan[opposedPlanKey] = opposedPlan
                        planDict[user] = plan
                    }
                }
                originPlan.append(day)
                plan[planKey] = originPlan
                planDict[user] = plan
                if save() {
                    return (true, "OK,计划添加成功")
                } else {
                    return saveFailedReport
                }
            } else {
                if var opposedPlan = convertIntArray(plan[opposedPlanKey]) {
                    if let idx = opposedPlan.index(of: day) {
                        opposedPlan.remove(at: idx)
                        plan[opposedPlanKey] = opposedPlan
                        planDict[user] = plan
                    }
                }
                plan[planKey] = [day]
                planDict[user] = plan
                if save() {
                    return (true, "OK, 新建计划成功")
                } else {
                    return saveFailedReport
                }
            }
        } else {
            planDict[user] = [planKey : [day]]
            if save() {
                return (true, "新建订饭计划成功")
            } else {
                return saveFailedReport
            }
        }
    }
    
    func getTodayPlanReport() -> String {
        let eaters = getTodayEaters()
        if eaters.count == 0 {
            return "今晚无人问津晚饭君"
        }
        return "今晚翻了晚饭君牌子的是: \n" + eaters.joined(separator: ",")
    }
    
    func getTodayEaters() -> [String] {
        return planDict.flatMap {
            (user, plan) -> String? in
            guard user != "initialized" else {
                return nil
            }
            guard let dict = plan as? [String: Any] else {
                return nil
            }
            let (today, weekday) = getFormattedDateOf(Date())
            if dictContains(intValue: today, ofKey: "explicitDay", dict: dict) {
                return user
            }
            if dictContains(intValue: today, ofKey: "exceptExplicitDay", dict: dict) {
                return nil
            }
            if dictContains(intValue: weekday, ofKey: "WeekDay", dict: dict) {
                return user
            }
            if dictContains(intValue: weekday, ofKey: "exceptWeekDay", dict: dict) {
                return nil
            }
            if let eatAtWorkDay = dict["week"] as? Bool,
                eatAtWorkDay {
                return user
            }
            return nil
        }
    }
    
    func dictContains(intValue: Int, ofKey: String, dict: [String: Any]) -> Bool {
        if let intArr = dict[ofKey] as? [Int],
            intArr.contains(intValue) {
            return true
        }
        return false
    }
}


func convertIntArray(_ any: Any?) -> [Int]? {
    if let anyArr = any as? [Any] {
        return anyArr.reduce([Int]()) {
            intArry, any in
            if let i = any as? Int {
                return intArry + [i]
            }
            return intArry
        }
    }
    return nil
}

func getDespOf(weekday: Int) -> String {
    guard weekday > 0 && weekday < 8 else {
        return String(weekday)
    }
    let weekDayArr = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
    return weekDayArr[weekday - 1]
}

func getFormattedDateOf(_ date: Date) -> (Int, Int) {
    let dateComponents = Calendar.current.dateComponents([.day, .month, .weekday], from: date)
    var weekday = dateComponents.weekday!
    if weekday == 1 {
        weekday = 7
    } else {
        weekday -= 1
    }
    return (dateComponents.month! * 100 + dateComponents.day!, weekday)
}

func getFormattedDateOfToday() -> Int {
    return getFormattedDateOf(Date()).0
}

func getFormattedDateOffsetOfToday(with: Int) -> Int{
    let offsetTimeInterval = TimeInterval(with * 3600 * 24)
    return getFormattedDateOf(Date().addingTimeInterval(offsetTimeInterval)).0
}

