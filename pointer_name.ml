open BatPervasives

exception ParseError of exn 

type seg = [ `K of Key.t | `S of string ]

type t = { 
  list  : seg list ; 
  bytes : string Lazy.t ;
  hash  : Key.t Lazy.t 
}

let fullrepl str sub by = 
  try ignore (BatString.find str sub) ;
      String.concat by (BatString.nsplit str sub) 
  with _ -> str

let human_readable t = 
  String.concat "/" ("" :: (List.map (function 
  | `S s -> fullrepl (fullrepl s "%" "%25") "/" "%2F"
  | `K k -> Key.to_hex_short k) t.list))

let bytes t = 
  String.length (Lazy.force t.bytes) 

let bytes_of_list list = 
  let zero = Encode7bit.to_string 0 in
  let length s = Encode7bit.to_string (String.length s + 1) in
  let concat = 
    String.concat ""
      (List.concat 
	 (List.map (function 
	 | `K k -> [ zero ; Key.to_bytes k ]
	 | `S s -> [ length s ; s ]) list))
  in
  concat
	 
let make list = 
  let bytes = lazy (bytes_of_list list) in
  let hash  = lazy (Key.of_sha1 (Sha1.string (Lazy.force bytes))) in
  { list ; bytes ; hash }

let read t = 
  t.list

let hash t = 
  Lazy.force t.hash 

let to_bytes t =
  Lazy.force t.bytes

let list_of_bytes bytes = 
  try 
    let c = ref 0 in
    let getchar () = incr c ; bytes.[!c-1] in
    let getstr len = 
      let s = String.sub bytes !c len in 
      c := !c + len ; s
    in
    let rec build () = 
      let l = Encode7bit.of_charStream getchar () in
      let h = 
	if l = 0 
	then `K (Key.of_bytes (getstr Key.bytes))
	else `S (getstr (l - 1))
      in
      h :: build () 
    in
    build () 
  with exn -> raise (ParseError exn)

let of_bytes bytes = 
  let list  = list_of_bytes bytes in 
  let hash  = lazy (Key.of_sha1 (Sha1.string bytes)) in
  let bytes = Lazy.lazy_from_val bytes in 
  { list ; hash ; bytes }
