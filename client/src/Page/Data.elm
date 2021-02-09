port module Page.Data exposing (Flags, Model, init, Msg, subscriptions, update, title, view)

import Dto.Dto exposing (AddressId, PropertyData)
import Page.Search exposing (Msg)
import Util.DateFormat exposing (dateString)
import Html exposing (Html, a, div, h1, img, input, strong, table, td, th, tr, tbody, thead, text, nav, ul, li)
import Html.Attributes as Attrs exposing (attribute, class, height, href, placeholder, src, style, width, value)
import Html.Events exposing (onInput)
import Round
import String

-- MODEL


type alias Model =
    { data: List PropertyData
    , search: String
    , searchData: List PropertyData
    }

type alias Flags =
    { watchlist : List AddressId
    }

init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        model : Model
        model =
            { data = []
            , search = ""
            , searchData = []
            }
    in
    ( model, getPropertyData flags.watchlist )


-- PORTS


port getPropertyData : List AddressId -> Cmd msg
port updatePropertyData : ( List PropertyData -> msg ) -> Sub msg


-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    updatePropertyData ReceivedPropertyData


-- UPDATE

type Msg
    = ReceivedPropertyData (List PropertyData)
    | UpdateSearch String

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReceivedPropertyData data ->
            ( { model | data = data, searchData = searchResults data model.search }, Cmd.none )
        UpdateSearch search ->
            ( { model | search = search, searchData = searchResults model.data search }, Cmd.none )

searchResults : List PropertyData -> String -> List PropertyData
searchResults rawData search =
    let
        trimmed : String
        trimmed =
            String.trim search
    in
    if String.isEmpty trimmed then rawData
    else List.filter (\pd -> String.contains (String.toLower trimmed) (String.toLower pd.address)) rawData


-- VIEW


title : String
title =
    "Property Data"

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
            [ li [ class "nav-item" ]
                [ a
                    [ class "nav-link"
                    , href "/manage"
                    ]
                    [ text "Manage" ]
                ]
            , li 
                [ class "nav-item active"
                , style "cursor" "pointer"
                , style "user-select" "none"
                ]
                [ div [ class "nav-link" ] [ text "Data" ] ]
            ]
        ]
    , div [ class "container-fluid mt-4" ]
      [ div [ class "row" ]
        [ div
          [ class "offset-9 col-3"
          , style "margin-bottom" "0.5em"
          ]
          [ input
            [ value model.search
            , attribute "type" "text"
            , class "form-control"
            , onInput UpdateSearch
            , placeholder "Search..."
            ]
          []
          ]
        ]
      , div [ class "row" ] [ tableView model ]
      ]
    ]

tableView : Model -> Html Msg
tableView model =
    table [ class "table table-striped" ]
        [ tableHeaderView
        , tableDataView model.searchData
        ]

tableHeaderView : Html Msg
tableHeaderView =
    thead []
    [ tr []
        [ th [ class "sticky-top bg-white" ] [ text "Address" ]
        , th [ class "sticky-top bg-white" ] [ text "Estimate" ]
        , th [ class "sticky-top bg-white" ] [ text "Rateable Value" ]
        , th [ class "sticky-top bg-white" ] [ text "Sale Price" ]
        , th [ class "sticky-top bg-white" ]
            [ text "RV - Sale "
            , img
                [ src "assets/images/question-circle.svg"
                , width 16
                , height 16
                , style "margin-bottom" "5px"
                , style "cursor" "pointer"
                , Attrs.title "Calculated using the rateable value closest to when the property was sold"
                ]
                []
            ]
        , th [ class "sticky-top bg-white" ] [ text "Estimate - RV" ]
        , th [ class "sticky-top bg-white" ]
            [ text "Estimate - Sale "
            , img
                [ src "assets/images/question-circle.svg"
                , width 16
                , height 16
                , style "margin-bottom" "5px"
                , style "cursor" "pointer"
                , Attrs.title "Calculated using the estimate closest to when the property was sold"
                ]
                []
            ]
        , th [ class "sticky-top bg-white" ] [ text "Details" ]
        ]
    ]

tableDataView : List PropertyData -> Html Msg
tableDataView dataList =
    tbody [] ( List.map (\data -> tableRowView data) dataList)

tableRowView : PropertyData -> Html Msg
tableRowView data =
    let
        estimate : String
        estimate =
            case data.estimate of
                Just e ->
                    String.fromInt e
                Nothing ->
                    "-"

        estimateDate : String
        estimateDate =
            case data.estimateDate of
                Just ed ->
                    dateString ed
                Nothing ->
                    "-"
            
        rv : String
        rv =
            case data.rateableValue of
                Just r ->
                    String.fromInt r
                Nothing ->
                    "-"

        rvDate : String
        rvDate =
            case data.rateableValueDate of
                Just rvd ->
                    dateString rvd
                Nothing ->
                    "-"

        sale : String
        sale =
            case data.salePrice of
                Just sp ->
                    String.fromInt sp
                Nothing ->
                    "-"

        saleDate : String
        saleDate =
            case data.saleDate of
                Just sd ->
                    dateString sd
                Nothing ->
                    "-"

        rvSaleDiff : String
        rvSaleDiff = 
            case data.rvSaleDiff of
                Just rvsd ->
                    let
                        val : String
                        val =
                            Round.round 1 (rvsd * 100)
                    in
                        if val == "-100.0" then
                            "-"
                    else
                        val ++ "%"
                Nothing ->
                    "-"

        estimateRvDiff : String
        estimateRvDiff =
            case data.estimateRvDiff of
                Just rved ->
                    Round.round 1 (rved * 100) ++ "%"
                Nothing ->
                    "-"

        estimateSaleDiff : String
        estimateSaleDiff =
            case data.estimateSaleDiff of
                Just esd ->
                    Round.round 1 (esd * 100) ++ "%"
                Nothing ->
                    "-"

    in
    tr []
        [ td [] [ text data.address ]
        , td [] [ text (estimate ++ " (" ++ estimateDate ++ ")") ]
        , td [] [ text (rv ++ " (" ++ rvDate ++ ")") ]
        , td [] [ text (sale ++ " (" ++ saleDate ++ ")") ]
        , td [] [ text rvSaleDiff ]
        , td [] [ text estimateRvDiff ]
        , td [] [ text estimateSaleDiff ]
        , propertyDetails data
        ]

propertyDetails : PropertyData -> Html Msg
propertyDetails data =
    let
        bedrooms : String
        bedrooms =
            case data.bedrooms of
                Just brs ->
                    String.fromInt brs
                Nothing ->
                    "-"

        bathrooms : String
        bathrooms =
            case data.baths of
                Just brs ->
                    String.fromInt brs
                Nothing ->
                    "-"

        carParks : String
        carParks = 
            case data.carParks of
                Just cps ->
                    String.fromInt cps
                Nothing ->
                    "-"

        floor : String
        floor =
            case data.floorArea of
                Just flr ->
                    String.fromInt flr ++ "m2"
                Nothing ->
                    "-"

        land : String
        land =
            case data.landArea of
                Just lnd ->
                    String.fromInt lnd ++ "m2"
                Nothing ->
                    "-"
    in
    td []
        [ div []
            [ strong [] [ text "beds: " ]
            , text bedrooms
            , strong [] [ text " baths: " ]
            , text bathrooms
            , strong [] [ text " parks: " ]
            , text carParks
            , strong [] [ text " floor: " ]
            , text floor
            , strong [] [ text " land: " ]
            , text land
            ]
        ]
