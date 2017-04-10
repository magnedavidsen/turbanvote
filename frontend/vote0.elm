import Html exposing (..)
import Html.Events exposing (..)

import Http
import Json.Decode exposing (list, string)

postBooks : Http.Request (List String)
postBooks =
  Http.post "http://localhost:3000/vote" Http.emptyBody (list string)


main =
  Html.beginnerProgram
    { model = model
    , view = view
    , update = update
    }


-- MODEL

type alias Turban =
    { id : String
    , votes : Int
    , name : String
    }

type alias Model = { turbans : List Turban }
model : Model
model =
  {turbans = [{id = "1", votes = 0, name = "yeah1"}, {id = "2", votes = 0, name = "yeah2"}, {id = "3", votes = 0, name = "yeah3"}]}


-- UPDATE

postVote : String -> Cmd Msg
postVote topic =
  let
    url =
      "http://localhost:3000/vote"
  in
    Http.post url Http.emptyBody (list string)

type Msg = Vote String | Dummy

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Dummy ->
      (model, postVote)
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
    , button [onClick (Vote turban.id)] [text turban.name]
    ]
