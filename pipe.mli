exception EOT

type socket = Unix.file_descr

class read : socket -> object 
  method char    : char
  method int     : int
  method string  : int -> string
  method key     :  Key.t
  method count   : int
end

class write : socket -> object
  method char   : char -> unit
  method int    : int -> unit
  method string : string -> unit
  method key    : Key.t -> unit
  method count  : int
  method lock   : Mtx.t
  method closed : bool
end

class readwrite : socket -> object
  method read  : read
  method write : write
end
