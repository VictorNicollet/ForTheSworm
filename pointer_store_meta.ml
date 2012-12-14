type kind = [`RAW]

module Name = Pointer_name 

type t = { kind : kind ; name : Name.t }

module Kind = struct

  exception Unknown of char
            
  let to_char = function 
    | `RAW -> 'R'
      
  let of_char = function 
    | 'R' -> `RAW
    |  c  -> raise (Unknown c)

end

let of_bytes bytes = 
  try 
    let name = Name.of_bytes bytes in
    let off  = Name.bytes name in 
    let kind = Kind.of_char bytes.[off] in
    Some { kind ; name }
  with exn -> 
    (* TODO : handle this exception *)
    None
    
let of_channel chan = 
  let length = in_channel_length chan in 
  let bytes  = String.create length in 
  really_input chan bytes 0 length ;
  of_bytes bytes 

let to_bytes t = 
  Printf.sprintf "%s%c" 
    (Name.to_bytes t.name)
    (Kind.to_char t.kind) 

