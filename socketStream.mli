exception EOT

type socket = Unix.file_descr

class read : socket -> object 
  method char   : char
  method int    : int
  method string : int -> string
end

class write : socket -> object
  method char   : char -> unit
  method int    : int -> unit
  method string : string -> unit
end
