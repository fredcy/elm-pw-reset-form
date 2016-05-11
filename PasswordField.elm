module PasswordField exposing (Model, Msg, init, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)


type alias Model =
    { password : String
    , showclear : Bool
    }


init : Model
init =
    Model "" False


type Msg
    = SetPassword String
    | SetShowclear Bool



-- The update function receives `focusCmd`, a function that creates a command
-- for focusing on this particular form element.


update : Cmd Msg -> Msg -> Model -> ( Model, Cmd Msg )
update focusCmd msg model =
    case msg of
        SetPassword pw ->
            ( { model | password = pw }, Cmd.none )

        SetShowclear b ->
            ( { model | showclear = b }, focusCmd )



-- We separate the static properties from those in the model.


type alias Props =
    { name : String
    , label : String
    }


view : Props -> Model -> Html Msg
view props model =
    let
        showId =
            props.name ++ "-show"
    in
        div []
            [ label [ for props.name ] [ text props.label ]
            , input
                [ type'
                    (if model.showclear then
                        "text"
                     else
                        "password"
                    )
                , value model.password
                , name props.name
                , onInput SetPassword
                ]
                []
            , label [ class "show", for showId ] [ text "show" ]
            , input
                [ type' "checkbox"
                , id showId
                , checked model.showclear
                , onCheck SetShowclear
                , tabindex -1
                  -- not reached via Tab key
                ]
                []
            ]
