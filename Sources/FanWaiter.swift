//
//  FanWaiter.swift
//  NewFan
//
//  Created by 赵少龙 on 2016/12/8.
//
//
import Foundation

enum FanCommandType {
    case week
    case weekDay
    case weekDayError
    case offsetDay
    case offsetDayError
    case explicitDay
    case explicitDayError
    
    var checkPattern: String {
        switch self {
        case .week:
            return "^(\\+\\+)|(\\-\\-)$"
        case .weekDay:
            return "^(\\+|\\-)[1-5]$"
        case .weekDayError:
            return "^(\\+|\\-)(0|[6-9])(\\d)*$"
        case .offsetDay:
            return "^(\\+|\\-)((今天)|(明天)|(后天)|(大后天)|(大大后天))$"
        case .offsetDayError:
            return "^(\\+|\\-)((昨天)|((大)*前天)|(大(3,)后天))$"
        case .explicitDay:
            return "(^\\+|\\-)(([1-9]|(0[1-9])|(1[0-2])).([1-9]|([1-2][0-9])|(3[0-1])))$"
        case .explicitDayError:
            return "(^\\+|\\-)(\\d+).(\\d+)$"
        }
    }
    
    static func getFanCommandTypeAndConstant(fromStr str: String) -> (FanCommandType, Int)? {
        if str =~ week.checkPattern {
            return (week, str == "++" ? 0 : -1)
        } else if str =~ weekDay.checkPattern {
            let n = Int(str)!
            return (weekDay, n)
        } else if str =~ weekDayError.checkPattern {
            let n = Int(str)!
            return (weekDayError, n)
        } else if str =~ offsetDay.checkPattern {
            let (multiplier, value) = splitCommand(str: str)
            print("multiplier: \(multiplier), value:\(value)")
            var n = offsetDayDict[value]!
            if multiplier == -1 && n == 0 {
                n = 9999
            }
            return (offsetDay, multiplier * n)
        } else if str =~ offsetDayError.checkPattern {
            //let (multiplier, value) = splitCommandStr(str)
            let n = str.characters.contains("后") ? 0 : -1
            return (offsetDayError,  n)
        } else if str =~ explicitDay.checkPattern {
            let (multiplier, value) = splitCommand(str: str)
            let nums = value.components(separatedBy: ".")
            var n = 0
            if nums.count == 2 {
                n = Int(nums[0])! * 100 + Int(nums[1])!
            }
            return (explicitDay, multiplier * n)
        } else if str =~ explicitDayError.checkPattern {
            return (explicitDayError, 0)
        } else {
            return nil
        }
    }
}

struct FanCommand {
    var type: FanCommandType
    var constant: Int
    static func getCommandFrom(str: String) -> FanCommand? {
        if let (type, constant) = FanCommandType.getFanCommandTypeAndConstant(fromStr: str) {
            return FanCommand(type: type, constant: constant)
        }
        return nil
    }
    
    // TODO:
    func executedReport(user: String) -> (Bool, String) {
        guard var planManager = PlanManager() else {
            return (false, "PlanManager doesn't work..")
        }
        var success = true
        var report = ""
        
        switch type {
        case .week:
            if constant < 0 {
                return planManager.cancelWeekPlanFor(user)
            } else {
                return planManager.addWeekPlanFor(user)
            }
        case .weekDay:
            if constant < 0 {
                return planManager.cancelWeekDayPlanFor(user, withDay: -constant)
            } else {
                return planManager.addWeekDayPlanFor(user, withDay: constant)
            }
        case .offsetDay:
            if constant < 0 {
                return planManager.cancelOffsetDayPlanFor(user, withOffset: -constant)
            } else {
                return planManager.addOffsetDayPlanFor(user, withOffset: constant)
            }
        case .explicitDay:
            if constant < 0 {
                return planManager.cancelExplicitDayPlanFor(user, withDay: -constant)
            } else {
                return planManager.addExplicitDayPlanFor(user, withDay: constant)
            }
        case .explicitDayError:
            print("type check explicitdayerror!")
            success = false
            report = "指定的日期格式不对"
        default:
            return (false, "哎呦，命令是错的，你是想测试晚饭君的智商吗 (ÒωÓױ)")
        }
        return (success, report)
    }
}

enum CommandMode {
    case fanPlan(FanCommand)
    case userName(String)
    case help
    case list
    case unknown
    
    init(commandStr: String) {
        print("commandMode Init  commandStr:\(commandStr)")
        if commandStr == "help" {
            self = .help
        } else if commandStr == "list" {
            self = .list
        } else if let command = FanCommand.getCommandFrom(str: commandStr) {
            self = .fanPlan(command)
        } else {
            self = .unknown
        }
    }
}

let commandHelpStr = "**偶尔忘记点饭而挨饿?忘记取消点饭而浪费粮食?让智能晚饭君来拯救你**\n**自从有了智能晚饭君，麻麻再也不用担心我的晚饭啦。**\n**晚饭君使用指南:**" + "\n- `fan ++` or `fan --`    每个工作日自动点饭 or 不自动点饭 \n- `fan +n` or `fan -n`    n = [1, 5] 每周n点饭 or 不点饭  例如: fan +1\n- `fan +今天` or `fan -今天`    明天点饭 or 不点饭\n- `fan +明天` or `fan -明天`    明天点饭 or 不点饭\n- `fan +后天` or `fan -后天`    后天点饭 or 不点饭\n- `fan +大后天` or `fan -大后天`    大后天点饭 or 不点饭\n- `fan +大大后天` or `fan -大大后天`    大大后天点饭 or 不点饭\n- `fan +Month.day` or `fan -Month.day`    Month.day那天点饭 or 不点饭\n- `fan XX help 某某`    帮某某自动点饭或者取消点饭 XX为以上任意命令\n- `fan list` 查看今天点了晚饭的人"

class FanWaiter {
    static func handleFanPlanWith(commandStr: String, userName: String) -> String {
        var commands: [FanCommand] = []
        var others: [String] = []
        var isHelpOthers = false
        var responseStr = ""
        if commandStr == "fan" {
            return commandHelpStr
        }
        var strs = commandStr.components(separatedBy: " ")
        strs.removeFirst()
        for commandStr in strs {
            let cmd = CommandMode(commandStr: commandStr)
            switch cmd {
            case .help:
                isHelpOthers = true
            case .fanPlan(let cmd):
                commands.append(cmd)
            case .list:
                return dailyReport()
            default:
                if isHelpOthers {
                    others.append(commandStr)
                }
            }
        }
        
        if commands.isEmpty {
            return "命令解析失败，请参考命令手册输入正确的命令。输入`fan`查看手册"
        }
        
        if isHelpOthers && others.isEmpty {
            return "请输入需要帮助的人的姓名"
        }
        
        if others.isEmpty {
            others.append(userName)
        }
        for user in others {
            for cmd in commands {
                let (success, report) = cmd.executedReport(user: user)
                if !success {
                    responseStr = report
                    break
                } else {
                    responseStr = user + "," + report + "\n" + dailyReport()
                }
            }
        }
        return responseStr
        //return "\(userName): \(commandStr)"
    }
    
    static func dailyReport() -> String {
        guard let planManager = PlanManager() else {
            return "暂时没有任何点饭计划"
        }
        return planManager.getTodayPlanReport()
    }
}
