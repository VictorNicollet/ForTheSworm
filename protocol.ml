include Protocol_types

let version = 1

module Handshake = Protocol_handshake

let endpoints : endpoint list = [
  Handshake.endpoint
]

let parseNextRequest r =
  List.assoc (r # char) endpoints r
      
