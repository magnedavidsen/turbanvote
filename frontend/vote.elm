port module Main exposing (..)

import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import WebSocket

import Http
import Json.Decode exposing (Decoder, int, string, map3 , field, decodeString, list, decodeValue)

counterEndpoint : String
counterEndpoint =
  "wss://turbanvote.herokuapp.com/counter"

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
    }

type alias Model = { turbans : List Turban, alreadyVoted : Bool }

init : (Model, Cmd Msg)
init =
  (Model [] False, doload())

turbanDecoder : Decoder Turban
turbanDecoder =
    map3 Turban
      (field "id" string)
      (field "count" int)
      (field "name" string)

decodeTurbans : String -> List Turban
decodeTurbans payload =
  case decodeString (Json.Decode.list turbanDecoder) payload of
    Ok val -> val
    Err message -> []


-- UPDATE

port save : String -> Cmd msg
port load : (Maybe String -> msg) -> Sub msg
port doload : () -> Cmd msg

postVote : String -> Cmd Msg
postVote id =
  WebSocket.send counterEndpoint id

type Msg = Vote String | ReceiveTurbans String | Doload | Load (Maybe String)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    ReceiveTurbans str ->
      ({model | turbans = decodeTurbans str}, Cmd.none)
    Doload ->
      ( model, doload() )
    Load value ->
      case value of
        Just xs -> ({model | alreadyVoted = not (String.isEmpty xs)}, Cmd.none )
        Nothing -> ({model | alreadyVoted = False}, Cmd.none )
    Vote id ->
      let
        updateVote t =
          if t.id == id then
            { t | count = t.count + 1 }
          else
            t
          in
            ({ model | turbans = List.map updateVote model.turbans, alreadyVoted = True },
            Cmd.batch [save "True", postVote id])

-- VIEW
alreadyVotedText : Bool -> String
alreadyVotedText alreadyVoted =
  if alreadyVoted then
    "Takk for stemmen!"
  else
    "Stem da mann/kvinne!"

sumOfVotes : List Turban -> Int
sumOfVotes turbanlist =
  let
    getCount turban =
      turban.count
  in
    List.sum (List.map getCount turbanlist)

percentageOfVotes : Int -> Model -> Int
percentageOfVotes votes model =
  round ((toFloat votes / toFloat (sumOfVotes model.turbans)) * 100)

myStyle : Int -> Attribute msg
myStyle width =
  style
    [ ("backgroundColor", "blue")
    , ("color", "white")
    , ("height", "1.5em")
    , ("margin", "0.5em 0")
    , ("width", (toString width) ++ "%")
    ]

view : Model -> Html Msg
view model =
  div [class "container"]
    [ section []
      (List.map (\turban -> article []
      [ img [src "https://scontent-arn2-1.xx.fbcdn.net/v/t1.0-9/17457714_10154631752074514_1853965134717809529_n.jpg?oh=d8229e93432033b6b90f4a25f13b5d72&oe=594FCF0F"] []
      , div [class "name"] [ text turban.name ]
      , div [class "description"] [ text "Litt  tekst om den fine turbanen, og tankene bak. Osv. Sånne ting. Hvorfor den er blå og gul og sånn. Yassss." ]
      , button [onClick (Vote turban.id)] [text "STEM"]
      , div [myStyle (percentageOfVotes turban.count model)] [ text (((toString (percentageOfVotes turban.count model))) ++ "%") ]
      ])  model.turbans)
    , footer [] [text (alreadyVotedText model.alreadyVoted)]]
    --, div [] [button [class "inactive"] [text "STEM"]]]
