import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import WebSocket
import Http
import Json.Decode exposing (Decoder, int, string, map2, field, decodeString)


main =
  Html.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }


type alias Turban =
    { id : String
    , votes : Int
    }


server : String
server =
  "wss://localhost:3000"

voteEndpoint : String
voteEndpoint =
  server ++ "/vote"

counterEndpoint : String
counterEndpoint =
  server ++ "/counter"

turbanDecoder : Decoder Turban
turbanDecoder =
    map2 Turban
      (field "id" string)
      (field "counter" int)


-- MODEL

type alias Model =
  { input : String
  , messages : List String
  }


init : (Model, Cmd Msg)
init =
  (Model "" [], Cmd.none)



-- UPDATE

type Msg
  = Input String
  | Send
  | NewMessage String
  | Turbans String

update : Msg -> Model -> (Model, Cmd Msg)
update msg {input, messages} =
  case msg of
    Input newInput ->
      (Model newInput messages, Cmd.none)

    Send ->
      (Model "" messages, WebSocket.send voteEndpoint input)

    NewMessage str ->
      Debug.log(str)
      (Model input (str :: messages), Cmd.none)

    Turbans str ->
      yo= decodeString turbanDecoder str
      (Model input (str :: messages), Cmd.none)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  WebSocket.listen counterEndpoint Turbans



-- VIEW


view : Model -> Html Msg
view model =
  div []
    [ input [onInput Input] []
    , button [onClick Send] [text "Send"]
    , div [] (List.map viewMessage (List.reverse model.messages))
    ]


viewMessage : String -> Html msg
viewMessage msg =
  div [] [ text msg ]
