module Component.NotFound exposing (notFound)

import Html exposing (Html, div, h3, text)
notFound : Html msg
notFound =
    div [] [ h3 [] [ text "Oops! The page you requested was not found!" ] ]