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

type alias Model = { turbans : List Turban, diffTurbans : List Turban, alreadyVoted : String }

init : (Model, Cmd Msg)
init =
  (Model [] [] "", doload())

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

diff : List Turban -> List Turban -> List Turban
diff oldTurbans newTurbans =
  List.map2 (\oldTurban -> \newTurban ->  Turban oldTurban.id (newTurban.count - oldTurban.count) oldTurban.name) oldTurbans newTurbans


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
      ({model | turbans = decodeTurbans str, diffTurbans = (diff model.turbans (decodeTurbans str)) }, Cmd.none)
    Doload ->
      ( model, doload() )
    Load value ->
      case value of
        Just xs -> ({model | alreadyVoted = xs}, Cmd.none )
        Nothing -> ({model | alreadyVoted = ""}, Cmd.none )
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
              ({ model | turbans = List.map updateVote model.turbans, alreadyVoted = id },
              Cmd.batch [save id, postVote id])

-- VIEW
alreadyVotedText : String -> String
alreadyVotedText alreadyVoted =
  if not (String.isEmpty alreadyVoted) then
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
  if model.alreadyVoted == turbanid then
    "TAKK 😘"
  else
    "STEM"

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
      , button [onClick (Vote turban.id), class (buttonClass model turban.id)] [text (buttonText model turban.id)]
      --, div [myStyle (percentageOfVotes turban.count model)] [ text (((toString (percentageOfVotes turban.count model))) ++ "%") ]
      ])  model.turbans)
    --, footer [] [text (toString model.diffTurbans) ]
    , footer [] [text (alreadyVotedText model.alreadyVoted)]]
    --, div [] [button [class "inactive"] [text "STEM"]]]
