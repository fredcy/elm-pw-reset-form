module PasswordField where

import Effects exposing (Effects)
import Html exposing (..)
import Html.Attributes exposing (checked, class, for, id, name, style, tabindex, type', value)
import Html.Events exposing (on, targetValue, targetChecked)

type alias Model =
  { password : String
  , showclear : Bool
  }

init : Model
init = Model "" False


type Action = NoOp
            | SetPassword String
            | SetShowclear Bool

update : (Action -> Effects Action) -> Action -> Model -> (Model, Effects Action)
update focusEffect action model =
  case action of
    NoOp -> (model, Effects.none)
    SetPassword pw -> ( { model | password = pw }, Effects.none)
    SetShowclear b -> ( { model | showclear = b }, focusEffect NoOp)
                      

type alias Props =
  { name : String
  , label : String
  }

view : Signal.Address Action -> Props -> Model -> Html
view address props model =
  let
    showId = props.name ++ "-show"
  in
    div []
          [ label [ for props.name ] [ text props.label ]
          , input [ type' (if model.showclear then "text" else "password")
                  , value model.password
                  , name props.name
                  , on "input" targetValue (Signal.message address << SetPassword)
                  ]
            []
          , label [ class "show", for showId ] [ text "show" ]
          , input [ type' "checkbox"
                  , id showId
                  , checked model.showclear
                  , on "change" targetChecked (Signal.message address << SetShowclear)
                  , tabindex -1   -- not reached via Tab key
                  ]
          []
        ]  

