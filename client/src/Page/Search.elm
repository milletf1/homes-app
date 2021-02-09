port module Page.Search exposing (Flags, Model, init, Msg, update, title, view)

import Dto.Dto exposing (AddressId)
import Html exposing (Html, a, button, div, h3, h5, input, nav, text, ul, li)
import Html.Attributes exposing (attribute, class, disabled, href, placeholder, style, value)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as Decode exposing (Decoder)
import Url.Builder as UrlBuilder exposing (crossOrigin)
import Util.KeyboardEvents exposing (onEnter)
import List
import Json.Decode exposing (string)


-- MODEL


type alias Model =
    { search : String
    , results : List String
    , watchlist : List AddressId
    , fetchingId : Bool
    , url : String
    }

type alias Flags =
    { watchlist : List AddressId
    , url : String
    }

init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        model : Model
        model =
            { search = ""
            , results = []
            , watchlist = flags.watchlist
            , fetchingId = False
            , url = flags.url
            }
    in
    ( model, Cmd.none )


-- PORTS


port postWatchlistItems : List AddressId -> Cmd msg
port deleteWatchlistItems : List AddressId -> Cmd msg


-- UPDATE


type Msg
    = UpdateSearch String
    | PerformSearch
    | SearchResolved ( Result Http.Error ( List String ) )
    | FindWatchlistItemId String
    | WatchlistItemResolved ( Result Http.Error AddressId )
    | DeleteWatchlistItem String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateSearch newSearch ->
            ( { model | search = newSearch }, Cmd.none )

        PerformSearch ->
            let
                url : String
                url =
                    crossOrigin
                        model.url
                        [ "search" ]
                        [ UrlBuilder.string "address" model.search ]

                expect: Http.Expect Msg
                expect =
                    Http.expectJson SearchResolved searchResultDecoder
            in
            ( model , Http.get { url = url , expect = expect } )

        SearchResolved result ->
            case result of
                Ok results ->
                    ( { model | results = results }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        FindWatchlistItemId address ->
            let
                url : String
                url =
                    crossOrigin
                        model.url
                        [ "property-id" ]
                        [ UrlBuilder.string "address" address ]

                expect: Http.Expect Msg
                expect =
                    Http.expectJson WatchlistItemResolved addressIdResultDecoder
            in
            ( { model | fetchingId = True }, Http.get { url = url, expect = expect } )

        WatchlistItemResolved result ->
            case result of
                Ok addressId ->
                    let
                        isNewAddress : Bool
                        isNewAddress =
                            List.length (List.filter (\ai -> ai.id == addressId.id) model.watchlist) == 0

                        newWatchlistItemIds : List AddressId
                        newWatchlistItemIds =
                            if isNewAddress then
                                [ addressId ]
                            else
                                []

                        updatedWatchlistItemIds : List AddressId
                        updatedWatchlistItemIds =
                            List.append model.watchlist newWatchlistItemIds
                    in
                    ( { model | watchlist = updatedWatchlistItemIds, fetchingId = False }
                    , postWatchlistItems newWatchlistItemIds
                    )

                Err _ ->
                    ( { model | fetchingId = False }, Cmd.none )

        DeleteWatchlistItem address ->
            let
                deleteWatchlistItemIds : List AddressId
                deleteWatchlistItemIds =
                    model.watchlist
                        |> List.filter (\addressId -> addressId.address == address)

                updateWatchlistItemIds : List AddressId
                updateWatchlistItemIds =
                    model.watchlist
                        |> List.filter (\addressId -> addressId.address /= address)
            in
            ( { model | watchlist = updateWatchlistItemIds }
            , deleteWatchlistItems deleteWatchlistItemIds
            )


searchResultDecoder : Decoder (List String)
searchResultDecoder =
    Decode.list ( Decode.field "Title" Decode.string )
        |> Decode.field "results"

addressIdResultDecoder : Decoder AddressId
addressIdResultDecoder =
    Decode.map2 AddressId
        (Decode.field "address" Decode.string)
        (Decode.field "id" Decode.string)


-- VIEW


title : String
title =
    "Search Properties"

view : Model -> Html Msg
view model =
    div []
        [ nav [ class "navbar navbar-expand-lg navbar-dark bg-dark" ]
            [ a
                [ class "navbar-brand"
                , href "/manage"
                ]
                [ text "Property Watchlist" ]
            , ul [ class "navbar-nav mr-auto" ]
                [ li [ class "nav-item active"
                    , style "cursor" "pointer"
                    , style "user-select" "none"
                    ]
                    [ div [ class "nav-link" ] [ text "Manage" ] ]
                , li [ class "nav-item" ]
                    [ a
                        [ class "nav-link"
                        , href "/data"
                        ]
                        [ text "Data" ] ]
                ]
            ]
        , div [ class "container-fluid mt-4" ]
            [ div [ class "row"]
                [ div [ class "col-sm-11" ]
                    [ input
                      [ value model.search
                      , attribute "type" "text"
                      , class "form-control"
                      , onInput UpdateSearch
                      , placeholder "Search for properties..."
                      , onEnter PerformSearch
                      ]
                      []
                    ]
                , div [ class "col-sm-1" ]
                    [ button
                      [ class "btn btn-primary"
                      , attribute "type" "button"
                      , onClick PerformSearch
                      ]
                      [ text "Search" ]
                    ]
                ]
            , div [ class "row mt-2" ]
                [ div [ class "col-sm-12 col-md-6" ] [ searchResultsView model ]
                , div [ class "col-sm-12 col-md-6" ] [ watchlistView model ] 
                 ]
            ]
        ]

searchResultsView : Model -> Html Msg
searchResultsView model =
    if List.length model.results < 1 then
        h5 [] [ text "No results" ]
    else
        div [] [ resultsView model ]

resultsView : Model -> Html Msg
resultsView model =
    let
        unwatchedList : List String
        unwatchedList =
            List.filter (\a -> notWatched a model.watchlist) model.results

        resultTuple : List (String, Bool)
        resultTuple =
            List.map (\r -> ( r, model.fetchingId )) unwatchedList
    in
    div []
    [ h5 [] [ text "Results" ]
    , div [ class "container-fluid" ] ( List.map resultView resultTuple )
    ]

notWatched : String -> List AddressId -> Bool
notWatched address watchedAddressId =
    let
        watchAddressMatch : List AddressId
        watchAddressMatch =
            List.filter (\ai -> ai.address == address) watchedAddressId
    in
        (List.length watchAddressMatch == 0)

resultView : (String, Bool) -> Html Msg
resultView resultTuple =
    div 
    [ class "row"
    , style "margin-bottom" "0.5em"
    ]
    [ div
      [ class "col-10"
      , style "display" "flex"
      , style "align-items" "center"
      ]
      [ text (Tuple.first resultTuple)
      ]
    , div [ class "col-2" ]
      [ button [ class "btn btn-secondary", onClick (FindWatchlistItemId (Tuple.first resultTuple)), disabled (Tuple.second resultTuple) ] [ text "Watch" ]
      ]
    ]

watchlistView : Model -> Html Msg
watchlistView model =
    if List.length model.watchlist > 0 then
        div []
        [ h5 [] [ text "Watchlist" ]
        , div [ class "container-fluid" ] ( List.map (\ai -> watchlistItemView ai.address ) model.watchlist )
        ]
    else
        div [ class "text-center mt-4" ]
        [ h3 [] [ text "No properties in watchlist" ]
        , h5 [] [ text "Use the search bar to find properties to add to your watchlist" ]
        ]

watchlistItemView : String -> Html Msg
watchlistItemView address =
    div 
    [ class "row"
    , style "margin-bottom" "0.5em"
    ]
    [ div
      [ class "col-10"
      , style "display" "flex"
      , style "align-items" "center"
      ]
      [ text address
      ]
    , div [ class "col-2" ]
      [ button
        [ class "btn btn-danger btn-sm"
        , attribute "type" "button"
        , onClick (DeleteWatchlistItem address)
        ]
        [ text "Remove"
        ]
      ]
    ]
