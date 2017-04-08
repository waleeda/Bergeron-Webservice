//
//  WebService.swift
//  Bergeron Mobile
//
//  Created by waleed azhar on 2017-01-19.
//  
//
import Foundation

typealias JSONDictionary = [String: AnyObject]
typealias JSONArray = [JSONDictionary]

////////
//all api endpoint urls
struct URLS {
    
    static var main = NSURL(string: "https://redwingserver.herokuapp.com")
    
    static var book = NSURL(string: "https://redwingserver.herokuapp.com/calendar")
    
    static var delete = NSURL(string: "https://redwingserver.herokuapp.com/calendar/delete")
    
    static func checkNumber(number:Int) -> NSURL {
        return  NSURL(string: "https://redwingserver.herokuapp.com/student/12345/\(number)")!
    }
    
    static func calender(withStudentNumber:Int, duration:Int) -> NSURL {
        return NSURL(string: "https://redwingserver.herokuapp.com/calendar/12345/\(withStudentNumber)/\(duration)")!
    }
    
    static var feedBack = NSURL(string:"https://redwingserver.herokuapp.com/feedback")
    
    static var dailyMessage = NSURL(string: "https://redwingserver.herokuapp.com/dailyMessage/12345")
}

////////////
/*
 // extension to NSMutableURLRequest to create a request
 */
extension NSMutableURLRequest {
    convenience init<A>(resource: Resource<A>) {
        self.init(url: resource.url as URL)
        self.httpMethod = resource.method.method
        if case let .post(data) = resource.method {
            setValue("application/json", forHTTPHeaderField: "Content-Type")
            httpBody = data as Data
        }
    }
}

///////////
/*
 // functional http webservice
 */
enum HttpMethod<Body> {
    
    case get
    
    case post(Body)
    
}

extension HttpMethod {
    
    var method: String {
        switch self {
        case .get: return "GET"
        case .post: return "POST"
        }
    }
    
    func map<B>(f: (Body) -> B) -> HttpMethod<B> {
        switch self {
        case .get: return .get
        case .post(let body):
            return .post(f(body))
        }
        
    }
}
// represents a resource to be got from the server
struct Resource<A> {
    let url: NSURL
    let method: HttpMethod<Data>
    //turns data returned from server in to swift object of type A
    let parse: (NSData) -> A?
}

extension Resource {
    init(url: NSURL, method: HttpMethod<AnyObject> = .get, parseJSON: @escaping (AnyObject) -> A?) {
        
        self.url = url
        
        self.method = method.map { json in
            try! JSONSerialization.data(withJSONObject:json, options: [])
        }
        
        self.parse = { data in
            let json = try? JSONSerialization.jsonObject(with: data as Data, options: []) as AnyObject
            return json.flatMap(parseJSON)
        }
    }
}
// webservuce that loads a resource
final class Webservice {
    func load<A>(resource: Resource<A>, completion: @escaping (A?) -> ()) {
        let request = NSMutableURLRequest(resource: resource)
        URLSession.shared.dataTask(with: request as URLRequest) { (data, _, _) in
            guard let data = data else {
                completion(nil)
                return
            }
            completion(resource.parse(data as NSData))
            }.resume()
    }
}

////////////
struct  Student {
    let studentNumber: Int
}

extension Student{
    init?(dictionary:JSONDictionary){
        guard let id = dictionary["studentNumber"] as? String else {print("s id failed"); return nil }
        if let sid = Int(id) {
            self.studentNumber = sid
        } else {
            studentNumber = 0
        }
    }
}

struct Calendar {
    let success:Bool
    let timeSlots:[Int]
}

extension Calendar {
    enum TimeSlotState:Int {
        case available = 0, bookedByUser, unavailable, closed, past
    }
    
    
}

extension Calendar {
    init?(dictionary: JSONDictionary) {
        
        guard let message = dictionary["message"] as? JSONDictionary else {
            self.success = false
            self.timeSlots = []
            return  }
        guard let sucess = dictionary["success"] as? Bool else {
            
            self.success = false
            self.timeSlots = []
            return}
        guard let timeSlots = message["slotAvail"] as? NSArray? else {print("SS") ;return nil}
        
        self.success = sucess
        self.timeSlots = timeSlots as! [Int]
        
    }
    
}
/////////////////////////////////////

struct FeedBack {
    let serverCode:String = "a6xq1x908xl81hs67"
    let student:Student
    let feedBackContent:String
    
}
extension FeedBack{
    var json:JSONDictionary {
        return ["studentNumber": student.studentNumber as AnyObject,
                "serverCode": serverCode as AnyObject,
                "feedbackContent": feedBackContent as AnyObject]
    }
}

struct FeedBackResponse{
    let success:Bool
    let message:String
    
}
extension FeedBackResponse{
    init?(dictionary:JSONDictionary) {
        guard let success = dictionary["success"] as? Bool else { self.message = ""; self.success = false; return}
        guard let message = dictionary["message"] as? String else {self.message = "";self.success = success;  return}
        self.success = success
        self.message = message
    }
}

func giveFeedback(feedBack:FeedBack) -> Resource<FeedBackResponse> {
    let url = URLS.feedBack
    return Resource<FeedBackResponse>(url: url!, method: HttpMethod.post(feedBack.json as AnyObject), parseJSON: { (json) -> FeedBackResponse? in
        return FeedBackResponse(dictionary: json as! JSONDictionary)
    })
    
}
/////////////////////////////////////////

struct StudentNumberCheck{
    let success:Bool
    let validNumber:Bool
}

extension StudentNumberCheck{
    init?(dictionary: JSONDictionary){
        guard let message = dictionary["message"] as? String else {print("message failed"); return nil }
        guard let success = dictionary["success"] as? Bool else { print("success failed"); return nil }
        self.success = success
        
        if message == "valid"{
            self.validNumber = true
        }else {
            self.validNumber = false
        }
    }
}
/////////////////////////////////////////

struct DailyMessage{
    let success:Bool
    let message:String
}

extension DailyMessage{
    init?(dictionary: JSONDictionary){
        guard let message = dictionary["message"] as? String else {print("message failed"); return nil }
        guard let success = dictionary["success"] as? Bool else { print("success failed"); return nil }
        self.success = success
        self.message = message
    }
}
/////////////////////////////////////////

struct RoomCancellationRequest {
    let student: Student
    let sSlot: Int
    let roomN: Int
    let serverCode = "a6xq1x908xl81hs67"
}

extension RoomCancellationRequest {
    var json:JSONDictionary {
        print("makeing json")
        return ["studentNumber": student.studentNumber as AnyObject,
                "sSlot": sSlot as AnyObject,
                "roomN": roomN as AnyObject,
                "serverCode": serverCode as AnyObject]
    }
    
}

struct RoomCancellationRecipt {
    let success:Bool
    let message:JSONDictionary
    let response:String
    
}

extension RoomCancellationRecipt {
    init?(dictionary: JSONDictionary){
        
        guard let success = dictionary["success"] as? Bool else { print("success failed"); return nil }
        guard let message = dictionary["message"] as? JSONDictionary else {print("message failed"); return nil }
        guard let res = message["response"] as? String else {return nil}
        
        self.message = message
        self.success = success
        self.response = res
    }
}

extension RoomCancellationRecipt{
    static let successMessage:String = "Your room reservation has been canceled."
    static let failureMessage:String = "An error has occurred. Please see a guru if you need help booking a room!"
}

func cancelBooking(cancelationRequest: RoomCancellationRequest) -> Resource<RoomCancellationRecipt> {
    let url = URLS.delete
    return Resource<RoomCancellationRecipt>(url: url!, method: HttpMethod.post(cancelationRequest.json as AnyObject), parseJSON: { (json) -> RoomCancellationRecipt? in
        
        return RoomCancellationRecipt(dictionary: json as! JSONDictionary)
    })
    
}

/////////////////////////////////////////
struct RoomBookingRequest {
    let student: Student
    let sSlot: Int
    let nSlots: Int
    let roomN: Int
    let serverCode = "a6xq1x908xl81hs67"
}

extension RoomBookingRequest {
    var json:JSONDictionary {
        return ["studentNumber": student.studentNumber as AnyObject,
                "sSlot": sSlot as AnyObject,
                "nSlots": nSlots as AnyObject,
                "roomN": roomN as AnyObject,
                "serverCode": serverCode as AnyObject]
    }
    
}

struct RoomBookingRecipt {
    let success:Bool
    let message:String
    
    let student:Student
    let room:String
    let sSlot: Int
    let response:String
}

extension RoomBookingRecipt {
    init?(dictionary: JSONDictionary){
        guard let success = dictionary["success"] as? Bool else { return nil }
        
        if success == false {
            self.success = success
            self.message = "Failed"
            self.room = ""
            self.sSlot = -1
            self.response = ""
            self.student = Student(studentNumber: -1)
            return
        }
        
        guard let message = dictionary["message"] as? JSONDictionary else {return nil }
        guard let room = message["room"] as? String else {return nil}
        guard let sSl = message["sSlot"] as? Int else {return nil}
        guard let id = message["studentNumber"] as? Int else {return nil}
        guard let response = message["response"] as? String else {return nil}
        
        self.response = response
        self.message = ""
        self.success = success
        self.student = Student(studentNumber: id)
        self.room = room
        self.sSlot = sSl
    }
    
    init?(dic:JSONDictionary){
        
        guard let message = dic["message"] as? String else {return nil }
        guard let room = dic["room"] as? String else {return nil}
        guard let sSl = dic["sSlot"] as? Int else {print("sL failed");return nil}
        guard let id = dic["studentNumber"] as? Int else {print("id failed");return nil}
        guard let response = dic["response"] as? String else {print("id failed");return nil}
        guard let success = dic["success"] as? Bool else {print("id failed");return nil}
        
        self.message = message
        self.room = room
        self.sSlot = sSl
        self.student = Student(studentNumber: id)
        self.response = response
        self.success = success
    }
    
}

extension RoomBookingRecipt{
    var json:JSONDictionary {
        return ["studentNumber": student.studentNumber as AnyObject,
                "sSlot": sSlot as AnyObject,
                "room": room as AnyObject,
                "success": success as AnyObject,
                "message": message as AnyObject,
                "response": response as AnyObject]
    }
    
    
}

extension RoomBookingRecipt{
    static let successMessage = "The room has just been booked, try another time-slot!"
    static let failureMessage = "An error has occurred. Please see a guru to book a room!"
}

func book(roomRequest:RoomBookingRequest) -> Resource<RoomBookingRecipt> {
    let url = URLS.book
    return Resource<RoomBookingRecipt>(url: url!, method: HttpMethod.post(roomRequest.json as AnyObject), parseJSON: { (json) -> RoomBookingRecipt? in
        return RoomBookingRecipt(dictionary: json as! JSONDictionary)
    })
    
}
/////////////////////////////////////////
