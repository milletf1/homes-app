module Util.KeyboardEvents exposing (onEnter)

import Html exposing (Attribute)
import Html.Events exposing (keyCode, on)
import Json.Decode exposing (andThen, fail, succeed)


onEnter : msg -> Attribute msg
onEnter msg =
    let
        isEnter code =
            if code == 13 then
                succeed msg
            else
                fail "not ENTER"
    in
        on "keydown" (andThen isEnter keyCode)