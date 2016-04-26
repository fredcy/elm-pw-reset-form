module PasswordField exposing (Model, Action, init, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

type alias Model =
  { password : String
  , showclear : Bool
  }

init : Model
init = Model "" False


type Action = NoOp
            | SetPassword String
            | SetShowclear Bool


-- The update function receives `focusEffect`, a function that creates an Effect
-- for focusing on this particular form element.
update : Cmd Action -> Action -> Model -> (Model, Cmd Action)
update focusEffect action model =
  case action of
    NoOp -> (model, Cmd.none)
    SetPassword pw -> ( { model | password = pw }, Cmd.none)
    SetShowclear b -> ( { model | showclear = b }, focusEffect)
                      

-- We separate the static properties from those in the model.                      
type alias Props =
  { name : String
  , label : String
  }

view : Props -> Model -> Html Action
view props model =
  let
    showId = props.name ++ "-show"
  in
    div []
          [ label [ for props.name ] [ text props.label ]
          , input [ type' (if model.showclear then "text" else "password")
                  , value model.password
                  , name props.name
                  , onInput SetPassword
             ]
            []
          , label [ class "show", for showId ] [ text "show" ]
          , input [ type' "checkbox"
                  , id showId
                  , checked model.showclear
                  , onCheck SetShowclear
                  , tabindex -1   -- not reached via Tab key
                  ]
          []
        ]  
