exception EOT

type socket = Unix.file_descr

class read socket = object (self)

  val socket = socket
  val buf    = String.create 10

  method char = 
    let n = Unix.recv socket buf 0 1 [] in
    if n = 1 then buf.[0] else raise EOT

  method int = 
    Encode7bit.of_charStream (fun r -> r # char) self
    
  method string length = 
    let out = String.create length in 
    let rec get read length = 
      if length = 0 then out else
	let n = Unix.recv socket out read length [] in
	if n = 0 then raise EOT else
	  get (read + n) (length - n)
    in
    get 0 length 

end

class write socket = object (self) 

  val socket = socket

  method char c = 
    let s = String.make 1 c in 
    let _ = Unix.send socket s 0 1 [] in
    () 

  method int i = 
    let s = Encode7bit.to_string i in
    let _ = Unix.send socket s 0 (String.length s) [] in
    () 

  method string s = 
    let _ = Unix.send socket s 0 (String.length s) [] in
    () 

end
