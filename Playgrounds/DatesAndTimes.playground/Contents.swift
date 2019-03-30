import Foundation
import PostgresClientKit

//
// TIMESTAMP WITH TIME ZONE
//

let tstz = Date().postgresTimestampWithTimeZone
tstz.date
tstz.dateComponents
tstz.postgresValue
tstz.description

let tstz2 = PostgresTimestampWithTimeZone(
    year: 1969,
    month: 03,
    day: 14,
    hour: 13,
    minute: 14,
    second: 15,
    nanosecond: 987654321,
    timeZone: TimeZone.current)
tstz2!.date
tstz2!.dateComponents
tstz2!.postgresValue
tstz2!.description

let tstz3 = PostgresTimestampWithTimeZone("2000-01-02 12:34:56.988+01")
tstz3!.date
tstz3!.dateComponents
tstz3!.postgresValue
tstz3!.description


//
// TIMESTAMP
//

let ts = Date().postgresTimestamp(in: TimeZone.current)
ts.date(in: TimeZone.current)
ts.date(in: TimeZone(secondsFromGMT: 0)!)
ts.dateComponents
ts.postgresValue
ts.description

let ts2 = PostgresTimestamp(
    year: 1969,
    month: 03,
    day: 14,
    hour: 13,
    minute: 14,
    second: 15,
    nanosecond: 987654321)
ts2!.date(in: TimeZone.current)
ts2!.date(in: TimeZone(secondsFromGMT: 0)!)
ts2!.dateComponents
ts2!.postgresValue
ts2!.description

let ts3 = PostgresTimestamp("2000-01-02 12:34:56.988")
ts3!.date(in: TimeZone.current)
ts3!.date(in: TimeZone(secondsFromGMT: 0)!)
ts3!.dateComponents
ts3!.postgresValue
ts3!.description


//
// DATE
//

let d = Date().postgresDate(in: TimeZone.current)
d.date(in: TimeZone.current)
d.date(in: TimeZone(secondsFromGMT: 0)!)
d.dateComponents
d.postgresValue
d.description

let d2 = PostgresDate(
    year: 1969,
    month: 03,
    day: 14)
d2!.date(in: TimeZone.current)
d2!.date(in: TimeZone(secondsFromGMT: 0)!)
d2!.dateComponents
d2!.postgresValue
d2!.description

let d3 = PostgresDate("2000-01-02")
d3!.date(in: TimeZone.current)
d3!.date(in: TimeZone(secondsFromGMT: 0)!)
d3!.dateComponents
d3!.postgresValue
d3!.description


//
// TIME
//

let t = Date().postgresTime(in: TimeZone.current)
t.date(in: TimeZone.current)
t.date(in: TimeZone(secondsFromGMT: 0)!)
t.dateComponents
t.postgresValue
t.description

let t2 = PostgresTime(
    hour: 13,
    minute: 14,
    second: 15,
    nanosecond: 987654321)
t2!.date(in: TimeZone.current)
t2!.date(in: TimeZone(secondsFromGMT: 0)!)
t2!.dateComponents
t2!.postgresValue
t2!.description

let t3 = PostgresTime("12:34:56.988")
t3!.date(in: TimeZone.current)
t3!.date(in: TimeZone(secondsFromGMT: 0)!)
t3!.dateComponents
t3!.postgresValue
t3!.description


//
// TIME WITH TIME ZONE
//

let tz = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())!
let ttz = Date().postgresTimeWithTimeZone(in: tz)
ttz!.date
ttz!.timeZone
ttz!.dateComponents
ttz!.postgresValue
ttz!.description

let ttz2 = PostgresTimeWithTimeZone(
    hour: 13,
    minute: 14,
    second: 15,
    nanosecond: 987654321,
    timeZone: tz)
ttz2!.date
ttz2!.timeZone
ttz2!.dateComponents
ttz2!.postgresValue
ttz2!.description

let ttz3 = PostgresTimeWithTimeZone("12:34:56.988-07")
ttz3!.date
ttz3!.timeZone
ttz3!.dateComponents
ttz3!.postgresValue
ttz3!.description

// EOF
