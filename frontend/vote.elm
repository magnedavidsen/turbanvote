port module Main exposing (..)

import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import WebSocket

import Http
import Json.Decode exposing (Decoder, int, string, map5, field, decodeString, list, decodeValue)

counterEndpoint : String
counterEndpoint =
  "wss://www.osloturban.no/"

main =
  Html.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ WebSocket.listen counterEndpoint ReceiveTurbans
        , load Load ]

-- MODEL

type alias Turban =
    { id : String
    , count : Int
    , name : String
    , title : String
    , desc : String
    }

type alias Model = { turbans : List Turban, diffTurbans : List Turban, alreadyVoted : String, mouseOver : String }

init : (Model, Cmd Msg)
init =
  (Model [] [] "" "", doload())

turbanDecoder : Decoder Turban
turbanDecoder =
    map5 Turban
      (field "id" string)
      (field "count" int)
      (field "name" string)
      (field "title" string)
      (field "desc" string)

decodeTurbans : String -> List Turban
decodeTurbans payload =
  case decodeString (Json.Decode.list turbanDecoder) payload of
    Ok val -> val
    Err message -> []

diff : List Turban -> List Turban -> List Turban
diff oldTurbans newTurbans =
  List.map2 (\oldTurban -> \newTurban ->  Turban oldTurban.id (newTurban.count - oldTurban.count) oldTurban.name oldTurban.title oldTurban.desc) oldTurbans newTurbans


-- UPDATE

port save : String -> Cmd msg
port load : (Maybe String -> msg) -> Sub msg
port doload : () -> Cmd msg

postVote : String -> Cmd Msg
postVote id =
  WebSocket.send counterEndpoint id

type Msg = Vote String | ReceiveTurbans String | Doload | Load (Maybe String) | MouseOverImage String

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    ReceiveTurbans str ->
      ({model | turbans = decodeTurbans str, diffTurbans = (diff model.turbans (decodeTurbans str)) }, Cmd.none)
    Doload ->
      ( model, doload() )
    Load value ->
      case value of
        Just xs -> ({model | alreadyVoted = xs}, Cmd.none )
        Nothing -> ({model | alreadyVoted = ""}, Cmd.none )
    MouseOverImage turbanid ->
      ({model | mouseOver = turbanid}, Cmd.none)
    Vote id ->
      if not (String.isEmpty model.alreadyVoted) then
        (model, Cmd.none)
      else
        let
          updateVote t =
            if t.id == id then
              { t | count = t.count + 1 }
            else
              t
            in
              ({ model | alreadyVoted = id },
              Cmd.batch [save id, postVote id])

-- VIEW
alreadyVotedText : String -> String
alreadyVotedText alreadyVoted =
  if not (String.isEmpty alreadyVoted) then
    "Takk for stemmen!"
  else
    "Stem da, mann/kvinne!"

buttonClass : Model ->  String -> String
buttonClass model turbanid =
  if not (String.isEmpty model.alreadyVoted) && model.alreadyVoted == turbanid then
    "inactive voted"
  else if not (String.isEmpty model.alreadyVoted) then
    "inactive"
  else
    ""

buttonText : Model -> String -> String
buttonText model turbanid =
  if String.isEmpty model.alreadyVoted then
    "Stem"
  else if model.alreadyVoted == turbanid then
    "Takk 😘"
  else
    "Du har stemt 😏"

votesSinceLastUpdate : Model -> String -> Int
votesSinceLastUpdate model turbanid =
  List.sum (List.map (\turban -> turban.count)
  (List.filter (\turbanDiff -> turbanDiff.id == turbanid) model.diffTurbans))


imageSource : String -> Bool -> String
imageSource turbanid mouseover =
  if mouseover then
    "turban_" ++ turbanid ++ "_back.jpg"
  else
    "turban_" ++ turbanid ++ "_front.jpg"

view : Model -> Html Msg
view model =
  div [class "container"]
    [ section []
      (List.map (\turban ->
        let mouseover = False in
          article []
            [ div [class "images"]
                [img [class "bottom", src ("turban_" ++ turban.id ++ "_bottom.jpg") ] []
                , img [class "top",src ("turban_" ++ turban.id ++ "_top.jpg") ] []]
            , div [class "title"] [ text turban.title ]
            , div [class "name"] [ text turban.name ]
            , button [onClick (Vote turban.id), class (buttonClass model turban.id)] [text (buttonText model turban.id)]
            -- , div [class (if (votesSinceLastUpdate model turban.id) > 0 then "likes" else "no-likes")] [text (String.repeat (votesSinceLastUpdate model turban.id) "❤️")]
            , if (votesSinceLastUpdate model turban.id) > 0 then div [class "likes"] [text "❤️"] else span [class "no-likes"] [text ""]
            -- , div [class "likes"] [text "❤️"]
            , div [class "description"] [ text turban.desc]
            ])  model.turbans)
    , footer [] [text (alreadyVotedText model.alreadyVoted)]]
