port module Main exposing (..)

import Dto.Dto exposing (AddressId)
import Browser
import Browser.Navigation as Nav
import Component.NotFound exposing (notFound)
import Html exposing (Html)
import Page.Search as Search
import Page.Data as Data
import Route exposing (..)
import Url exposing (Url)


-- MAIN


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = UrlRequested
        }


-- MODEL


type alias Model =
    { route : Route
    , page : Page
    , navKey : Nav.Key
    , watchlist : List AddressId
    , url : String
    }

type Page
    = NotFoundPage
    | SearchPage Search.Model
    | DataPage Data.Model

type alias Flags =
    { watchlist : List AddressId
    , url : String
    }

init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url navKey =
    let
        model =
            { route = Route.parseUrl url
            , page = NotFoundPage
            , navKey = navKey
            , watchlist = flags.watchlist
            , url = flags.url
            }
    in
    initCurrentPage ( model, Cmd.none )


-- PORTS


port updateWatchlist : ( List AddressId -> msg ) -> Sub msg


-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.page of
        DataPage page ->
            Sub.batch
                [ updateWatchlist ReceivedWatchlistUpdate
                , Sub.map DataPageMsg ( Data.subscriptions page )
                ]

        _ ->
            updateWatchlist ReceivedWatchlistUpdate


-- UPDATE


type Msg
  = UrlRequested Browser.UrlRequest
  | UrlChanged Url
  | SearchPageMsg Search.Msg
  | DataPageMsg Data.Msg
  | ReceivedWatchlistUpdate (List AddressId)

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.page ) of
        ( ReceivedWatchlistUpdate updatedAddressIds, _ ) ->
            ( { model | watchlist = updatedAddressIds }
            , Cmd.none
            )
        
        ( UrlRequested urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.navKey ( Url.toString url ) )

                Browser.External url ->
                    ( model, Nav.load url )
        
        ( UrlChanged url, _ ) ->
            let
                newRoute =
                    Route.parseUrl url
            in
            ( { model | route = newRoute }, Cmd.none )
                |> initCurrentPage

        ( SearchPageMsg subMsg, SearchPage pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    Search.update subMsg pageModel
            in
            ( { model | page = SearchPage updatedPageModel }
            , Cmd.map SearchPageMsg updatedCmd
            )

        ( DataPageMsg subMsg, DataPage pageModel ) ->
            let
                (updatedPageModel, updatedCmd ) =
                    Data.update subMsg pageModel
            in
            ( { model | page = DataPage updatedPageModel }
            , Cmd.map DataPageMsg updatedCmd
            )

        (_, _ ) ->
            ( model, Cmd.none )

initCurrentPage : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
initCurrentPage ( model, existingCmds ) =
    let
        ( currentPage, mappedPageCmds ) =
            case model.route of
                Route.NotFound ->
                    ( NotFoundPage, Cmd.none )

                Route.Search ->
                    let
                        searchPageFlags : Search.Flags
                        searchPageFlags =
                            { watchlist = model.watchlist
                            , url = model.url
                            }

                        ( pageModel, pageCmds ) =
                            Search.init searchPageFlags
                    in
                    ( SearchPage pageModel, Cmd.map SearchPageMsg pageCmds)

                Route.Data ->
                    let
                        dataPageFlags: Data.Flags
                        dataPageFlags =
                            { watchlist = model.watchlist }

                        ( pageModel, pageCmds ) =
                            Data.init dataPageFlags
                    in
                    ( DataPage pageModel, Cmd.map DataPageMsg pageCmds)
    in
    ( { model | page = currentPage }
    , Cmd.batch [ existingCmds, mappedPageCmds ]
    )


-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = selectTitle model
    , body = [ selectView model ]
    }

selectTitle : Model -> String
selectTitle model =
    case model.page of
        NotFoundPage ->
            "404 Not Found"

        SearchPage _ ->
            Search.title

        DataPage _ ->
            Data.title

selectView : Model -> Html Msg
selectView model =
    case model.page of
        NotFoundPage ->
            notFound

        SearchPage pageModel ->
            Search.view pageModel
                |> Html.map SearchPageMsg

        DataPage pageModel ->
            Data.view pageModel
                |> Html.map DataPageMsg