port module Main exposing (Category, Item, Model, Msg(..), Portfolio, categoryDecoder, getPortfolioFromChannel, getSelectedCategoryId, getSelectedItem, init, initialModel, itemDecoder, main, portfolioDecoder, subscriptions, update, view, viewCategoryButton, viewCategoryNavbar, viewError, viewItem, viewItems, viewSelectedItem)

import Browser
import Html exposing (..)
import Html.Attributes exposing (attribute, class, classList, href, src, target, type_, width, style)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Decode.Pipeline as Pipeline exposing (optional, required)
import Json.Encode as Encode
import Set

{--Model
The `initialModel` function initializes our `Model`. This function is called in `init` and outputs a `Model`
--}


initialModel : String -> Model
initialModel url =
    { errorMessage = ""
    , portfolio =
        { categories = []
        , items = []
        }
    , selectedCategoryId = Nothing
    , selectedItemId = Nothing
    , likedItems = []
    }


type alias Model =
    { errorMessage : String
    , portfolio : Portfolio
    , selectedCategoryId : Maybe Int
    , selectedItemId : Maybe Int
    , likedItems : List (Int, Int)
    }


type alias Portfolio =
    { categories : List Category
    , items : List Item
    }


type alias Category =
    { id : Int, label : String }


type alias Item =
    { id : Int
    , title : String
    , categoryId : Int
    , imageUrl : String
    , linkUrl : String
    , description : String
    , overlayColor : String
    , likes : Int
    }


type alias ChannelRequest =
    { event : String, payload : Encode.Value }


type alias ChannelResponse =
    { code : Int, response : Portfolio }



{--View
The function `view` renders an Html element using our application model.
Note that the type signature is Model -> Html Msg. This means that this function transforms an argument
of `Model` into an `Html` element that, in turn produces messages tagged with `Msg`.

We will see this when we introduce some interaction.
--}


view : Model -> Html Msg
view model =
    let
        portfolio =
            model.portfolio

        selectedCategoryId =
            getSelectedCategoryId model

        selectedItem =
            getSelectedItem model selectedCategoryId
    in
    div [ class "container" ]
        [ div [ class "row" ]
            [ div
                [ class "col"
                ]
                [ br [] [] ]
            ]
        , div [ class "row" ]
            [ div
                [ class "col"
                ]
                [ h1 [] [ text "Elmfolio" ] ]
            ]
        , viewCategoryNavbar portfolio selectedCategoryId
        , viewSelectedItem selectedItem
        , viewItems model selectedCategoryId selectedItem
        ]


viewCategoryNavbar : Portfolio -> Int -> Html Msg
viewCategoryNavbar { categories } selectedCategoryId =
    div [ class "row" ]
        [ div
            [ class "col" ]
            [ div [ class "nav-category" ]
                (List.map (viewCategoryButton selectedCategoryId) categories)
            ]
        ]


viewCategoryButton : Int -> Category -> Html Msg
viewCategoryButton selectedCategoryId category =
    let
        categorySelected =
            selectedCategoryId == category.id

        buttonsBaseAttrs =
            [ type_ "button", classes ]

        buttonOnClick =
            if categorySelected then
                []
            else
                [ onClick (CategoryClicked category.id) ]

        buttonAttrs =
            buttonsBaseAttrs ++ buttonOnClick

        classes =
            classList
                [ ( "btn btn-category", True )
                , ( "btn-primary", categorySelected )
                , ( "btn-secondary", not categorySelected )
                ]
    in
    button buttonAttrs [ text category.label ]


viewItems : Model -> Int -> Maybe Item -> Html Msg
viewItems { portfolio, errorMessage, likedItems } selectedCategoryId selectedItemId =
    let
        filteredItems =
            portfolio.items |> List.filter (\i -> i.categoryId == selectedCategoryId) |> List.map (viewItem likedItems)

        contents =
            if String.isEmpty errorMessage then
                div [ class "row items-container" ]
                    filteredItems
            else
                viewError errorMessage
    in
    contents


viewItem : List (Int, Int) -> Item -> Html Msg
viewItem likedItems item =
    let
        iconset =
            if List.member (item.categoryId, item.id) likedItems then
                "fas"
            else
                "far"
    in
    div
        [ class "col-4 item-panel" ]
        [ span [ style "display" "inline-blockw"] [ 
            img [ src item.imageUrl
            , class "img-fluid"
            , onClick (ItemClicked item.id)
            ] []
            , span [ class "badge badge-info like-box", onClick (ItemLiked item.id)][
                i [ class <| iconset ++ " fa-heart" ] []
                , text <| " " ++ (String.fromInt item.likes)
            ]


        ]
            
        ]



viewSelectedItem : Maybe Item -> Html msg
viewSelectedItem item =
    let
        contents =
            case item of
                Nothing ->
                    []

                Just detail ->
                    [ div [ class "col-6" ]
                        [ img [ src detail.imageUrl, class "img-fluid" ] [] ]
                    , div [ class "col-6" ]
                        [ h3 [] [ text detail.title ]
                        , hr [] []
                        , text detail.description
                        , br [] []
                        , br [] []
                        , a [ href detail.linkUrl, target "_blank" ] [ text detail.linkUrl ]
                        ]
                    ]
    in
    div [ class "row selected-item-container" ]
        contents


viewError : String -> Html Msg
viewError error =
    div [ class "alert alert-danger", attribute "role" "alert" ]
        [ strong []
            [ text error ]
        ]



{--Update--
The `update` function will be called by `Browser.element` each time a message (`Msg`) is received.
This update function responds to messages (`Msg`), updating the model and returning commands as needed.
--}


type Msg
    = HandleChannelResponse ChannelResponse
    | CategoryClicked Int
    | ItemClicked Int
    | ItemLiked Int
    | None


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        HandleChannelResponse channelResponse ->
            let
                { code, response } =
                    channelResponse

                updatedModel =
                    case (code, response) of
                        (200, portfolio) ->
                            { model 
                                | portfolio = portfolio
                                , selectedCategoryId = Just <| getSelectedCategoryId model
                            }

                        _ ->
                            model
            in
            ( updatedModel, Cmd.none )

        CategoryClicked categoryId ->
            let
                updatedModel =
                    { model
                        | selectedCategoryId = Just categoryId
                        , selectedItemId = Nothing
                    }
            in
            ( updatedModel, Cmd.none )

        ItemClicked itemId ->
            let
                updatedModel =
                    { model
                        | selectedItemId = Just itemId
                    }
            in
            ( updatedModel, Cmd.none )

        ItemLiked itemId ->
            let
                updatedLikedItems selectedCategoryId =
                    (selectedCategoryId, itemId) :: model.likedItems
                        |> Set.fromList
                        |> Set.toList

                updatedModel =
                    case model.selectedCategoryId of
                        Just selectedCategoryId ->
                            { model | likedItems = updatedLikedItems selectedCategoryId }
                        Nothing ->
                            model
            in
            ( updatedModel, Cmd.none )

        None ->
            ( model, Cmd.none )


getPortfolioFromChannel =
    channelEventRequest { event = "get_items", payload = Encode.null }



-- JSON Decoding


portfolioDecoder : Decoder Portfolio
portfolioDecoder =
    Decode.succeed Portfolio
        |> required "categories" (Decode.list categoryDecoder)
        |> required "items" (Decode.list itemDecoder)


categoryDecoder : Decoder Category
categoryDecoder =
    Decode.succeed Category
        |> required "id" Decode.int
        |> required "label" Decode.string


itemDecoder : Decoder Item
itemDecoder =
    Decode.succeed Item
        |> required "id" Decode.int
        |> required "title" Decode.string
        |> required "categoryId" Decode.int
        |> required "imageUrl" Decode.string
        |> required "linkUrl" Decode.string
        |> required "description" Decode.string
        |> required "overlayColor" Decode.string
        |> required "likes" Decode.int



getSelectedCategoryId : Model -> Int
getSelectedCategoryId model =
    model.selectedCategoryId 
        |> Maybe.withDefault (getFirstCategory model)


getSelectedItem : Model -> Int -> Maybe Item
getSelectedItem { portfolio, selectedItemId } selectedCategoryId =
    case selectedItemId of
        Nothing ->
            Nothing

        Just id ->
            portfolio.items
                |> List.filter (\i -> i.id == id && i.categoryId == selectedCategoryId)
                |> List.head

getFirstCategory { portfolio } =
    portfolio.categories
        |> List.head
        |> Maybe.map .id
        |> Maybe.withDefault 1

apiUrl =
    "https://www.mocky.io/v2/5c77106130000059009d6136"


port channelEventRequest : ChannelRequest -> Cmd msg


port channelEventResponse : (ChannelResponse -> msg) -> Sub msg



{--Subscriptions
In Elm, using subscriptions is how your application can listen for external input. Some examples are:
 - Keyboard events
 - Mouse movements
 - Browser locations changes
 - Websocket events

In this application, we don't have a need for any active subscriptions so we add in Sub.none
--}


subscriptions _ =
    Sub.batch [ channelEventResponse receiveChannelEventReponse ]


receiveChannelEventReponse response =
    HandleChannelResponse response



{--Program setup and initialization--}
{--
The `main` function is the entry point for our app which means it's the first thing that is run
--}


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



{--The `init` function is run by `main` upon application startup and allows us to set
our app's initial state as well as scheduling any commands we'd like to run after the app starts
up. For now, we don't need to run any commands so we'll use Cmd.none here.
--}


init : () -> ( Model, Cmd Msg )
init _ =
    ( initialModel apiUrl
    , getPortfolioFromChannel
    )
