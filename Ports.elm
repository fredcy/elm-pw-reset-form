port module Ports exposing (..)

-- Send out password values for evaluation.
port pwChanges : String -> Cmd msg

-- Get back evaluations of password strength.
port pwStrength : (Int -> msg) -> Sub msg


-- Send direction to focus on element.
port focus : String -> Cmd msg
             

-- Get static information about form, scraped from the legacy form.
type alias FormInfo = { action : String
                      , formkey : String
                      , formname : String
                      }
port formInfo : FormInfo
