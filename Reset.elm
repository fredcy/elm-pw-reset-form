module Reset where

import Effects exposing (Effects, Never)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on, targetValue, targetChecked)
import Result exposing (andThen)
import Signal exposing (Mailbox, constant)
import StartApp exposing (App, start)
import String
import Task

import PasswordField

app : StartApp.App Model
app = StartApp.start { init = init, view = view, update = update, inputs = [pwStrengthActions] }

main : Signal Html
main =
  app.html
     
port tasks : Signal (Task.Task Never ())
port tasks =
  app.tasks


-- Send out password values for evaluation.
pwChangesMailbox : Mailbox String
pwChangesMailbox = Signal.mailbox ""

port pwChanges : Signal String
port pwChanges = pwChangesMailbox.signal |> Signal.dropRepeats

-- Get back evaluations of password strength.
port pwStrength : Signal Int

pwStrengthActions : Signal Action
pwStrengthActions =
  Signal.map (\i -> UpdateStrength i) pwStrength

-- Send direction to focus on element. In order to use as an Effect we need to
-- wrap the focus port with a Mailbox.
focusMailbox : Signal.Mailbox String
focusMailbox = Signal.mailbox ""

port focus : Signal String
port focus = focusMailbox.signal
             
-- Get static information about form, scraped from the legacy form.
type alias FormInfo = { action : String
                      , formkey : String
                      , formname : String
                      }
port formInfo : FormInfo


type alias Model =
  { password : PasswordField.Model
  , password2 : PasswordField.Model
  , confirmed : Bool
  , strength: Int
  }

defaultModel : Model
defaultModel =
  let
    password = PasswordField.init
    password2 = PasswordField.init
  in
    Model password password2 False 0

init : (Model, Effects Action)
init = (defaultModel, sendFocus "#elmResetForm input[name=password]" NoOp)


type Action =
  NoOp
  | UpdatePassword PasswordField.Action
  | UpdatePassword2 PasswordField.Action
  | UpdateConfirmed Bool
  | UpdateStrength Int

-- Create a task that sends the password value over the port for evaluation.
sendPwChange : String -> Effects Action
sendPwChange pw =
  Signal.send pwChangesMailbox.address pw |> Task.map (always NoOp) |> Effects.task

-- Create a task that sends a javascript element-selector to the port for
-- requesting focus. Since we pass this to the sub-model we make the action a
-- parameter also.
sendFocus: String -> a -> Effects a
sendFocus selector action =
  Signal.send focusMailbox.address selector |> Task.map (always action) |> Effects.task


update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    NoOp ->
      (model, Effects.none)
    UpdatePassword pfAction ->
      let focusEffect = sendFocus "#elmResetForm input[name=password]"
          (password', fx) = PasswordField.update focusEffect pfAction model.password
          model' = { model | password = password' }
          pwEffect = sendPwChange model'.password.password
      in (model', Effects.batch [Effects.map UpdatePassword fx, pwEffect])
    UpdatePassword2 pfAction ->
      let focusEffect = sendFocus "#elmResetForm input[name=password2]"
          (password2', fx) = PasswordField.update focusEffect pfAction model.password2
          model' = { model | password2 = password2' }
      in (model', Effects.map UpdatePassword2 fx)
    UpdateConfirmed b ->
      ({ model | confirmed = b }, Effects.none)
    UpdateStrength i ->
      ({ model | strength = i }, Effects.none)


view : Signal.Address Action -> Model -> Html
view address model =
  div []
      [ inputForm address model
      --, debugDisplay model
      ]

inputForm : Signal.Address Action -> Model -> Html
inputForm address model =
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
    pwaddress = Signal.forwardTo address UpdatePassword
    pwaddress2 = Signal.forwardTo address UpdatePassword2
  in
    Html.form [ action formInfo.action, method "post", id "elmResetForm" ]
          [ ol []
                 [ li [] [ PasswordField.view pwaddress props model.password
                         , if message /= "" then
                             div [ class "message" ] [ text message ]
                           else
                             strengthDisplay model.strength
                         ]
                 , li [] [ PasswordField.view pwaddress2 props2 model.password2
                         , div [ class "message" ] [ text message2 ]
                         ]
                 , li []
                        [ label [ for "accept" ] [ text "Accept ITS Policy and Honor Code" ]
                        , input [ type' "checkbox"
                                , id "accept"
                                , name "accept"
                                , checked model.confirmed
                                , on "change" targetChecked (Signal.message address << UpdateConfirmed)
                                ] []
                        ]
                 ]
          , if ready model then submitButton model else div [] []
          , input [ type' "hidden", name "_formname", value formInfo.formname ] []
          , input [ type' "hidden", name "_formkey", value formInfo.formkey ] []
          ]
      
strengthDisplay : Int -> Html
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

debugDisplay : Model -> Html
debugDisplay model =
  div []
        [ h3 [] [ text "Model" ]
        , toString model |> text
        , h3 [] [ text "Strength" ]
        , toString model.strength |> text
        ]

submitButton : Model -> Html
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

