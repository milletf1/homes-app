module Util.DateFormat exposing (dateString)

import Time exposing (Month(..), Posix, Zone, millisToPosix, toDay, toMonth, toYear)
import TimeZone exposing (pacific__auckland)


dateString : Int -> String
dateString milliseconds =
    let
        zone : Zone
        zone =
            lazyZone

        posix : Posix
        posix =
            millisToPosix milliseconds

        year : String
        year =
            String.fromInt ( toYear zone posix )

        day : String
        day =
            String.fromInt ( toDay zone posix )

        month : String
        month =
            let
                m : Month
                m =
                    toMonth zone posix
            in
            case m of
                Jan ->
                    "Jan"
                Feb ->
                    "Feb"
                Mar ->
                    "Mar"
                Apr ->
                    "Apr"
                May ->
                    "May"
                Jun ->
                    "Jun"
                Jul ->
                    "Jul"
                Aug ->
                    "Aug"
                Sep ->
                    "Sep"
                Oct ->
                    "Oct"
                Nov ->
                    "Nov"
                Dec ->
                    "Dec"
    in
    month ++ " " ++ day ++ ", " ++ year

lazyZone : Zone
lazyZone =
    pacific__auckland ()