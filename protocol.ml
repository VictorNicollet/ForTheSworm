include Protocol_types

let version = 1

module Response = Protocol_response
module ClientKernel = Protocol_clientKernel

module Handshake = Protocol_handshake
module SaveBlob = Protocol_saveBlob
module LoadBlob = Protocol_loadBlob
module AddEvent = Protocol_addEvent
module CreateStream = Protocol_createStream

let endpoints : endpoint list = [
  Handshake.endpoint ;
  SaveBlob.endpoint ;
  LoadBlob.endpoint ;
  AddEvent.endpoint ;
  CreateStream.endpoint ; 
]

let parseNextRequest stream server =
  let r = stream # read in
  let w = stream # write in 
  let i = r # int  in 
  let c = r # char in
  let endpoint = List.assoc c endpoints in
  endpoint r server begin fun callback -> 
    Mtx.use (w # lock) (lazy (
      w # int i ;
      callback w
    ))
  end
