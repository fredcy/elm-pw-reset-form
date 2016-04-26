port module Reset exposing (..)

import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Result exposing (andThen)
import String
import Task

import PasswordField


-- Get static information about form, scraped from the legacy form.
type alias FormInfo = { action : String
                      , formkey : String
                      , formname : String
                      }


main =
  Html.programWithFlags { init = init, view = view, update = update, subscriptions = subscriptions }


-- Send out password values for evaluation.
port pwChanges : String -> Cmd msg

-- Get back evaluations of password strength.
port pwStrength : (Int -> msg) -> Sub msg


-- Send direction to focus on element.
port focus : String -> Cmd msg
             

subscriptions : Model -> Sub Action
subscriptions model =
  pwStrength UpdateStrength
             

type alias Model =
  { password : PasswordField.Model
  , password2 : PasswordField.Model
  , confirmed : Bool
  , strength : Int
  , formInfo : FormInfo
  }


init : FormInfo -> (Model, Cmd Action)
init flags =
  ( Model PasswordField.init PasswordField.init False 0 flags
  , sendFocus "#elmResetForm input[name=password]" )


type Action =
  NoOp
  | UpdatePassword PasswordField.Action
  | UpdatePassword2 PasswordField.Action
  | UpdateConfirmed Bool
  | UpdateStrength Int

-- Create a command that sends the password value over the port for evaluation.
sendPwChange : String -> Cmd Action
sendPwChange pw =
  pwChanges pw  -- ??? map to NoOp

-- Create a effect that sends a javascript element-selector to the port for
-- requesting focus. Since we pass this to the sub-model we make the action a
-- parameter also.
sendFocus: String -> Cmd a
sendFocus selector =
  focus selector


update : Action -> Model -> (Model, Cmd Action)
update action model =
  case action of
    NoOp ->
      (model, Cmd.none)
    UpdatePassword pfAction ->
      let focusEffect = sendFocus "#elmResetForm input[name=password]"
          (password', fx) = PasswordField.update focusEffect pfAction model.password
          model' = { model | password = password' }
          pwEffect = sendPwChange model'.password.password
      in (model', Cmd.batch [Cmd.map UpdatePassword fx, pwEffect])
    UpdatePassword2 pfAction ->
      let focusEffect = sendFocus "#elmResetForm input[name=password2]"
          (password2', fx) = PasswordField.update focusEffect pfAction model.password2
          model' = { model | password2 = password2' }
      in (model', Cmd.map UpdatePassword2 fx)
    UpdateConfirmed b ->
      ({ model | confirmed = b }, Cmd.none)
    UpdateStrength i ->
      ({ model | strength = i }, Cmd.none)


view : Model -> Html Action
view model =
  div []
      [ inputForm model
      --, debugDisplay model
      ]

inputForm : Model -> Html Action
inputForm  model =
  let
    message = case validPassword model.password.password of
                Err msg -> msg
                Ok _ -> ""
    message2 = if model.password2.password == "" then
                 ""
               else if model.password2.password /= model.password.password then
                 "Does not match"
               else
                 ""
    props = { name = "password", label = "New password" }
    props2 = { name = "password2", label = "New password, again" }
  in
    Html.form [ action model.formInfo.action, method "post", id "elmResetForm" ]
          [ ol []
                 [ li [] [ PasswordField.view props model.password |> Html.map UpdatePassword
                         , if message /= "" then
                             div [ class "message" ] [ text message ]
                           else
                             strengthDisplay model.strength
                         ]
                 , li [] [ PasswordField.view props2 model.password2 |> Html.map UpdatePassword2
                         , div [ class "message" ] [ text message2 ]
                         ]
                 , li []
                        [ label [ for "accept" ] [ text "Accept ITS Policy and Honor Code" ]
                        , input [ type' "checkbox"
                                , id "accept"
                                , name "accept"
                                , checked model.confirmed
                                , onCheck UpdateConfirmed
                                ] []
                        ]
                 ]
          , if ready model then submitButton model else div [] []
          , input [ type' "hidden", name "_formname", value model.formInfo.formname ] []
          , input [ type' "hidden", name "_formkey", value model.formInfo.formkey ] []
          ]
      
strengthDisplay : Int -> Html Action
strengthDisplay strength =
  let
    score = strength
    (message, class') =
      case score of
        0 -> ("weak: too guessable", "score-0")
        1 -> ("weak: very guessable", "score-1")
        2 -> ("weak: somewhat guessable", "score-2" )
        3 -> ("good: safely unguessable", "score-3")
        4 -> ("good: very unguessable", "score-4")
        _ -> ("unknown", "score-error")
  in
    div [ class ("score-bar " ++ class') ]
          [ text message ]

debugDisplay : Model -> Html Action
debugDisplay model =
  div []
        [ h3 [] [ text "Model" ]
        , toString model |> text
        , h3 [] [ text "Strength" ]
        , toString model.strength |> text
        ]

submitButton : Model -> Html Action
submitButton model =
  if ready model then
    input [ type' "submit" ] []
  else
    text ""


-- Evaluate the proposed password against the absolute local requirements.
validPassword : String -> Result String ()
validPassword str =
  if String.contains "'" str then
    Err "Password should not include the single-quote character (')"
  else if String.contains "\"" str then
         Err "Password should not include the double-quote character (\")"
       else if String.length str < 8 then
              Err "Password must be at least 8 characters long"
            else 
              Ok ()

-- Is the data ready for submitting back to the server?
ready : Model -> Bool
ready model =
  let valid = case validPassword model.password.password of
                Err _ -> False
                Ok _ -> True
  in valid && model.password.password == model.password2.password && model.confirmed

