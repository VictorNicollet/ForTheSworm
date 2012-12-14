exception ParseError of exn

type t = {
  bytes  : string ;
  offset : int ;
  keys   : int ;
  kcache : Key.t array Lazy.t ;
  hash   : Key.t Lazy.t
}

let to_bytes t = 
  t.bytes

let bytes t = 
  String.length t.bytes

let of_bytes bytes = 
  try 
    let keys   = Encode7bit.of_prefix bytes in
    let offset = Encode7bit.length keys in 
    if offset + keys * Key.bytes >= String.length bytes 
    then raise (ParseError (Failure "Blob is too short"))
    else
      let kcache = lazy begin 
	let step = Key.bytes in 
	Array.init keys 
	  (fun i -> Key.of_bytes (String.sub bytes (i * step + offset) step))
      end in 
      let hash   = lazy (Key.of_sha1 (Sha1.string bytes)) in
      { bytes ; offset ; keys ; kcache ; hash }
  with exn -> raise (ParseError exn) 

let to_channel chan t = 
  output_string chan t.bytes

let of_channel chan =
  try 
    let length = in_channel_length chan in 
    let bytes  = String.create length in 
    really_input chan bytes 0 length ;
    of_bytes bytes
  with 
  | (ParseError _ as exn) -> raise exn  
  | exn -> raise (ParseError exn)

let hash t = 
  Lazy.force t.hash 

let keys t = 
  Lazy.force t.kcache

let data t = 
  let offset = t.offset + Key.bytes * t.keys in
  let length = String.length t.bytes - offset in 
  String.sub t.bytes offset length

let make ?(keys=[| |]) bytes = 
  let bytes =
    let n = Encode7bit.to_string (Array.length keys) in
    let l = List.map Key.to_bytes (Array.to_list keys) in
    String.concat "" (n :: (l @ [bytes]))
  in 
  let kcache = Lazy.lazy_from_val keys in
  let keys   = Array.length keys in
  let offset = Encode7bit.length keys in
  let hash = lazy (Key.of_sha1 (Sha1.string bytes)) in
  { bytes ; keys ; kcache ; offset ; hash }


