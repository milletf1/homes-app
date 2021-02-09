module Route exposing (Route(..), parseUrl)

import Url exposing (Url)
import Url.Parser exposing (..)
import Html exposing (a)

type Route
    = NotFound
    | Search
    | Data

parseUrl : Url -> Route
parseUrl url =
    case parse matchRoute url of
        Just route ->
            route

        Nothing ->
            NotFound

matchRoute : Parser (Route -> a) a
matchRoute =
    oneOf
        [ map Search top
        , map Search (s "manage")
        , map Data (s "data")
        ]