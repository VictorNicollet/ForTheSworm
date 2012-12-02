include Protocol_types

let version = 1

module Handshake = Protocol_handshake
module Save = Protocol_save

let endpoints : endpoint list = [
  Handshake.endpoint ;
  Save.endpoint
]

let parseNextRequest r =
  let c = r # char in
  Log.(out DEBUG "Command : %c" c) ;
  List.assoc c endpoints r
      
