import Html exposing (..)
import Html.Events exposing (..)
import WebSocket

import Http
import Json.Decode exposing (Decoder, int, string, map3 , field, decodeString, list, decodeValue)

server : String
server =
  "ws://localhost:3000"

counterEndpoint : String
counterEndpoint =
  server ++ "/counter"

postBooks : Http.Request (List String)
postBooks =
  Http.post "http://localhost:3000/vote" Http.emptyBody (list string)


main =
  Html.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }


subscriptions : Model -> Sub Msg
subscriptions model =
  WebSocket.listen counterEndpoint Turbans

-- MODEL

type alias Turban =
    { id : String
    , votes : Int
    , name : String
    }

type alias Model = { turbans : List Turban }


init : (Model, Cmd Msg)
init =
  (Model [{id = "1", votes = 0, name = "yeah1"}, {id = "2", votes = 0, name = "yeah2"}, {id = "3", votes = 0, name = "yeah3"}], Cmd.none)

turbanDecoder : Decoder Turban
turbanDecoder =
    map3 Turban
      (field "id" string)
      (field "votes" int)
      (field "name" string)

decodeTurbans : String -> List Turban
decodeTurbans payload =
  case decodeString (list turbanDecoder) payload of
    Ok val -> val
    Err message -> []


-- UPDATE

postVote : String -> Cmd Msg
postVote id =
  let
    url =
      "http://localhost:3000/vote/" ++ id
  in
    Http.send PostVote (Http.post url Http.emptyBody string)

type Msg = Vote String | Dummy String | PostVote (Result Http.Error String) | Turbans String

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Turbans str ->
      ({model | turbans = decodeTurbans str}, Cmd.none)
    PostVote _ ->
      (model, Cmd.none)
    Dummy id ->
      (model, postVote id)
    Vote id ->
      let
        updateVote t =
          if t.id == id then
            { t | votes = t.votes + 1 }
          else
            t
          in
            ({ model | turbans = List.map updateVote model.turbans }, Cmd.none)

-- VIEW

view : Model -> Html Msg
view model =
    div [] (List.map viewTurban model.turbans)

viewTurban : Turban -> Html Msg
viewTurban turban =
  div []
    [ span [] [ text turban.name ]
    , span [] [ text " - "]
    , span [] [ text (toString turban.votes) ]
    , span [] [ text " - "]
    , button [onClick (Dummy turban.id)] [text turban.name]
    ]
