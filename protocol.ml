include Protocol_types

let version = 1

module Response = Protocol_response

module Handshake = Protocol_handshake
module Save = Protocol_save

let endpoints : endpoint list = [
  Handshake.endpoint ;
  Save.endpoint
]

let parseNextRequest r =
  let c = r # char in
  List.assoc c endpoints r
      
