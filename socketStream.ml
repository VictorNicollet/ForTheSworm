exception EOT

type socket = Unix.file_descr

class read socket = object (self)

  val socket = socket
  val buf    = String.create 10

  val mutable count = 0 
  method count = count

  method char = 
    let n = Unix.recv socket buf 0 1 [] in
    count <- count + n ;
    if n = 1 then buf.[0] else raise EOT

  method int = 
    Encode7bit.of_charStream (fun r -> r # char) self
    
  method string length = 
    let buf = String.create length in 
    let rec get read length = 
      if length = 0 then buf else
	let n = Unix.recv socket buf read length [] in
	if n = 0 then raise EOT else begin
	  count <- count + n ;
	  get (read + n) (length - n)
	end
    in
    get 0 length

  method key = 
    Key.of_bytes (self # string Key.bytes)

end

class write socket = object (self) 

  val socket = socket

  val mutable closed = false
  method closed = closed

  val mutable count = 0
  method count = count

  method string s =
    if not closed then 
      try 
	let n = Unix.send socket s 0 (String.length s) [] in
	count <- count + n
      with _ -> 
	closed <- true
	
  method char c =
    self # string (String.make 1 c)

  method int i =
    self # string (Encode7bit.to_string i)

  method key k = 
    self # string (Key.to_bytes k)

  val lock = Mtx.make "writer"
  method lock = lock 

end

class stream socket = object
  val read = new read socket
  method read = read
  val write = new write socket
  method write = write
end
