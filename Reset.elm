port module Reset exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Result exposing (andThen)
import String
import Task
import PasswordField


-- Get static information about form, scraped from the legacy form.


type alias FormInfo =
    { action : String
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


subscriptions : Model -> Sub Msg
subscriptions model =
    pwStrength UpdateStrength


type alias Model =
    { password : PasswordField.Model
    , password2 : PasswordField.Model
    , confirmed : Bool
    , strength : Int
    , formInfo : FormInfo
    }


init : FormInfo -> ( Model, Cmd Msg )
init flags =
    ( Model PasswordField.init PasswordField.init False 0 flags
    , sendFocus "#elmResetForm input[name=password]"
    )


type Msg
    = UpdatePassword PasswordField.Msg
    | UpdatePassword2 PasswordField.Msg
    | UpdateConfirmed Bool
    | UpdateStrength Int



-- Create a command that sends the password value over the port for evaluation.


sendPwChange : String -> Cmd Msg
sendPwChange pw =
    pwChanges pw



-- Create a command that sends a javascript element-selector to the port for
-- requesting focus.


sendFocus : String -> Cmd a
sendFocus selector =
    focus selector


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdatePassword pfMsg ->
            let
                focusCmd =
                    sendFocus "#elmResetForm input[name=password]"

                ( password_, fx ) =
                    PasswordField.update focusCmd pfMsg model.password

                model_ =
                    { model | password = password_ }

                pwCmd =
                    sendPwChange model_.password.password
            in
                ( model_, Cmd.batch [ Cmd.map UpdatePassword fx, pwCmd ] )

        UpdatePassword2 pfMsg ->
            let
                focusCmd =
                    sendFocus "#elmResetForm input[name=password2]"

                ( password2_, fx ) =
                    PasswordField.update focusCmd pfMsg model.password2

                model_ =
                    { model | password2 = password2_ }
            in
                ( model_, Cmd.map UpdatePassword2 fx )

        UpdateConfirmed b ->
            ( { model | confirmed = b }, Cmd.none )

        UpdateStrength i ->
            ( { model | strength = i }, Cmd.none )


view : Model -> Html Msg
view model =
    div []
        [ inputForm model
          --, debugDisplay model
        ]


inputForm : Model -> Html Msg
inputForm model =
    let
        message =
            case validPassword model.password.password of
                Err msg ->
                    msg

                Ok _ ->
                    ""

        message2 =
            if model.password2.password == "" then
                ""
            else if model.password2.password /= model.password.password then
                "Does not match"
            else
                ""

        props =
            { name = "password", label = "New password" }

        props2 =
            { name = "password2", label = "New password, again" }
    in
        Html.form [ action model.formInfo.action, method "post", id "elmResetForm" ]
            [ ol []
                [ li []
                    [ PasswordField.view props model.password |> Html.map UpdatePassword
                    , if message /= "" then
                        div [ class "message" ] [ text message ]
                      else
                        strengthDisplay model.strength
                    ]
                , li []
                    [ PasswordField.view props2 model.password2 |> Html.map UpdatePassword2
                    , div [ class "message" ] [ text message2 ]
                    ]
                , li []
                    [ label [ for "accept" ] [ text "Accept ITS Policy and Honor Code" ]
                    , input
                        [ type_ "checkbox"
                        , id "accept"
                        , name "accept"
                        , checked model.confirmed
                        , onCheck UpdateConfirmed
                        ]
                        []
                    ]
                ]
            , if ready model then
                submitButton model
              else
                div [] []
            , input [ type_ "hidden", name "_formname", value model.formInfo.formname ] []
            , input [ type_ "hidden", name "_formkey", value model.formInfo.formkey ] []
            ]


strengthDisplay : Int -> Html Msg
strengthDisplay strength =
    let
        score =
            strength

        ( message, class_ ) =
            case score of
                0 ->
                    ( "weak: too guessable", "score-0" )

                1 ->
                    ( "weak: very guessable", "score-1" )

                2 ->
                    ( "weak: somewhat guessable", "score-2" )

                3 ->
                    ( "good: safely unguessable", "score-3" )

                4 ->
                    ( "good: very unguessable", "score-4" )

                _ ->
                    ( "unknown", "score-error" )
    in
        div [ class ("score-bar " ++ class_) ]
            [ text message ]


debugDisplay : Model -> Html Msg
debugDisplay model =
    div []
        [ h3 [] [ text "Model" ]
        , toString model |> text
        , h3 [] [ text "Strength" ]
        , toString model.strength |> text
        ]


submitButton : Model -> Html Msg
submitButton model =
    if ready model then
        input [ type_ "submit" ] []
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
    let
        valid =
            case validPassword model.password.password of
                Err _ ->
                    False

                Ok _ ->
                    True
    in
        valid && model.password.password == model.password2.password && model.confirmed
